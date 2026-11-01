<?php

namespace Tests\Feature;

use App\Models\CashSession;
use App\Models\Inventory;
use App\Models\Product;
use App\Models\Sale;
use App\Models\SaleItem;
use App\Models\Store;
use App\Models\User;
use App\Services\BranchAnalyticsService;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class BranchPerformanceTest extends TestCase
{
    use DatabaseTransactions;

    protected User $adminUser;
    protected Store $flagship;
    protected Store $kandy;
    protected Store $galle;

    protected function setUp(): void
    {
        parent::setUp();

        $this->adminUser = User::where('email', 'admin@smartshop.com')->first();
        $this->flagship = Store::where('code', 'STORE-001')->first();
        $this->kandy = Store::where('code', 'STORE-002')->first();
        $this->galle = Store::where('code', 'STORE-003')->first();
    }

    public function test_service_computes_multi_branch_performance_summary(): void
    {
        /** @var BranchAnalyticsService $analytics */
        $analytics = app(BranchAnalyticsService::class);
        $summary = $analytics->getBranchPerformanceSummary();

        $this->assertNotEmpty($summary);
        $this->assertGreaterThanOrEqual(3, $summary->count());

        $flagshipData = $summary->firstWhere('store_code', 'STORE-001');
        $this->assertNotNull($flagshipData);
        $this->assertArrayHasKey('revenue', $flagshipData);
        $this->assertArrayHasKey('gross_margin', $flagshipData);
        $this->assertArrayHasKey('margin_percent', $flagshipData);
        $this->assertArrayHasKey('cogs', $flagshipData);
        $this->assertArrayHasKey('inventory_units', $flagshipData);
        $this->assertArrayHasKey('inventory_value', $flagshipData);
    }

    public function test_service_computes_cashier_sales_velocity_and_drawer_discrepancy(): void
    {
        /** @var BranchAnalyticsService $analytics */
        $analytics = app(BranchAnalyticsService::class);
        $cashiers = $analytics->getCashierPerformance();

        $this->assertNotEmpty($cashiers);

        $sarah = $cashiers->firstWhere('email', 'cashier1@smartshop.com');
        $this->assertNotNull($sarah);
        $this->assertArrayHasKey('sales_count', $sarah);
        $this->assertArrayHasKey('total_volume', $sarah);
        $this->assertArrayHasKey('sessions_count', $sarah);
        $this->assertArrayHasKey('accuracy_percent', $sarah);
        $this->assertArrayHasKey('status', $sarah);
    }

    public function test_service_computes_stock_aging_and_transfer_recommendations(): void
    {
        /** @var BranchAnalyticsService $analytics */
        $analytics = app(BranchAnalyticsService::class);
        $recommendations = $analytics->getStockAgingAndRecommendations(10);

        $this->assertNotEmpty($recommendations);

        $first = $recommendations->first();
        $this->assertArrayHasKey('product_name', $first);
        $this->assertArrayHasKey('sku', $first);
        $this->assertArrayHasKey('store_name', $first);
        $this->assertArrayHasKey('quantity_on_hand', $first);
        $this->assertArrayHasKey('stock_value', $first);
        $this->assertArrayHasKey('velocity', $first);
        $this->assertArrayHasKey('velocity_label', $first);
        $this->assertArrayHasKey('recommendation', $first);
    }

    public function test_service_computes_executive_kpis(): void
    {
        /** @var BranchAnalyticsService $analytics */
        $analytics = app(BranchAnalyticsService::class);
        $kpis = $analytics->getExecutiveKpis();

        $this->assertArrayHasKey('total_revenue', $kpis);
        $this->assertArrayHasKey('total_orders', $kpis);
        $this->assertArrayHasKey('gross_margin', $kpis);
        $this->assertArrayHasKey('margin_percent', $kpis);
        $this->assertArrayHasKey('accuracy_rate', $kpis);
        $this->assertArrayHasKey('network_inventory_units', $kpis);
        $this->assertArrayHasKey('network_inventory_valuation', $kpis);
        $this->assertArrayHasKey('top_branch_name', $kpis);
    }

    public function test_api_can_fetch_branch_performance_telemetry(): void
    {
        $response = $this->actingAs($this->adminUser)->getJson('/api/v1/reports/branch-performance');

        $response->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonStructure([
                'status',
                'data' => [
                    'kpis' => [
                        'total_revenue',
                        'gross_margin',
                        'margin_percent',
                        'accuracy_rate',
                        'network_inventory_valuation',
                    ],
                    'branches',
                    'cashiers',
                ],
            ]);
    }

    public function test_api_can_fetch_stock_aging_and_transfer_recommendations(): void
    {
        $response = $this->actingAs($this->adminUser)->getJson('/api/v1/reports/stock-aging?limit=15');

        $response->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonStructure([
                'status',
                'data' => [
                    'total_analyzed',
                    'recommendations',
                ],
            ]);

        $this->assertGreaterThan(0, $response->json('data.total_analyzed'));
    }
}
