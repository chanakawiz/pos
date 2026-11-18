<?php

namespace Tests\Feature;

use App\Models\CashSession;
use App\Models\Device;
use App\Models\EodReport;
use App\Models\Payment;
use App\Models\Product;
use App\Models\Sale;
use App\Models\SaleItem;
use App\Models\SmsLog;
use App\Models\Store;
use App\Models\User;
use App\Services\EodCloseoutService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class EodCloseoutTest extends TestCase
{
    use DatabaseTransactions;

    protected Store $store;
    protected User $cashier;
    protected User $manager;
    protected Device $device;

    protected function setUp(): void
    {
        parent::setUp();

        $this->store = Store::first() ?? Store::create([
            'code' => 'STORE-EOD-01',
            'name' => 'Flagship Boutique',
            'phone' => '0771234567',
            'email' => 'store@omniluxe.store',
            'currency_symbol' => 'LKR',
            'is_active' => true,
        ]);

        $this->cashier = User::where('email', 'cashier1@smartshop.com')->first()
            ?? User::factory()->create(['name' => 'Test Cashier', 'email' => 'testcashier@smartshop.com']);

        $this->manager = User::where('email', 'manager@smartshop.com')->first()
            ?? User::factory()->create(['name' => 'Store Manager', 'email' => 'testmanager@smartshop.com', 'phone' => '0779998888']);

        $this->device = Device::first() ?? Device::create([
            'store_id' => $this->store->id,
            'device_code' => 'LANE-EOD-01',
            'device_name' => 'Register Lane 01',
            'is_active' => true,
        ]);
    }

    public function test_status_query_detects_open_registers_and_calculates_cash_at_risk(): void
    {
        // Ensure clean state for this cashier
        CashSession::where('cashier_id', $this->cashier->id)->update(['status' => 'closed']);

        $session = CashSession::create([
            'store_id' => $this->store->id,
            'device_id' => $this->device->id,
            'cashier_id' => $this->cashier->id,
            'opened_at' => now()->subHours(4),
            'opening_balance' => 15000.00,
            'status' => 'open',
        ]);

        $service = app(EodCloseoutService::class);
        $status = $service->getRegisterStatus($this->store->id);

        $this->assertGreaterThanOrEqual(1, $status['open_sessions_count']);
        $this->assertGreaterThanOrEqual(15000.00, $status['cash_at_risk']);

        $found = collect($status['registers'])->firstWhere('session_uuid', $session->uuid);
        $this->assertNotNull($found);
        $this->assertEquals(15000.00, $found['opening_float']);
    }

    public function test_daily_summary_aggregates_cash_card_discounts_and_refunds(): void
    {
        $product = Product::first();

        // Create a completed sale today
        $sale = Sale::create([
            'store_id' => $this->store->id,
            'cashier_id' => $this->cashier->id,
            'device_id' => $this->device->id,
            'invoice_number' => 'INV-EOD-' . uniqid(),
            'subtotal' => 25000.00,
            'discount_amount' => 1000.00,
            'tax_amount' => 0.00,
            'total_amount' => 24000.00,
            'paid_amount' => 24000.00,
            'payment_status' => 'paid',
            'fulfillment_status' => 'delivered',
            'channel' => 'pos',
            'sold_at' => now(),
        ]);

        // Pay 14,000 cash, 10,000 card
        Payment::create([
            'sale_id' => $sale->id,
            'payment_method' => 'cash',
            'amount' => 14000.00,
            'paid_at' => now(),
        ]);

        Payment::create([
            'sale_id' => $sale->id,
            'payment_method' => 'card',
            'amount' => 10000.00,
            'paid_at' => now(),
        ]);

        $service = app(EodCloseoutService::class);
        $summary = $service->calculateDailySummary($this->store);

        $this->assertGreaterThanOrEqual(24000.00, $summary['gross_sales']);
        $this->assertGreaterThanOrEqual(14000.00, $summary['cash_sales']);
        $this->assertGreaterThanOrEqual(10000.00, $summary['card_sales']);
        $this->assertGreaterThanOrEqual(1000.00, $summary['total_discounts']);
    }

    public function test_closeout_closes_open_sessions_and_creates_eod_report(): void
    {
        CashSession::where('cashier_id', $this->cashier->id)->update(['status' => 'closed']);

        $session = CashSession::create([
            'store_id' => $this->store->id,
            'device_id' => $this->device->id,
            'cashier_id' => $this->cashier->id,
            'opened_at' => now()->subHours(6),
            'opening_balance' => 10000.00,
            'status' => 'open',
        ]);

        $service = app(EodCloseoutService::class);
        $report = $service->performCloseout($this->store, [
            'force' => true,
            'is_automated' => false,
            'notify_sms' => false,
            'notes' => 'Test closeout',
        ]);

        $this->assertInstanceOf(EodReport::class, $report);
        $this->assertEquals($this->store->id, $report->store_id);
        $this->assertGreaterThanOrEqual(1, $report->closed_sessions_count);

        // Verify session was marked closed
        $this->assertEquals('closed', $session->fresh()->status);
        $this->assertNotNull($session->fresh()->closed_at);
        $this->assertNotNull($session->fresh()->closing_balance);
    }

    public function test_closeout_dispatches_manager_sms_digest(): void
    {
        $report = EodReport::create([
            'store_id' => $this->store->id,
            'report_date' => Carbon::today(),
            'closed_sessions_count' => 2,
            'total_opening_float' => 20000.00,
            'total_cash_sales' => 50000.00,
            'total_card_sales' => 30000.00,
            'total_gift_card_sales' => 0.00,
            'gross_sales' => 80000.00,
            'total_discounts' => 2000.00,
            'total_refunds' => 0.00,
            'net_sales' => 80000.00,
            'expected_cash' => 70000.00,
            'actual_closing_cash' => 70000.00,
            'net_discrepancy' => 0.00,
            'is_automated' => true,
        ]);

        $service = app(EodCloseoutService::class);
        $smsLog = $service->dispatchEodSms($report, $this->store, '0771234567');

        $this->assertInstanceOf(SmsLog::class, $smsLog);
        $this->assertEquals('eod_summary', $smsLog->event_type);
        $this->assertStringContainsString('EOD Report', $smsLog->message);
        $this->assertStringContainsString('Balanced', $smsLog->message);
    }

    public function test_artisan_eod_closeout_command_dry_run_and_execution(): void
    {
        // Dry run
        $this->artisan('pos:eod-closeout', [
            '--store' => $this->store->id,
            '--dry-run' => true,
        ])->assertExitCode(0);

        // Actual automated closeout
        $this->artisan('pos:eod-closeout', [
            '--store' => $this->store->id,
            '--force' => true,
            '--notify' => true,
        ])->assertExitCode(0);

        $this->assertDatabaseHas('eod_reports', [
            'store_id' => $this->store->id,
            'report_date' => Carbon::today()->toDateString(),
            'is_automated' => 1,
        ]);
    }

    public function test_api_eod_status_summary_and_closeout_endpoints(): void
    {
        // 1. Status API
        $statusRes = $this->actingAs($this->manager)
            ->getJson("/api/v1/eod/status?store_id={$this->store->id}");

        $statusRes->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonStructure([
                'data' => [
                    'open_sessions_count',
                    'cash_at_risk',
                    'registers',
                ],
            ]);

        // 2. Summary API
        $summaryRes = $this->actingAs($this->manager)
            ->getJson("/api/v1/eod/summary?store_id={$this->store->id}");

        $summaryRes->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonStructure([
                'summary' => [
                    'gross_sales',
                    'cash_sales',
                    'card_sales',
                    'expected_cash',
                ],
            ]);

        // 3. Closeout API
        $closeoutRes = $this->actingAs($this->manager)
            ->postJson('/api/v1/eod/closeout', [
                'store_id' => $this->store->id,
                'force' => true,
                'notes' => 'API Manager Closeout Test',
                'notify_sms' => false,
            ]);

        $closeoutRes->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('type', 'CONSOLIDATED-Z-REPORT')
            ->assertJsonStructure(['report' => ['uuid', 'report_date', 'gross_sales']]);

        // 4. History API
        $historyRes = $this->actingAs($this->manager)
            ->getJson("/api/v1/eod/history?store_id={$this->store->id}");

        $historyRes->assertStatus(200)
            ->assertJsonPath('status', 'success');
    }

    public function test_resend_eod_sms_endpoint(): void
    {
        $report = EodReport::create([
            'store_id' => $this->store->id,
            'report_date' => Carbon::today(),
            'gross_sales' => 150000.00,
            'total_cash_sales' => 80000.00,
            'total_card_sales' => 70000.00,
            'net_sales' => 150000.00,
            'expected_cash' => 90000.00,
            'actual_closing_cash' => 90000.00,
            'net_discrepancy' => 0.00,
            'closed_sessions_count' => 3,
        ]);

        $resendRes = $this->actingAs($this->manager)
            ->postJson("/api/v1/eod/{$report->uuid}/resend-sms", [
                'phone' => '0779876543',
            ]);

        $resendRes->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonStructure(['sms_log']);
    }
}
