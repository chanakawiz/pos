<?php

namespace App\Filament\Resources\ProductResource\Pages;

use App\Filament\Resources\ProductResource;
use App\Models\Inventory;
use App\Models\StockMovement;
use Filament\Resources\Pages\CreateRecord;

class CreateProduct extends CreateRecord
{
    protected static string $resource = ProductResource::class;

    protected function afterCreate(): void
    {
        $product = $this->record;
        $initialStock = (float) ($this->data['initial_stock'] ?? 10);
        $storeId = 1;

        Inventory::firstOrCreate(
            [
                'store_id'   => $storeId,
                'product_id' => $product->id,
                'variant_id' => null,
            ],
            [
                'quantity_on_hand'  => $initialStock,
                'quantity_reserved' => 0,
            ]
        );

        if ($initialStock > 0) {
            StockMovement::create([
                'store_id'        => $storeId,
                'product_id'      => $product->id,
                'user_id'         => auth()->id(),
                'type'            => 'purchase',
                'quantity'        => $initialStock,
                'before_quantity' => 0,
                'after_quantity'  => $initialStock,
                'reference_uuid'  => $product->uuid,
                'notes'           => 'Initial inventory stock upon catalog creation',
            ]);
        }
    }
}
