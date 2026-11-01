<?php

namespace App\Services;

use App\Events\CatalogAvailabilityChanged;
use App\Events\StoreInventoryUpdated;
use App\Models\Inventory;
use App\Models\Store;

/**
 * Fans a stock change out to two strictly separated audiences:
 *   - staff:    exact quantities  → private-store.{uuid}.operations
 *   - shoppers: availability band → catalog (public)
 */
class InventoryBroadcaster
{
    /**
     * @param  array<int, int>  $productIds
     */
    public function changed(Store $store, array $productIds, string $source): void
    {
        $productIds = array_values(array_unique(array_filter($productIds)));
        if ($productIds === []) {
            return;
        }

        $rows = Inventory::query()
            ->with('product:id,uuid,name,min_stock_level')
            ->where('store_id', $store->id)
            ->whereIn('product_id', $productIds)
            ->whereNull('variant_id')
            ->get();

        $internal = [];
        $public = [];

        foreach ($rows as $row) {
            if (! $row->product) {
                continue;
            }

            $qty = (float) $row->quantity_on_hand;
            $threshold = (float) ($row->reorder_point ?: ($row->product->min_stock_level ?? 5));
            $internal[] = [
                'product_uuid' => $row->product->uuid,
                'quantity_on_hand' => $qty,
                'min_stock_level' => $threshold,
                'is_low_stock' => $qty <= $threshold,
            ];
            $public[] = ['product_uuid' => $row->product->uuid, 'availability' => self::availabilityBand($qty, $threshold)];
        }

        if ($internal === []) {
            return;
        }

        StoreInventoryUpdated::dispatch($store, $internal, $source);
        CatalogAvailabilityChanged::dispatch($public);
    }

    public static function availabilityBand(float $quantity, float $reorderPoint): string
    {
        if ($quantity <= 0) {
            return 'out_of_stock';
        }

        return $quantity <= max($reorderPoint, 0) ? 'low_stock' : 'in_stock';
    }
}
