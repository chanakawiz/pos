<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\StaffCommission;
use App\Models\Store;
use App\Models\User;
use App\Services\BillingService;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class CommissionTest extends TestCase
{
    use DatabaseTransactions;

    public function test_sale_automatically_accrues_staff_commission_and_refund_reverses_it(): void
    {
        $cashier = User::where('email', 'cashier1@smartshop.com')->firstOrFail();
        $cashier->update([
            'commission_rate' => 3.00,
            'monthly_sales_target' => 200000.00,
        ]);

        $store = $cashier->store ?? Store::firstOrFail();
        $product = Product::where('is_active', true)->firstOrFail();

        $billing = app(BillingService::class);
        $sale = $billing->processSale([
            'items' => [
                ['product_id' => $product->id, 'quantity' => 2, 'unit_price' => 50000.00],
            ],
            'payments' => [
                ['payment_method' => 'cash', 'amount' => 100000.00],
            ],
        ], $store, $cashier);

        // 3% of sale total_amount accrued automatically
        $commission = StaffCommission::where('sale_id', $sale->id)->first();
        $this->assertNotNull($commission);
        $expectedCommission = round((float) $sale->total_amount * 0.03, 2);
        $this->assertEquals($expectedCommission, (float) $commission->commission_amount);
        $this->assertEquals('pending', $commission->status);

        // Full refund reverses commission to 0 and marks status reversed
        $firstItem = $sale->items->first();
        $billing->processRefund(
            sale: $sale,
            items: [['sale_item_id' => $firstItem->id, 'quantity' => 2]],
            reason: 'Customer exchange',
            cashier: $cashier,
            restock: true
        );

        $commission->refresh();
        $this->assertEquals('reversed', $commission->status);
        $this->assertEquals(0.00, (float) $commission->commission_amount);
    }

    public function test_leaderboard_self_summary_and_payout_api_endpoints(): void
    {
        $cashier = User::where('email', 'cashier1@smartshop.com')->firstOrFail();
        $cashier->update([
            'commission_rate' => 4.00,
            'monthly_sales_target' => 100000.00,
        ]);

        $store = $cashier->store ?? Store::firstOrFail();
        $product = Product::where('is_active', true)->firstOrFail();

        $sale = app(BillingService::class)->processSale([
            'items' => [
                ['product_id' => $product->id, 'quantity' => 1, 'unit_price' => 50000.00],
            ],
            'payments' => [
                ['payment_method' => 'card', 'amount' => 50000.00],
            ],
        ], $store, $cashier);

        $commission = StaffCommission::where('sale_id', $sale->id)->firstOrFail();

        // 1. Associate self-summary endpoint
        $meRes = $this->actingAs($cashier)->getJson('/api/v1/commissions/me?days=30');
        $meRes->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('data.commission_rate', 4)
            ->assertJsonPath('data.monthly_target', 100000);

        // 2. Network leaderboard endpoint
        $boardRes = $this->actingAs($cashier)->getJson('/api/v1/commissions/leaderboard?days=30');
        $boardRes->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonFragment(['user_id' => $cashier->id]);

        // 3. Settle payout endpoint
        $payRes = $this->actingAs($cashier)->postJson("/api/v1/commissions/{$commission->uuid}/pay");
        $payRes->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('data.status', 'paid');
    }
}
