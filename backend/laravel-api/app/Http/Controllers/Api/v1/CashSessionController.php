<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\CashSession;
use App\Models\Payment;
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
     * Get active session.
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

        // Calculate current total cash collected
        $cashSales = Payment::whereHas('sale', function ($q) use ($session) {
            $q->where('cashier_id', $session->cashier_id)
                ->where('sold_at', '>=', $session->opened_at);
        })
            ->where('payment_method', 'cash')
            ->sum('amount');

        return response()->json([
            'status' => 'open',
            'session' => $session,
            'current_cash_sales' => (float) $cashSales,
            'expected_balance' => (float) ($session->opening_balance + $cashSales),
        ]);
    }

    /**
     * Close active session with closing count.
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

        $cashSales = (float) Payment::whereHas('sale', function ($q) use ($session) {
            $q->where('cashier_id', $session->cashier_id)
                ->where('sold_at', '>=', $session->opened_at);
        })
            ->where('payment_method', 'cash')
            ->sum('amount');

        $expected = (float) $session->opening_balance + $cashSales;
        $closing = (float) $request->closing_balance;
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
            'session' => $session,
        ]);
    }
}
