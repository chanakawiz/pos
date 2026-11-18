<?php

namespace Tests\Feature;

use App\Models\Brand;
use App\Models\Category;
use App\Models\Customer;
use App\Models\Inventory;
use App\Models\Product;
use App\Models\Sale;
use App\Models\SmsLog;
use App\Models\Store;
use App\Models\User;
use App\Services\BillingService;
use App\Services\LoyaltyTierService;
use App\Services\OrderTrackingService;
use App\Services\Sms\Drivers\MockSmsDriver;
use App\Services\SmsService;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SmsGatewayTest extends TestCase
{
    use DatabaseTransactions;

    protected Store $store;
    protected User $cashier;
    protected Customer $customer;
    protected Product $product;
    protected SmsService $smsService;

    protected function setUp(): void
    {
        parent::setUp();

        config(['sms.default' => 'mock']);
        MockSmsDriver::reset();

        $this->store = Store::firstOrCreate(
            ['code' => 'STORE-SMS-TEST'],
            [
                'name' => 'OmniLuxe Colombo Flagship',
                'phone' => '+94 11 234 5678',
                'currency_symbol' => 'Rs.',
                'currency_code' => 'LKR',
                'address' => '420 Galle Road, Colombo 03',
                'is_active' => true,
            ]
        );

        $this->cashier = User::firstOrCreate(
            ['email' => 'cashier_sms_test@omniluxe.store'],
            [
                'name' => 'Sarah Connor (SMS Test)',
                'password' => bcrypt('password'),
                'store_id' => $this->store->id,
                'role' => 'cashier',
            ]
        );

        $this->customer = Customer::firstOrCreate(
            ['phone' => '0771234567'],
            [
                'name' => 'Devon Lane',
                'email' => 'devon_sms@omniluxe.test',
                'loyalty_points' => 150,
                'vip_tier' => 'silver',
                'total_spend' => 15000.00,
            ]
        );

        $category = Category::firstOrCreate(['slug' => 'sms-test-cat'], ['name' => 'Test Tech']);
        $brand = Brand::firstOrCreate(['slug' => 'sms-test-brand'], ['name' => 'OmniTech']);

        $this->product = Product::firstOrCreate(
            ['sku' => 'SKU-SMS-001'],
            [
                'name' => 'OmniLuxe Wireless Earbuds',
                'barcode' => '7891234567890',
                'retail_price' => 12500.00,
                'cost_price' => 7500.00,
                'category_id' => $category->id,
                'brand_id' => $brand->id,
                'is_active' => true,
            ]
        );

        Inventory::firstOrCreate(
            ['store_id' => $this->store->id, 'product_id' => $this->product->id],
            ['quantity_on_hand' => 50, 'quantity_reserved' => 0]
        );

        $this->smsService = app(SmsService::class);
    }

    public function test_phone_normalization_and_privacy_masking(): void
    {
        // Sri Lanka local formats
        $this->assertEquals('+94771234567', $this->smsService->normalizePhone('0771234567'));
        $this->assertEquals('+94771234567', $this->smsService->normalizePhone('771234567'));
        $this->assertEquals('+94771234567', $this->smsService->normalizePhone('94771234567'));
        $this->assertEquals('+94771234567', $this->smsService->normalizePhone('077-123-4567'));
        $this->assertEquals('+94771234567', $this->smsService->normalizePhone(' 077 123 4567 '));

        // Foreign E.164 formats
        $this->assertEquals('+12025550123', $this->smsService->normalizePhone('+1 (202) 555-0123'));

        // Privacy Masking
        $this->assertEquals('+9477 •••• 567', $this->smsService->maskPhone('+94771234567'));
        $this->assertEquals('077 •••• 567', $this->smsService->maskPhone('0771234567'));
    }

    public function test_mock_driver_dispatches_and_logs_to_database(): void
    {
        $log = $this->smsService->dispatch(
            '0771234567',
            'Hello from OmniLuxe Store!',
            'test'
        );

        $this->assertInstanceOf(SmsLog::class, $log);
        $this->assertEquals('sent', $log->status);
        $this->assertEquals('+94771234567', $log->recipient_phone);
        $this->assertEquals('+9477 •••• 567', $log->masked_phone);
        $this->assertStringStartsWith('MOCK-', $log->gateway_reference);
        $this->assertNotNull($log->sent_at);

        $this->assertDatabaseHas('sms_logs', [
            'id' => $log->id,
            'status' => 'sent',
            'recipient_phone' => '+94771234567',
        ]);

        $this->assertEquals(1, MockSmsDriver::count());
    }

    public function test_handles_gateway_failure_visibly(): void
    {
        MockSmsDriver::setShouldFail(true, 'Insufficient telecom gateway balance');

        $log = $this->smsService->dispatch('0771234567', 'Test failure message');

        $this->assertEquals('failed', $log->status);
        $this->assertEquals('Insufficient telecom gateway balance', $log->error_message);
        $this->assertNull($log->sent_at);

        $this->assertDatabaseHas('sms_logs', [
            'id' => $log->id,
            'status' => 'failed',
            'error_message' => 'Insufficient telecom gateway balance',
        ]);
    }

    public function test_sale_completion_automatically_dispatches_sms_receipt(): void
    {
        $billingService = app(BillingService::class);

        $sale = $billingService->processSale([
            'transaction_uuid' => (string) \Illuminate\Support\Str::uuid(),
            'customer_id' => $this->customer->id,
            'items' => [
                [
                    'product_id' => $this->product->id,
                    'quantity' => 1,
                    'unit_price' => 12500.00,
                ],
            ],
            'payments' => [
                [
                    'payment_method' => 'cash',
                    'amount' => 12500.00,
                ],
            ],
        ], $this->store, $this->cashier);

        $this->assertEquals(1, MockSmsDriver::count());
        $lastSent = MockSmsDriver::last();

        $this->assertEquals('+94771234567', $lastSent['to']);
        $this->assertStringContainsString($sale->invoice_number, $lastSent['message']);
        $this->assertStringContainsString('/receipt/' . $sale->invoice_number, $lastSent['message']);

        $this->assertDatabaseHas('sms_logs', [
            'sale_id' => $sale->id,
            'event_type' => 'pos_receipt',
            'status' => 'sent',
        ]);
    }

    public function test_courier_dispatch_automatically_sends_tracking_sms(): void
    {
        $sale = Sale::create([
            'uuid' => (string) \Illuminate\Support\Str::uuid(),
            'transaction_uuid' => (string) \Illuminate\Support\Str::uuid(),
            'invoice_number' => 'INV-TEST-DISP-001',
            'store_id' => $this->store->id,
            'cashier_id' => $this->cashier->id,
            'customer_id' => $this->customer->id,
            'delivery_phone' => '0771234567',
            'subtotal' => 12500.00,
            'total_amount' => 12500.00,
            'payment_status' => 'paid',
            'fulfillment_status' => 'unfulfilled',
            'sold_at' => now(),
            'channel' => 'online',
        ]);

        $trackingService = app(OrderTrackingService::class);
        $trackingService->updateFulfillment(
            $sale,
            'dispatched',
            'Prompt Express',
            'PR-998811',
            now()->addDays(2)
        );

        $this->assertEquals(1, MockSmsDriver::count());
        $lastSent = MockSmsDriver::last();

        $this->assertEquals('+94771234567', $lastSent['to']);
        $this->assertStringContainsString('Prompt Express', $lastSent['message']);
        $this->assertStringContainsString('PR-998811', $lastSent['message']);
        $this->assertStringContainsString('/track/INV-TEST-DISP-001', $lastSent['message']);

        $this->assertDatabaseHas('sms_logs', [
            'sale_id' => $sale->id,
            'event_type' => 'order_dispatched',
            'status' => 'sent',
        ]);
    }

    public function test_vip_tier_upgrade_triggers_congratulatory_sms(): void
    {
        $loyaltyService = app(LoyaltyTierService::class);

        // Advance customer spend past Gold Elite threshold (Rs. 100,000)
        $result = $loyaltyService->processSaleSpend($this->customer, 95000.00);

        $this->assertTrue($result['tier_upgraded']);
        $this->assertEquals('gold', $result['new_tier']);

        $this->assertEquals(1, MockSmsDriver::count());
        $lastSent = MockSmsDriver::last();

        $this->assertEquals('+94771234567', $lastSent['to']);
        $this->assertStringContainsString('Gold Elite', $lastSent['message']);
        $this->assertStringContainsString('5%', $lastSent['message']);

        $this->assertDatabaseHas('sms_logs', [
            'customer_id' => $this->customer->id,
            'event_type' => 'vip_upgrade',
            'status' => 'sent',
        ]);
    }

    public function test_resend_sms_api_endpoint(): void
    {
        Sanctum::actingAs($this->cashier);

        $sale = Sale::create([
            'uuid' => (string) \Illuminate\Support\Str::uuid(),
            'transaction_uuid' => (string) \Illuminate\Support\Str::uuid(),
            'invoice_number' => 'INV-TEST-RESEND-001',
            'store_id' => $this->store->id,
            'cashier_id' => $this->cashier->id,
            'customer_id' => $this->customer->id,
            'subtotal' => 12500.00,
            'total_amount' => 12500.00,
            'payment_status' => 'paid',
            'sold_at' => now(),
            'channel' => 'in_store',
        ]);

        $response = $this->postJson("/api/v1/sales/{$sale->uuid}/resend-sms", [
            'phone' => '0715556677',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonStructure([
                'status',
                'message',
                'data' => ['log_uuid', 'status', 'recipient_phone', 'gateway_reference'],
            ]);

        $this->assertEquals(1, MockSmsDriver::count());
        $lastSent = MockSmsDriver::last();
        $this->assertEquals('+94715556677', $lastSent['to']);
    }

    public function test_sms_logs_api_endpoint(): void
    {
        Sanctum::actingAs($this->cashier);

        $this->smsService->dispatch('0771234567', 'Audit log entry 1', 'pos_receipt', ['store_id' => $this->store->id]);
        $this->smsService->dispatch('0779998888', 'Audit log entry 2', 'web_order', ['store_id' => $this->store->id]);

        $response = $this->getJson('/api/v1/sms/logs');

        $response->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonStructure([
                'status',
                'data',
                'meta' => ['current_page', 'total', 'per_page'],
            ]);

        $this->assertGreaterThanOrEqual(2, $response->json('meta.total'));
    }

    public function test_sms_test_send_api_endpoint(): void
    {
        Sanctum::actingAs($this->cashier);

        $response = $this->postJson('/api/v1/sms/test-send', [
            'phone' => '0770001122',
            'message' => 'Custom test dispatch payload',
            'driver' => 'mock',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('data.status', 'sent');

        $this->assertEquals(1, MockSmsDriver::count());
    }
}
