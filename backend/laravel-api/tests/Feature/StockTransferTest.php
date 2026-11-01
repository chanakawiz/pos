<?php

namespace Tests\Feature;

use App\Models\Inventory;
use App\Models\Product;
use App\Models\StockTransfer;
use App\Models\Store;
use App\Models\User;
use App\Services\StockTransferService;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class StockTransferTest extends TestCase
{
    use DatabaseTransactions;

    protected Store $sourceStore;
    protected Store $destStore;
    protected User $adminUser;
    protected Product $product;

    protected function setUp(): void
    {
        parent::setUp();

        $this->sourceStore = Store::firstOrCreate(
            ['code' => 'STORE-COLOMBO-CENTRAL'],
            ['name' => 'Colombo Flagship Hub', 'is_active' => true]
        );

        $this->destStore = Store::firstOrCreate(
            ['code' => 'STORE-KANDY-BRANCH'],
            ['name' => 'Kandy Luxury Outlet', 'is_active' => true]
        );

        $this->adminUser = User::firstOrCreate(
            ['email' => 'transferadmin@omniluxe.test'],
            ['name' => 'Warehouse Dispatcher', 'password' => bcrypt('password'), 'role' => 'super_admin']
        );

        $this->product = Product::firstOrCreate(
            ['sku' => 'SKU-TRF-TEST-001'],
            [
                'store_id' => $this->sourceStore->id,
                'name' => 'OmniLuxe Heritage Silk Scarf',
                'selling_price' => 18500.00,
                'cost_price' => 9500.00,
                'is_active' => true,
            ]
        );
    }

    public function test_can_create_stock_transfer(): void
    {
        $service = app(StockTransferService::class);

        $transfer = $service->createTransfer(
            $this->sourceStore,
            $this->destStore,
            [
                ['product_id' => $this->product->id, 'quantity' => 15],
            ],
            $this->adminUser,
            'Urgent replenishment for weekend showcase'
        );

        $this->assertDatabaseHas('stock_transfers', [
            'id' => $transfer->id,
            'source_store_id' => $this->sourceStore->id,
            'destination_store_id' => $this->destStore->id,
            'status' => 'pending_approval',
        ]);

        $this->assertDatabaseHas('stock_transfer_items', [
            'stock_transfer_id' => $transfer->id,
            'product_id' => $this->product->id,
            'quantity_requested' => 15.000,
        ]);
    }

    public function test_can_dispatch_transfer_and_deduct_source_inventory(): void
    {
        // Seed initial source store stock = 50.000
        Inventory::updateOrCreate(
            ['store_id' => $this->sourceStore->id, 'product_id' => $this->product->id, 'variant_id' => null],
            ['quantity_on_hand' => 50.000, 'quantity_reserved' => 0.000]
        );

        $service = app(StockTransferService::class);
        $transfer = $service->createTransfer(
            $this->sourceStore,
            $this->destStore,
            [['product_id' => $this->product->id, 'quantity' => 12]],
            $this->adminUser
        );

        $dispatched = $service->dispatchTransfer($transfer, $this->adminUser);

        $this->assertEquals('in_transit', $dispatched->status);
        $this->assertNotNull($dispatched->dispatched_at);

        // Verify source stock is reduced to 38.000
        $sourceInv = Inventory::where('store_id', $this->sourceStore->id)
            ->where('product_id', $this->product->id)
            ->first();

        $this->assertEquals(38.000, (float) $sourceInv->quantity_on_hand);
    }

    public function test_can_receive_transfer_and_increment_destination_inventory(): void
    {
        // Seed initial stocks
        Inventory::updateOrCreate(
            ['store_id' => $this->sourceStore->id, 'product_id' => $this->product->id, 'variant_id' => null],
            ['quantity_on_hand' => 40.000]
        );
        Inventory::updateOrCreate(
            ['store_id' => $this->destStore->id, 'product_id' => $this->product->id, 'variant_id' => null],
            ['quantity_on_hand' => 5.000]
        );

        $service = app(StockTransferService::class);
        $transfer = $service->createTransfer(
            $this->sourceStore,
            $this->destStore,
            [['product_id' => $this->product->id, 'quantity' => 10]],
            $this->adminUser
        );

        $service->dispatchTransfer($transfer, $this->adminUser);
        $received = $service->receiveTransfer($transfer, $this->adminUser);

        $this->assertEquals('received', $received->status);
        $this->assertNotNull($received->received_at);

        // Destination stock should be 5 + 10 = 15.000
        $destInv = Inventory::where('store_id', $this->destStore->id)
            ->where('product_id', $this->product->id)
            ->first();

        $this->assertEquals(15.000, (float) $destInv->quantity_on_hand);
    }

    public function test_can_cancel_in_transit_transfer_and_restore_source_stock(): void
    {
        Inventory::updateOrCreate(
            ['store_id' => $this->sourceStore->id, 'product_id' => $this->product->id, 'variant_id' => null],
            ['quantity_on_hand' => 30.000]
        );

        $service = app(StockTransferService::class);
        $transfer = $service->createTransfer(
            $this->sourceStore,
            $this->destStore,
            [['product_id' => $this->product->id, 'quantity' => 8]],
            $this->adminUser
        );

        $service->dispatchTransfer($transfer, $this->adminUser);

        // Cancel while in transit
        $cancelled = $service->cancelTransfer($transfer, $this->adminUser, 'Transit vehicle issue');

        $this->assertEquals('cancelled', $cancelled->status);

        // Stock at source store should be restored back to 30.000
        $sourceInv = Inventory::where('store_id', $this->sourceStore->id)
            ->where('product_id', $this->product->id)
            ->first();

        $this->assertEquals(30.000, (float) $sourceInv->quantity_on_hand);
    }

    public function test_api_cross_store_stock_inquiry(): void
    {
        Inventory::updateOrCreate(
            ['store_id' => $this->sourceStore->id, 'product_id' => $this->product->id, 'variant_id' => null],
            ['quantity_on_hand' => 25.000]
        );

        Sanctum::actingAs($this->adminUser);

        $response = $this->getJson("/api/v1/products/{$this->product->id}/cross-store-stock");
        $response->assertStatus(200);
        $response->assertJson([
            'status' => 'success',
            'product' => [
                'id' => $this->product->id,
                'sku' => $this->product->sku,
            ],
        ]);

        $stores = collect($response->json('stores'));
        $colombo = $stores->firstWhere('store_id', $this->sourceStore->id);
        $this->assertNotNull($colombo);
        $this->assertEquals(25.000, $colombo['quantity_on_hand']);
    }

    public function test_api_stock_transfer_lifecycle(): void
    {
        Inventory::updateOrCreate(
            ['store_id' => $this->sourceStore->id, 'product_id' => $this->product->id, 'variant_id' => null],
            ['quantity_on_hand' => 20.000]
        );

        Sanctum::actingAs($this->adminUser);

        // 1. Create transfer
        $createRes = $this->postJson('/api/v1/stock-transfers', [
            'source_store_id' => $this->sourceStore->id,
            'destination_store_id' => $this->destStore->id,
            'notes' => 'API Transfer Lifecycle Test',
            'items' => [
                ['product_id' => $this->product->id, 'quantity' => 5],
            ],
        ]);

        $createRes->assertStatus(201);
        $uuid = $createRes->json('data.uuid');
        $this->assertNotEmpty($uuid);

        // 2. Dispatch
        $dispatchRes = $this->postJson("/api/v1/stock-transfers/{$uuid}/dispatch");
        $dispatchRes->assertStatus(200);
        $this->assertEquals('in_transit', $dispatchRes->json('data.status'));

        // 3. Receive
        $receiveRes = $this->postJson("/api/v1/stock-transfers/{$uuid}/receive");
        $receiveRes->assertStatus(200);
        $this->assertEquals('received', $receiveRes->json('data.status'));
    }
}
