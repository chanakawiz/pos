<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Product;
use App\Models\Sale;
use App\Models\Store;
use App\Models\User;
use App\Services\BillingService;
use App\Services\LoyaltyTierService;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class LoyaltyTierTest extends TestCase
{
    use DatabaseTransactions;

    protected Store $store;
    protected User $cashier;
    protected Customer $customer;
    protected LoyaltyTierService $tierService;

    protected function setUp(): void
    {
        parent::setUp();

        $this->store = Store::firstOrCreate(
            ['code' => 'STORE-TIER-TEST'],
            ['name' => 'Colombo Flagship Hub', 'address' => '420 Galle Road, Colombo 03', 'is_active' => true]
        );

        $this->cashier = User::firstOrCreate(
            ['email' => 'cashier_tier_test@smartshop.com'],
            ['name' => 'Tier Cashier', 'password' => bcrypt('password'), 'store_id' => $this->store->id, 'role' => 'cashier']
        );

        $this->customer = Customer::create([
            'name' => 'Alexander Wright',
            'phone' => '0778899001',
            'email' => 'alexander@omniluxe.test',
            'loyalty_points' => 0,
            'vip_tier' => 'silver',
            'total_spend' => 0.00,
        ]);

        $this->tierService = app(LoyaltyTierService::class);
    }

    public function test_customer_defaults_to_silver_privilege(): void
    {
        $this->assertEquals('silver', $this->customer->vip_tier);
        $this->assertEquals('Silver Privilege', $this->customer->tier_title);
        $this->assertEquals(0.0, $this->customer->tier_discount_percent);
        $this->assertEquals(1.0, $this->customer->points_multiplier);
    }

    public function test_automatic_progression_to_gold_elite(): void
    {
        // Spend Rs. 120,000.00
        $result = $this->tierService->processSaleSpend($this->customer, 120000.00);

        $this->assertEquals(1200, $result['points_earned']); // 120,000 / 100 * 1.0
        $this->assertEquals('gold', $result['new_tier']);
        $this->assertTrue($result['tier_upgraded']);
        $this->assertEquals(120000.00, $result['total_spend']);

        $fresh = $this->customer->fresh();
        $this->assertEquals('gold', $fresh->vip_tier);
        $this->assertEquals('Gold Elite', $fresh->tier_title);
        $this->assertEquals(5.0, $fresh->tier_discount_percent);
        $this->assertEquals(1.5, $fresh->points_multiplier);
        $this->assertNotNull($fresh->tier_updated_at);
    }

    public function test_automatic_progression_to_black_diamond_with_accelerator(): void
    {
        // First spend Rs. 150,000 -> reaches Gold (1.5x points)
        $this->tierService->processSaleSpend($this->customer, 150000.00);
        $this->assertEquals('gold', $this->customer->fresh()->vip_tier);

        // Next spend Rs. 120,000 -> total spend reaches Rs. 270,000 -> unlocks Black Diamond
        // In Gold tier, multiplier is 1.5x -> points earned: 120,000 / 100 * 1.5 = 1,800 points
        $result = $this->tierService->processSaleSpend($this->customer->fresh(), 120000.00);

        $this->assertEquals(1800, $result['points_earned']);
        $this->assertEquals('black', $result['new_tier']);
        $this->assertTrue($result['tier_upgraded']);
        $this->assertEquals(270000.00, $result['total_spend']);

        $fresh = $this->customer->fresh();
        $this->assertEquals('black', $fresh->vip_tier);
        $this->assertEquals('Black Diamond', $fresh->tier_title);
        $this->assertEquals(10.0, $fresh->tier_discount_percent);
        $this->assertEquals(2.0, $fresh->points_multiplier);
    }

    public function test_api_can_fetch_loyalty_tiers_breakdown(): void
    {
        $response = $this->getJson('/api/v1/loyalty/tiers');

        $response->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('data.silver.title', 'Silver Privilege')
            ->assertJsonPath('data.gold.title', 'Gold Elite')
            ->assertJsonPath('data.black.title', 'Black Diamond')
            ->assertJsonPath('data.black.discount_percent', 10);
    }

    public function test_billing_service_automatically_advances_customer_tier_on_sale(): void
    {
        $product = Product::firstOrCreate(
            ['sku' => 'SKU-VIP-TEST-001'],
            [
                'name' => 'Signature Luxury Watch',
                'selling_price' => 150000.00,
                'cost_price' => 90000.00,
                'is_active' => true,
            ]
        );

        $billingService = app(BillingService::class);
        $sale = $billingService->processSale([
            'customer_id' => $this->customer->id,
            'source' => 'online',
            'items' => [
                [
                    'product_id' => $product->id,
                    'quantity' => 1,
                    'unit_price' => 150000.00,
                    'discount_amount' => 0.00,
                ],
            ],
            'payments' => [
                [
                    'payment_method' => 'card',
                    'amount' => 150000.00,
                ],
            ],
        ], $this->store, $this->cashier);

        $this->assertNotNull($sale);
        $fresh = $this->customer->fresh();
        $this->assertEquals('gold', $fresh->vip_tier);
        $this->assertEquals(150000.00, (float) $fresh->total_spend);
        $this->assertGreaterThan(0, $fresh->loyalty_points);
    }
}
