<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Product;
use App\Models\Promotion;
use App\Models\Store;
use App\Models\User;
use App\Services\BillingService;
use App\Services\PromotionService;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class PromotionTest extends TestCase
{
    use DatabaseTransactions;

    public function test_percentage_promotion_with_discount_cap_calculates_accurately(): void
    {
        Promotion::create([
            'code' => 'LUXE15CAP',
            'name' => 'Holiday 15% Off (Max 10,000)',
            'type' => 'percentage',
            'value' => 15.00,
            'min_order_amount' => 20000.00,
            'max_discount_amount' => 10000.00,
            'allowed_channels' => ['web', 'pos'],
            'is_active' => true,
        ]);

        $service = app(PromotionService::class);

        // 50,000 * 15% = 7,500 (under cap)
        $res1 = $service->validateAndCalculate('luxe15cap', 50000.00, ['channel' => 'web']);
        $this->assertTrue($res1['valid']);
        $this->assertEquals(7500.00, $res1['discount_amount']);
        $this->assertEquals(42500.00, $res1['final_total']);

        // 100,000 * 15% = 15,000 -> capped at 10,000
        $res2 = $service->validateAndCalculate('LUXE15CAP', 100000.00, ['channel' => 'pos']);
        $this->assertTrue($res2['valid']);
        $this->assertEquals(10000.00, $res2['discount_amount']);

        // Below minimum spend rejected
        $res3 = $service->validateAndCalculate('LUXE15CAP', 10000.00, ['channel' => 'web']);
        $this->assertFalse($res3['valid']);
        $this->assertStringContainsString('Minimum order', $res3['message']);

        // Disallowed channel rejected
        $res4 = $service->validateAndCalculate('LUXE15CAP', 50000.00, ['channel' => 'mobile']);
        $this->assertFalse($res4['valid']);
        $this->assertStringContainsString('not valid on the mobile channel', $res4['message']);
    }

    public function test_buy_x_get_y_promotion_discounts_cheapest_qualifying_units(): void
    {
        Promotion::create([
            'code' => 'B2G1FREE',
            'name' => 'Buy 2 Get 1 Free Apparel',
            'type' => 'buy_x_get_y',
            'buy_quantity' => 2,
            'get_quantity' => 1,
            'is_active' => true,
        ]);

        $service = app(PromotionService::class);

        $items = [
            ['quantity' => 2, 'unit_price' => 15000.00],
            ['quantity' => 1, 'unit_price' => 8000.00],
        ];
        // Subtotal = 38,000; 3 units -> 1 free unit (cheapest = 8,000)
        $res = $service->validateAndCalculate('B2G1FREE', 38000.00, ['items' => $items]);
        $this->assertTrue($res['valid']);
        $this->assertEquals(8000.00, $res['discount_amount']);
        $this->assertEquals(30000.00, $res['final_total']);
    }

    public function test_vip_tier_gating_and_expiry_checks_are_enforced(): void
    {
        Promotion::create([
            'code' => 'BLACK20',
            'name' => 'Black Diamond Exclusive 20%',
            'type' => 'percentage',
            'value' => 20.00,
            'vip_tier_required' => 'black',
            'is_active' => true,
        ]);

        Promotion::create([
            'code' => 'EXPIRED50',
            'name' => 'Past Flash Sale',
            'type' => 'fixed_amount',
            'value' => 5000.00,
            'ends_at' => now()->subDay(),
            'is_active' => true,
        ]);

        $service = app(PromotionService::class);

        $silverAttempt = $service->validateAndCalculate('BLACK20', 50000.00, ['vip_tier' => 'silver']);
        $this->assertFalse($silverAttempt['valid']);

        $blackAttempt = $service->validateAndCalculate('BLACK20', 50000.00, ['vip_tier' => 'black']);
        $this->assertTrue($blackAttempt['valid']);
        $this->assertEquals(10000.00, $blackAttempt['discount_amount']);

        $expired = $service->validateAndCalculate('EXPIRED50', 50000.00);
        $this->assertFalse($expired['valid']);
        $this->assertStringContainsString('expired', $expired['message']);
    }

    public function test_atomic_redemption_on_sale_increments_usage_and_enforces_limit(): void
    {
        $promo = Promotion::create([
            'code' => 'ONCE2500',
            'name' => 'Single-Use VIP Voucher',
            'type' => 'fixed_amount',
            'value' => 2500.00,
            'max_uses' => 1,
            'is_active' => true,
        ]);

        $store = Store::firstOrFail();
        $cashier = User::where('email', 'cashier1@smartshop.com')->firstOrFail();
        $product = Product::where('is_active', true)->firstOrFail();

        $billing = app(BillingService::class);
        $sale = $billing->processSale([
            'items' => [
                ['product_id' => $product->id, 'quantity' => 1, 'unit_price' => 25000.00],
            ],
            'payments' => [
                ['payment_method' => 'cash', 'amount' => 22500.00],
            ],
            'discount_amount' => 2500.00,
            'promotion_code' => 'ONCE2500',
            'channel' => 'pos',
        ], $store, $cashier);

        $this->assertNotNull($sale->id);
        $this->assertEquals(1, $promo->fresh()->uses_count);
        $this->assertDatabaseHas('promotion_redemptions', [
            'promotion_id' => $promo->id,
            'sale_id' => $sale->id,
            'code_used' => 'ONCE2500',
            'channel' => 'pos',
        ]);

        // Second attempt must be rejected because max_uses = 1
        $second = app(PromotionService::class)->validateAndCalculate('ONCE2500', 25000.00);
        $this->assertFalse($second['valid']);
        $this->assertStringContainsString('maximum redemptions', $second['message']);
    }

    public function test_public_and_admin_promotion_api_endpoints(): void
    {
        $admin = User::where('email', 'admin@omniluxe.store')->first()
            ?? User::where('email', 'admin@smartshop.com')->firstOrFail();

        // 1. Admin creates promo via API
        $createRes = $this->actingAs($admin)->postJson('/api/v1/promotions', [
            'code' => 'OMNI10',
            'name' => 'OmniLuxe Launch 10%',
            'type' => 'percentage',
            'value' => 10.00,
            'min_order_amount' => 5000.00,
            'allowed_channels' => ['web', 'pos'],
            'is_active' => true,
        ]);
        $createRes->assertStatus(201)
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('promotion.code', 'OMNI10');

        $uuid = $createRes->json('promotion.uuid');

        // 2. Public active endpoint returns live campaign
        $activeRes = $this->getJson('/api/v1/promotions/active?channel=pos');
        $activeRes->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonFragment(['code' => 'OMNI10']);

        // 3. Public validate endpoint calculates discount
        $valRes = $this->postJson('/api/v1/promotions/validate', [
            'code' => 'OMNI10',
            'subtotal' => 40000.00,
            'channel' => 'web',
        ]);
        $valRes->assertStatus(200)
            ->assertJsonPath('data.discount_amount', 4000)
            ->assertJsonPath('data.final_total', 36000);

        // 4. Admin toggles campaign off -> validation now fails
        $this->actingAs($admin)->patchJson("/api/v1/promotions/{$uuid}/toggle")
            ->assertStatus(200)
            ->assertJsonPath('promotion.is_active', false);

        $this->postJson('/api/v1/promotions/validate', [
            'code' => 'OMNI10',
            'subtotal' => 40000.00,
            'channel' => 'web',
        ])->assertStatus(422);
    }
}
