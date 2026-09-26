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
}
