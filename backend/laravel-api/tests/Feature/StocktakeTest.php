<?php

namespace Tests\Feature;

use App\Models\Inventory;
use App\Models\Product;
use App\Models\Purchase;
use App\Models\PurchaseItem;
use App\Models\Store;
use App\Models\Supplier;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class StocktakeTest extends TestCase
{
    use DatabaseTransactions;

    public function test_stocktake_lifecycle_records_variances_and_adjusts_inventory_ledger(): void
    {
        $manager = User::where('email', 'manager@smartshop.com')->first()
            ?? User::where('email', 'cashier1@smartshop.com')->firstOrFail();
        $store = $manager->store ?? Store::firstOrFail();
        $product = Product::where('is_active', true)->firstOrFail();

        Inventory::updateOrCreate(
            ['store_id' => $store->id, 'product_id' => $product->id, 'variant_id' => null],
            ['quantity_on_hand' => 20.000, 'quantity_reserved' => 0.000]
        );

        // 1. Start stocktake session
        $startRes = $this->actingAs($manager)->postJson('/api/v1/stocktakes', [
            'notes' => 'Monthly flagship cycle count',
        ]);
        $startRes->assertStatus(201)
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('data.status', 'in_progress');

        $uuid = $startRes->json('data.uuid');

        // 2. Record physical barcode count (18 counted vs 20 expected -> -2 variance)
        $countRes = $this->actingAs($manager)->postJson("/api/v1/stocktakes/{$uuid}/counts", [
            'items' => [
                [
                    'product_id' => $product->id,
                    'counted_quantity' => 18,
                    'notes' => '2 units moved to display window',
                ],
            ],
        ]);
        $countRes->assertStatus(200)
            ->assertJsonPath('data.total_items_counted', 1)
            ->assertJsonPath('data.variance_items_count', 1);

        // 3. Finalize and apply adjustment
        $finalRes = $this->actingAs($manager)->postJson("/api/v1/stocktakes/{$uuid}/finalize", [
            'apply_adjustments' => true,
        ]);
        $finalRes->assertStatus(200)
            ->assertJsonPath('data.status', 'completed');

        // Verify inventory balance updated to 18 and movement logged
        $inv = Inventory::where('store_id', $store->id)->where('product_id', $product->id)->first();
        $this->assertEquals(18.0, (float) $inv->quantity_on_hand);
        $this->assertDatabaseHas('stock_movements', [
            'store_id' => $store->id,
            'product_id' => $product->id,
            'type' => 'adjustment',
            'reference_uuid' => $uuid,
        ]);
    }

    public function test_one_shot_mobile_stocktake_submission_syncs_and_finalizes(): void
    {
        $cashier = User::where('email', 'cashier1@smartshop.com')->firstOrFail();
        $store = $cashier->store ?? Store::firstOrFail();
        $product = Product::where('is_active', true)->firstOrFail();

        Inventory::updateOrCreate(
            ['store_id' => $store->id, 'product_id' => $product->id, 'variant_id' => null],
            ['quantity_on_hand' => 10.000, 'quantity_reserved' => 0.000]
        );

        $res = $this->actingAs($cashier)->postJson('/api/v1/stocktakes', [
            'notes' => 'Handheld barcode audit',
            'finalize' => true,
            'apply_adjustments' => true,
            'items' => [
                ['product_id' => $product->id, 'counted_quantity' => 13],
            ],
        ]);

        $res->assertStatus(201)
            ->assertJsonPath('data.status', 'completed')
            ->assertJsonPath('data.total_items_counted', 1);

        $inv = Inventory::where('store_id', $store->id)->where('product_id', $product->id)->first();
        $this->assertEquals(13.0, (float) $inv->quantity_on_hand);
    }

    public function test_mobile_barcode_po_receiving_supports_verified_quantity_overrides(): void
    {
        $manager = User::where('email', 'manager@smartshop.com')->first()
            ?? User::where('email', 'cashier1@smartshop.com')->firstOrFail();
        $store = $manager->store ?? Store::firstOrFail();
        $product = Product::where('is_active', true)->firstOrFail();
        $supplier = Supplier::first() ?? Supplier::create(['name' => 'OmniLuxe Global Distributors']);

        Inventory::updateOrCreate(
            ['store_id' => $store->id, 'product_id' => $product->id, 'variant_id' => null],
            ['quantity_on_hand' => 5.000, 'quantity_reserved' => 0.000]
        );

        $po = Purchase::create([
            'purchase_number' => 'PO-MOBILE-TEST-01',
            'supplier_id' => $supplier->id,
            'store_id' => $store->id,
            'user_id' => $manager->id,
            'status' => 'ordered',
            'total_amount' => 100000.00,
            'purchased_at' => now(),
        ]);

        PurchaseItem::create([
            'purchase_id' => $po->id,
            'product_id' => $product->id,
            'quantity' => 10,
            'unit_cost' => 10000.00,
            'subtotal' => 100000.00,
        ]);

        // Barcode scanner verified 8 units physically arrived out of 10 ordered
        $res = $this->actingAs($manager)->postJson("/api/v1/purchases/{$po->uuid}/receive", [
            'received_items' => [
                ['product_id' => $product->id, 'quantity' => 8],
            ],
            'notes' => 'Handheld barcode verified: 8/10 received',
        ]);

        $res->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('data.status', 'received');

        // Inventory should be 5 + 8 = 13
        $inv = Inventory::where('store_id', $store->id)->where('product_id', $product->id)->first();
        $this->assertEquals(13.0, (float) $inv->quantity_on_hand);
    }
}
