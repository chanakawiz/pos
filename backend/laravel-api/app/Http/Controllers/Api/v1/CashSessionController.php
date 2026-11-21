<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\CashSession;
use App\Models\CashSessionMovement;
use App\Models\Payment;
use App\Models\Refund;
use App\Models\Sale;
use App\Models\Store;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CashSessionController extends Controller
{
    /**
     * Open a new cash drawer session.
     */
    public function open(Request $request): JsonResponse
    {
        $request->validate([
            'opening_balance' => 'required|numeric|min:0',
            'notes' => 'nullable|string',
        ]);

        $user = $request->user();
        $store = $user->store ?? Store::firstOrFail();

        // Check if there is already an open session
        $existing = CashSession::where('cashier_id', $user->id)
            ->where('status', 'open')
            ->first();

        if ($existing) {
            return response()->json([
                'status' => 'error',
                'message' => 'An active cash session is already open for this cashier.',
                'session' => $existing,
            ], 422);
        }

        $session = CashSession::create([
            'store_id' => $store->id,
            'cashier_id' => $user->id,
            'opened_at' => Carbon::now(),
            'opening_balance' => (float) $request->opening_balance,
            'notes' => $request->notes,
            'status' => 'open',
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Cash session opened.',
            'session' => $session,
        ], 201);
    }

    /**
     * Get active session with live financial summary.
     */
    public function current(Request $request): JsonResponse
    {
        $user = $request->user();

        $session = CashSession::where('cashier_id', $user->id)
            ->where('status', 'open')
            ->first();

        if (!$session) {
            return response()->json(['status' => 'none', 'session' => null]);
        }

        $summary = $this->calculateSessionSummary($session);

        return response()->json([
            'status' => 'open',
            'session' => $session,
            'summary' => $summary,
        ]);
    }

    /**
     * Generate mid-shift X-Report (inquiry without closing register).
     */
    public function xReport(Request $request): JsonResponse
    {
        $user = $request->user();

        $session = CashSession::where('cashier_id', $user->id)
            ->where('status', 'open')
            ->firstOrFail();

        $summary = $this->calculateSessionSummary($session);

        return response()->json([
            'status' => 'success',
            'type' => 'X-REPORT',
            'title' => 'MID-SHIFT AUDIT (X-REPORT)',
            'report' => [
                'session_uuid' => $session->uuid,
                'store_name' => $session->store->name ?? 'Downtown Store',
                'cashier_name' => $session->cashier->name ?? $user->name,
                'opened_at' => $session->opened_at->toIso8601String(),
                'report_generated_at' => Carbon::now()->toIso8601String(),
                'status' => 'ACTIVE',
                'opening_float' => (float) $session->opening_balance,
                'cash_sales' => $summary['cash_sales'],
                'card_sales' => $summary['card_sales'],
                'gross_sales' => $summary['gross_sales'],
                'discount_total' => $summary['total_discounts'],
                'refund_total' => $summary['total_refunds'],
                'cash_in_total' => $summary['cash_in_total'],
                'cash_drop_total' => $summary['cash_drop_total'],
                'transactions_count' => $summary['transaction_count'],
                'expected_cash_in_drawer' => $summary['expected_cash'],
            ],
        ]);
    }

    /**
     * List cash drops and pay-in/pay-out movements for the active cash session.
     */
    public function movements(Request $request): JsonResponse
    {
        $user = $request->user();

        $session = CashSession::where('cashier_id', $user->id)
            ->where('status', 'open')
            ->first();

        if (!$session) {
            return response()->json([
                'status' => 'none',
                'data' => [],
            ]);
        }

        $movements = $session->movements()
            ->with('user:id,name')
            ->latest('recorded_at')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $movements,
            'summary' => $this->calculateSessionSummary($session),
        ]);
    }

    /**
     * Record a petty cash expense, safe drop, or float pay-in on the active session.
     */
    public function recordMovement(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'type' => 'required|in:cash_in,cash_out,petty_cash',
            'amount' => 'required|numeric|min:0.01',
            'reason' => 'required|string|max:255',
            'reference' => 'nullable|string|max:100',
            'notes' => 'nullable|string|max:500',
        ]);

        $user = $request->user();

        $session = CashSession::where('cashier_id', $user->id)
            ->where('status', 'open')
            ->first();

        if (!$session) {
            return response()->json([
                'status' => 'error',
                'message' => 'No active open cash session found for this cashier.',
            ], 422);
        }

        $movement = CashSessionMovement::create([
            'cash_session_id' => $session->id,
            'store_id' => $session->store_id,
            'user_id' => $user->id,
            'type' => $validated['type'],
            'amount' => (float) $validated['amount'],
            'reason' => $validated['reason'],
            'reference' => $validated['reference'] ?? ('DRP-' . strtoupper(substr(md5((string) microtime(true)), 0, 6))),
            'notes' => $validated['notes'] ?? null,
            'recorded_at' => Carbon::now(),
        ]);

        $summary = $this->calculateSessionSummary($session);

        return response()->json([
            'status' => 'success',
            'message' => 'Cash drawer movement recorded.',
            'movement' => $movement,
            'summary' => $summary,
        ], 201);
    }

    /**
     * Close active session with closing count and generate final Z-Report.
     */
    public function close(Request $request): JsonResponse
    {
        $request->validate([
            'closing_balance' => 'required|numeric|min:0',
            'notes' => 'nullable|string',
        ]);

        $user = $request->user();

        $session = CashSession::where('cashier_id', $user->id)
            ->where('status', 'open')
            ->firstOrFail();

        $summary = $this->calculateSessionSummary($session);

        $closing = (float) $request->closing_balance;
        $expected = $summary['expected_cash'];
        $discrepancy = $closing - $expected;

        $session->update([
            'closed_at' => Carbon::now(),
            'closing_balance' => $closing,
            'expected_balance' => $expected,
            'discrepancy' => $discrepancy,
            'notes' => $request->notes ?? $session->notes,
            'status' => 'closed',
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Cash session closed successfully.',
            'type' => 'Z-REPORT',
            'session' => $session->fresh(),
            'report' => [
                'session_uuid' => $session->uuid,
                'store_name' => $session->store->name ?? 'Downtown Store',
                'cashier_name' => $session->cashier->name ?? $user->name,
                'opened_at' => $session->opened_at->toIso8601String(),
                'closed_at' => $session->closed_at->toIso8601String(),
                'status' => 'CLOSED',
                'opening_float' => (float) $session->opening_balance,
                'cash_sales' => $summary['cash_sales'],
                'card_sales' => $summary['card_sales'],
                'gross_sales' => $summary['gross_sales'],
                'discount_total' => $summary['total_discounts'],
                'refund_total' => $summary['total_refunds'],
                'cash_in_total' => $summary['cash_in_total'],
                'cash_drop_total' => $summary['cash_drop_total'],
                'transactions_count' => $summary['transaction_count'],
                'expected_cash' => $expected,
                'actual_closing_cash' => $closing,
                'discrepancy' => $discrepancy,
                'notes' => $session->notes,
            ],
        ]);
    }

    /**
     * Compute comprehensive financial metrics for a shift session.
     */
    protected function calculateSessionSummary(CashSession $session): array
    {
        $openedAt = $session->opened_at;
        $closedAt = $session->closed_at ?? Carbon::now();

        $saleIds = Sale::where('cashier_id', $session->cashier_id)
            ->where('sold_at', '>=', $openedAt)
            ->where('sold_at', '<=', $closedAt)
            ->pluck('id');

        $salesQuery = Sale::whereIn('id', $saleIds);
        $transactionCount = $salesQuery->count();
        $grossSales = (float) $salesQuery->sum('total_amount');
        $totalDiscounts = (float) $salesQuery->sum('discount_amount');

        $cashSales = (float) Payment::whereIn('sale_id', $saleIds)
            ->where('payment_method', 'cash')
            ->sum('amount');

        $cardSales = (float) Payment::whereIn('sale_id', $saleIds)
            ->where('payment_method', 'card')
            ->sum('amount');

        $totalRefunds = (float) Refund::where('cashier_id', $session->cashier_id)
            ->where('created_at', '>=', $openedAt)
            ->where('created_at', '<=', $closedAt)
            ->sum('amount');

        $refundCount = Refund::where('cashier_id', $session->cashier_id)
            ->where('created_at', '>=', $openedAt)
            ->where('created_at', '<=', $closedAt)
            ->count();

        $cashInTotal = (float) $session->movements()
            ->where('type', 'cash_in')
            ->sum('amount');

        $cashDropTotal = (float) $session->movements()
            ->whereIn('type', ['cash_out', 'petty_cash'])
            ->sum('amount');

        $movementsCount = $session->movements()->count();

        $openingFloat = (float) $session->opening_balance;
        $expectedCash = round($openingFloat + $cashSales + $cashInTotal - $cashDropTotal - $totalRefunds, 2);

        return [
            'transaction_count' => $transactionCount,
            'gross_sales' => $grossSales,
            'total_discounts' => $totalDiscounts,
            'cash_sales' => $cashSales,
            'card_sales' => $cardSales,
            'total_refunds' => $totalRefunds,
            'refund_count' => $refundCount,
            'cash_in_total' => $cashInTotal,
            'cash_drop_total' => $cashDropTotal,
            'movements_count' => $movementsCount,
            'opening_float' => $openingFloat,
            'expected_cash' => $expectedCash,
        ];
    }
}
