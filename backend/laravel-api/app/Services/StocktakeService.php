<?php

namespace App\Services;

use App\Models\Inventory;
use App\Models\Product;
use App\Models\Stocktake;
use App\Models\StocktakeItem;
use App\Models\Store;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use InvalidArgumentException;

class StocktakeService
{
    public function __construct(
        protected InventoryService $inventoryService,
        protected InventoryBroadcaster $inventoryBroadcaster
    ) {}

    /**
     * Start a new cycle count / stocktake session for a store.
     */
    public function startStocktake(Store $store, User $user, ?string $notes = null): Stocktake
    {
        $number = 'STK-' . $store->code . '-' . now()->format('Ymd') . '-' . strtoupper(Str::random(4));

        return Stocktake::create([
            'stocktake_number' => $number,
            'store_id' => $store->id,
            'user_id' => $user->id,
            'status' => 'in_progress',
            'notes' => $notes,
            'started_at' => Carbon::now(),
        ]);
    }

    /**
     * Record or update scanned physical counts on an active stocktake.
     */
    public function recordCounts(Stocktake $stocktake, array $items): Stocktake
    {
        if ($stocktake->status !== 'in_progress') {
            throw new InvalidArgumentException("Stocktake {$stocktake->stocktake_number} is already {$stocktake->status}.");
        }

        return DB::transaction(function () use ($stocktake, $items) {
            foreach ($items as $entry) {
                $product = $this->resolveProduct($entry);
                if (! $product) {
                    continue;
                }

                $variantId = $entry['variant_id'] ?? null;
                $inventory = Inventory::where('store_id', $stocktake->store_id)
                    ->where('product_id', $product->id)
                    ->where('variant_id', $variantId)
                    ->first();

                $expected = (float) ($inventory?->quantity_on_hand ?? 0.000);
                $counted = round((float) ($entry['counted_quantity'] ?? 0.000), 3);
                $varianceQty = round($counted - $expected, 3);
                $unitCost = (float) $product->cost_price;
                $varianceValue = round($varianceQty * $unitCost, 2);

                StocktakeItem::updateOrCreate(
                    [
                        'stocktake_id' => $stocktake->id,
                        'product_id' => $product->id,
                        'variant_id' => $variantId,
                    ],
                    [
                        'expected_quantity' => $expected,
                        'counted_quantity' => $counted,
                        'variance_quantity' => $varianceQty,
                        'unit_cost' => $unitCost,
                        'variance_value' => $varianceValue,
                        'notes' => $entry['notes'] ?? null,
                    ]
                );
            }

            $this->recalculateTotals($stocktake);

            return $stocktake->fresh(['items.product', 'store', 'user']);
        });
    }

    /**
     * Finalize stocktake and optionally commit non-zero variances to branch inventory ledger.
     */
    public function finalizeStocktake(Stocktake $stocktake, User $user, bool $applyAdjustments = true): Stocktake
    {
        if ($stocktake->status !== 'in_progress') {
            throw new InvalidArgumentException("Stocktake {$stocktake->stocktake_number} cannot be finalized (status: {$stocktake->status}).");
        }

        return DB::transaction(function () use ($stocktake, $user, $applyAdjustments) {
            $stocktake->load(['items.product', 'items.variant', 'store']);
            $adjustedProductIds = [];

            if ($applyAdjustments) {
                foreach ($stocktake->items as $item) {
                    $delta = round((float) $item->variance_quantity, 3);
                    if (abs($delta) < 0.001) {
                        continue;
                    }

                    $this->inventoryService->addStock(
                        store: $stocktake->store,
                        product: $item->product,
                        variant: $item->variant,
                        quantity: $delta,
                        type: 'adjustment',
                        referenceUuid: $stocktake->uuid,
                        user: $user,
                        notes: "Stocktake {$stocktake->stocktake_number} adjustment (Expected {$item->expected_quantity}, Counted {$item->counted_quantity})"
                    );
                    $adjustedProductIds[] = $item->product_id;
                }
            }

            $this->recalculateTotals($stocktake);
            $stocktake->update([
                'status' => 'completed',
                'completed_at' => Carbon::now(),
            ]);

            if (! empty($adjustedProductIds)) {
                $this->inventoryBroadcaster->changed($stocktake->store, array_unique($adjustedProductIds), 'stocktake');
            }

            return $stocktake->fresh(['items.product', 'store', 'user']);
        });
    }

    protected function recalculateTotals(Stocktake $stocktake): void
    {
        $items = $stocktake->items()->get();
        $totalCounted = $items->count();
        $varianceCount = $items->filter(fn ($i) => abs((float) $i->variance_quantity) >= 0.001)->count();
        $netQty = round((float) $items->sum('variance_quantity'), 3);
        $netVal = round((float) $items->sum('variance_value'), 2);

        $stocktake->update([
            'total_items_counted' => $totalCounted,
            'variance_items_count' => $varianceCount,
            'net_quantity_variance' => $netQty,
            'net_value_variance' => $netVal,
        ]);
    }

    protected function resolveProduct(array $entry): ?Product
    {
        if (! empty($entry['product_id'])) {
            return Product::find($entry['product_id']);
        }
        if (! empty($entry['product_uuid'])) {
            return Product::where('uuid', $entry['product_uuid'])->first();
        }
        if (! empty($entry['barcode'])) {
            return Product::where('barcode', $entry['barcode'])->orWhere('sku', $entry['barcode'])->first();
        }
        if (! empty($entry['sku'])) {
            return Product::where('sku', $entry['sku'])->first();
        }

        return null;
    }
}
