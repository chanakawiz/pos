<?php

namespace Tests\Feature;

use App\Models\CashSession;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class CashSessionTest extends TestCase
{
    use DatabaseTransactions;

    public function test_can_open_session_and_generate_x_report_and_z_report(): void
    {
        $cashier = User::where('email', 'cashier1@smartshop.com')->first();

        // Ensure no leftover open session
        CashSession::where('cashier_id', $cashier->id)->where('status', 'open')->delete();

        // 1. Open Session with float
        $openResponse = $this->actingAs($cashier)->postJson('/api/v1/cash-sessions/open', [
            'opening_balance' => 120.00,
            'notes' => 'Morning shift open',
        ]);

        $openResponse->assertStatus(201)
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('session.opening_balance', '120.00')
            ->assertJsonPath('session.status', 'open');

        // 2. Fetch current session with summary
        $currentResponse = $this->actingAs($cashier)->getJson('/api/v1/cash-sessions/current');
        $currentResponse->assertStatus(200)
            ->assertJsonPath('status', 'open')
            ->assertJsonPath('summary.opening_float', 120)
            ->assertJsonPath('summary.expected_cash', 120);

        // 3. Generate X-Report (mid-shift audit)
        $xReportResponse = $this->actingAs($cashier)->getJson('/api/v1/cash-sessions/x-report');
        $xReportResponse->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('type', 'X-REPORT')
            ->assertJsonPath('report.opening_float', 120)
            ->assertJsonPath('report.status', 'ACTIVE');

        // 4. Close Session and generate Z-Report
        $closeResponse = $this->actingAs($cashier)->postJson('/api/v1/cash-sessions/close', [
            'closing_balance' => 125.00, // $5 overage
            'notes' => 'Evening register count',
        ]);

        $closeResponse->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('type', 'Z-REPORT')
            ->assertJsonPath('report.actual_closing_cash', 125)
            ->assertJsonPath('report.discrepancy', 5)
            ->assertJsonPath('session.status', 'closed');
    }

    public function test_can_record_cash_drops_petty_cash_and_pay_ins_affecting_expected_cash(): void
    {
        $cashier = User::where('email', 'cashier1@smartshop.com')->first();
        CashSession::where('cashier_id', $cashier->id)->where('status', 'open')->delete();

        // 1. Open shift with 15,000 float
        $this->actingAs($cashier)->postJson('/api/v1/cash-sessions/open', [
            'opening_balance' => 15000.00,
        ])->assertStatus(201);

        // 2. Record float pay-in (+5,000) -> expected 20,000
        $payInRes = $this->actingAs($cashier)->postJson('/api/v1/cash-sessions/movements', [
            'type' => 'cash_in',
            'amount' => 5000.00,
            'reason' => 'Mid-day change replenishment',
            'reference' => 'TOPUP-01',
        ]);
        $payInRes->assertStatus(201)
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('movement.type', 'cash_in')
            ->assertJsonPath('summary.cash_in_total', 5000)
            ->assertJsonPath('summary.expected_cash', 20000);

        // 3. Record safe cash drop (-8,000) -> expected 12,000
        $dropRes = $this->actingAs($cashier)->postJson('/api/v1/cash-sessions/movements', [
            'type' => 'cash_out',
            'amount' => 8000.00,
            'reason' => 'Mid-shift safe drop',
        ]);
        $dropRes->assertStatus(201)
            ->assertJsonPath('summary.cash_drop_total', 8000)
            ->assertJsonPath('summary.expected_cash', 12000);

        // 4. Record petty cash payout (-1,500) -> expected 10,500
        $pettyRes = $this->actingAs($cashier)->postJson('/api/v1/cash-sessions/movements', [
            'type' => 'petty_cash',
            'amount' => 1500.00,
            'reason' => 'Courier packaging supplies',
        ]);
        $pettyRes->assertStatus(201)
            ->assertJsonPath('summary.cash_drop_total', 9500)
            ->assertJsonPath('summary.movements_count', 3)
            ->assertJsonPath('summary.expected_cash', 10500);

        // 5. Fetch movements ledger
        $listRes = $this->actingAs($cashier)->getJson('/api/v1/cash-sessions/movements');
        $listRes->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonCount(3, 'data')
            ->assertJsonPath('summary.expected_cash', 10500);

        // 6. Close session at exact expected cash (10,500) -> 0 discrepancy
        $closeRes = $this->actingAs($cashier)->postJson('/api/v1/cash-sessions/close', [
            'closing_balance' => 10500.00,
            'notes' => 'Balanced after safe drop & petty cash',
        ]);
        $closeRes->assertStatus(200)
            ->assertJsonPath('report.cash_in_total', 5000)
            ->assertJsonPath('report.cash_drop_total', 9500)
            ->assertJsonPath('report.expected_cash', 10500)
            ->assertJsonPath('report.discrepancy', 0);
    }

    public function test_cannot_record_cash_movement_without_open_session(): void
    {
        $cashier = User::where('email', 'cashier1@smartshop.com')->first();
        CashSession::where('cashier_id', $cashier->id)->where('status', 'open')->delete();

        $res = $this->actingAs($cashier)->postJson('/api/v1/cash-sessions/movements', [
            'type' => 'cash_out',
            'amount' => 2500.00,
            'reason' => 'Safe drop',
        ]);

        $res->assertStatus(422)
            ->assertJsonPath('status', 'error');
    }
}
