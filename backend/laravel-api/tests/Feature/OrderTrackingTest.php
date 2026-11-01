<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Product;
use App\Models\ReturnRequest;
use App\Models\Sale;
use App\Models\SaleItem;
use App\Models\Store;
use App\Models\User;
use App\Services\OrderTrackingService;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class OrderTrackingTest extends TestCase
{
    use DatabaseTransactions;

    protected Store $store;
    protected User $user;
    protected Customer $customer;
    protected Product $product;

    protected function setUp(): void
    {
        parent::setUp();

        $this->store = Store::firstOrCreate(
            ['code' => 'STORE-TRACK-TEST'],
            ['name' => 'OmniLuxe Telemetry Store', 'is_active' => true]
        );

        $this->user = User::firstOrCreate(
            ['email' => 'trackadmin@omniluxe.test'],
            ['name' => 'Tracking Admin', 'password' => bcrypt('password'), 'role' => 'super_admin']
        );

        $this->customer = Customer::firstOrCreate(
            ['phone' => '0779998877'],
            ['name' => 'Malki Silva', 'email' => 'malki.silva@omniluxe.test', 'store_id' => $this->store->id]
        );

        $this->product = Product::firstOrCreate(
            ['sku' => 'SKU-TRACK-001'],
            [
                'store_id' => $this->store->id,
                'name' => 'OmniLuxe Italian Oxford Shoes',
                'selling_price' => 24500.00,
                'cost_price' => 15000.00,
                'warranty_period_months' => 12,
                'is_active' => true,
            ]
        );
    }

    protected function createTestSale(array $attributes = []): Sale
    {
        $sale = Sale::create(array_merge([
            'store_id' => $this->store->id,
            'cashier_id' => $this->user->id,
            'customer_id' => $this->customer->id,
            'invoice_number' => 'INV-TRK-' . rand(10000, 99999),
            'transaction_uuid' => (string) \Illuminate\Support\Str::uuid(),
            'sale_status' => 'completed',
            'payment_status' => 'paid',
            'fulfillment_status' => 'dispatched',
            'courier_name' => 'Prompt Express Priority',
            'tracking_number' => 'PRM-TRACK-99881',
            'subtotal' => 24500.00,
            'tax_amount' => 0.00,
            'discount_amount' => 0.00,
            'total_amount' => 24500.00,
            'payment_method' => 'card',
            'source' => 'online',
            'sold_at' => now(),
        ], $attributes));

        SaleItem::create([
            'sale_id' => $sale->id,
            'product_id' => $this->product->id,
            'quantity' => 1,
            'unit_cost' => 15000.00,
            'unit_price' => 24500.00,
            'subtotal' => 24500.00,
            'total' => 24500.00,
        ]);

        return $sale->fresh(['items.product', 'store', 'customer']);
    }

    public function test_can_render_track_page_without_query(): void
    {
        $response = $this->get('/track');
        $response->assertStatus(200);
        $response->assertSee('Track Order & Returns Portal', false);
        $response->assertSee('Real-Time Omnichannel Telemetry');
    }

    public function test_can_track_order_by_invoice_number(): void
    {
        $sale = $this->createTestSale();

        $response = $this->get("/track?query={$sale->invoice_number}");
        $response->assertStatus(200);
        $response->assertSee($sale->invoice_number);
        $response->assertSee('Prompt Express Priority');
        $response->assertSee('PRM-TRACK-99881');
        $response->assertSee('OmniLuxe Italian Oxford Shoes');
        $response->assertSee('Order Progression Telemetry');
    }

    public function test_can_track_order_by_courier_tracking_number(): void
    {
        $sale = $this->createTestSale(['tracking_number' => 'COURIER-TRACK-777']);

        $response = $this->get('/track?query=COURIER-TRACK-777');
        $response->assertStatus(200);
        $response->assertSee($sale->invoice_number);
        $response->assertSee('COURIER-TRACK-777');
    }

    public function test_shows_error_when_order_not_found(): void
    {
        $response = $this->get('/track?query=NON-EXISTENT-INV');
        $response->assertStatus(200);
        $response->assertSee('Order Search Alert');
        $response->assertSee('NON-EXISTENT-INV');
    }

    public function test_can_submit_return_request_via_web(): void
    {
        $sale = $this->createTestSale();
        $saleItem = $sale->items->first();

        $payload = [
            'type' => 'exchange',
            'reason' => 'Wrong size or fit',
            'customer_notes' => 'Please exchange for size UK 9',
            'items' => [
                [
                    'selected' => '1',
                    'sale_item_id' => $saleItem->id,
                    'quantity' => 1,
                    'item_condition' => 'unopened',
                    'replacement_notes' => 'Size UK 9 Black',
                ],
            ],
        ];

        $response = $this->post("/track/{$sale->invoice_number}/return", $payload);
        $response->assertRedirect();
        $response->assertSessionHas('success');

        $this->assertDatabaseHas('return_requests', [
            'sale_id' => $sale->id,
            'type' => 'exchange',
            'reason' => 'Wrong size or fit',
            'customer_notes' => 'Please exchange for size UK 9',
        ]);

        $this->assertDatabaseHas('return_request_items', [
            'sale_item_id' => $saleItem->id,
            'quantity' => 1,
            'item_condition' => 'unopened',
            'replacement_notes' => 'Size UK 9 Black',
        ]);
    }

    public function test_api_can_track_order(): void
    {
        $sale = $this->createTestSale();

        $response = $this->getJson("/api/v1/orders/track/{$sale->invoice_number}");
        $response->assertStatus(200);
        $response->assertJson([
            'success' => true,
            'data' => [
                'invoice_number' => $sale->invoice_number,
                'courier_name' => 'Prompt Express Priority',
                'tracking_number' => 'PRM-TRACK-99881',
                'fulfillment_status' => 'dispatched',
            ],
        ]);
    }

    public function test_api_can_submit_return_request(): void
    {
        $sale = $this->createTestSale();
        $saleItem = $sale->items->first();

        $payload = [
            'invoice_number' => $sale->invoice_number,
            'type' => 'refund',
            'reason' => 'Defective or damaged product',
            'customer_notes' => 'Sole stitch loose',
            'items' => [
                [
                    'sale_item_id' => $saleItem->id,
                    'quantity' => 1,
                    'item_condition' => 'defective',
                    'replacement_notes' => 'Requesting store credit',
                ],
            ],
        ];

        $response = $this->postJson('/api/v1/orders/returns', $payload);
        $response->assertStatus(201);
        $response->assertJson([
            'success' => true,
            'data' => [
                'type' => 'return',
                'status' => 'pending',
            ],
        ]);
    }

    public function test_service_updates_fulfillment_status(): void
    {
        $sale = $this->createTestSale(['fulfillment_status' => 'processing']);
        $service = app(OrderTrackingService::class);

        $updated = $service->updateFulfillment(
            $sale,
            'delivered',
            'FINAL-DELIVERY-123',
            'Domex Express'
        );

        $this->assertEquals('delivered', $updated->fulfillment_status);
        $this->assertEquals('FINAL-DELIVERY-123', $updated->tracking_number);
        $this->assertEquals('Domex Express', $updated->courier_name);
        $this->assertNotNull($updated->delivered_at);
    }
}
