<?php

namespace App\Services;

use App\Models\Inventory;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\StockMovement;
use App\Models\Store;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class InventoryService
{
    /**
     * Deduct stock for a sale or return transfer.
     */
    public function deductStock(
        Store $store,
        Product $product,
        ?ProductVariant $variant,
        float $quantity,
        string $referenceUuid,
        ?User $user = null,
        string $notes = 'Sale deduction'
    ): StockMovement {
        return DB::transaction(function () use ($store, $product, $variant, $quantity, $referenceUuid, $user, $notes) {
            $inventory = Inventory::firstOrCreate(
                [
                    'store_id' => $store->id,
                    'product_id' => $product->id,
                    'variant_id' => $variant?->id,
                ],
                [
                    'quantity_on_hand' => 0.00,
                    'quantity_reserved' => 0.00,
                ]
            );

            $before = (float) $inventory->quantity_on_hand;
            $after = round($before - $quantity, 3);

            $inventory->update(['quantity_on_hand' => $after]);

            return StockMovement::create([
                'store_id' => $store->id,
                'product_id' => $product->id,
                'variant_id' => $variant?->id,
                'user_id' => $user?->id,
                'type' => 'sale',
                'quantity' => -$quantity,
                'before_quantity' => $before,
                'after_quantity' => $after,
                'reference_uuid' => $referenceUuid,
                'notes' => $notes,
            ]);
        });
    }

    /**
     * Add stock (refund, purchase receiving, transfer in, adjustment).
     */
    public function addStock(
        Store $store,
        Product $product,
        ?ProductVariant $variant,
        float $quantity,
        string $type,
        string $referenceUuid,
        ?User $user = null,
        string $notes = ''
    ): StockMovement {
        return DB::transaction(function () use ($store, $product, $variant, $quantity, $type, $referenceUuid, $user, $notes) {
            $inventory = Inventory::firstOrCreate(
                [
                    'store_id' => $store->id,
                    'product_id' => $product->id,
                    'variant_id' => $variant?->id,
                ],
                [
                    'quantity_on_hand' => 0.00,
                    'quantity_reserved' => 0.00,
                ]
            );

            $before = (float) $inventory->quantity_on_hand;
            $after = round($before + $quantity, 3);

            $inventory->update(['quantity_on_hand' => $after]);

            return StockMovement::create([
                'store_id' => $store->id,
                'product_id' => $product->id,
                'variant_id' => $variant?->id,
                'user_id' => $user?->id,
                'type' => $type,
                'quantity' => $quantity,
                'before_quantity' => $before,
                'after_quantity' => $after,
                'reference_uuid' => $referenceUuid,
                'notes' => $notes,
            ]);
        });
    }
}
