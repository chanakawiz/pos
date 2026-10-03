<?php

namespace Tests\Feature;

use App\Models\User;
use Tests\TestCase;

class ReportTest extends TestCase
{
    public function test_can_fetch_sales_summary_and_inventory_reports(): void
    {
        $user = User::where('email', 'admin@smartshop.com')->first()
            ?? User::where('email', 'cashier1@smartshop.com')->first();

        // Sales summary report
        $summaryResponse = $this->actingAs($user)->getJson('/api/v1/reports/sales-summary?period=today');
        $summaryResponse->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonStructure([
                'status',
                'period',
                'summary' => [
                    'total_transactions',
                    'gross_revenue',
                    'net_revenue',
                ],
            ]);

        // Top products report
        $topProductsResponse = $this->actingAs($user)->getJson('/api/v1/reports/top-products');
        $topProductsResponse->assertStatus(200)
            ->assertJsonPath('status', 'success');

        // Low stock report
        $lowStockResponse = $this->actingAs($user)->getJson('/api/v1/reports/low-stock');
        $lowStockResponse->assertStatus(200)
            ->assertJsonPath('status', 'success');
    }
}
