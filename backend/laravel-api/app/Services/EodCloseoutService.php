<?php

namespace App\Services;

use App\Models\CashSession;
use App\Models\EodReport;
use App\Models\Payment;
use App\Models\Refund;
use App\Models\Sale;
use App\Models\SmsLog;
use App\Models\Store;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class EodCloseoutService
{
    public function __construct(
        protected SmsService $smsService
    ) {}

    /**
     * Get real-time status of cashier registers across one or all stores.
     */
    public function getRegisterStatus(?int $storeId = null): array
    {
        $query = CashSession::with(['store', 'device', 'cashier'])
            ->where('status', 'open');

        if ($storeId) {
            $query->where('store_id', $storeId);
        }

        $openSessions = $query->get();

        $registers = [];
        $totalCashAtRisk = 0.00;

        foreach ($openSessions as $session) {
            $financials = $this->calculateSessionFinancials($session);
            $totalCashAtRisk += $financials['expected_cash'];

            $registers[] = [
                'session_uuid' => $session->uuid,
                'session_id' => $session->id,
                'store_id' => $session->store_id,
                'store_name' => $session->store->name ?? 'Downtown Store',
                'device_name' => $session->device->name ?? 'Register Lane',
                'cashier_id' => $session->cashier_id,
                'cashier_name' => $session->cashier->name ?? 'Cashier',
                'opened_at' => $session->opened_at->toIso8601String(),
                'elapsed_hours' => round($session->opened_at->diffInMinutes(now()) / 60, 1),
                'opening_float' => (float) $session->opening_balance,
                'cash_sales' => $financials['cash_sales'],
                'card_sales' => $financials['card_sales'],
                'gross_sales' => $financials['gross_sales'],
                'refunds' => $financials['total_refunds'],
                'expected_cash' => $financials['expected_cash'],
                'transactions_count' => $financials['transaction_count'],
            ];
        }

        return [
            'open_sessions_count' => count($registers),
            'cash_at_risk' => round($totalCashAtRisk, 2),
            'registers' => $registers,
            'audited_at' => now()->toIso8601String(),
        ];
    }

    /**
     * Calculate consolidated financial metrics for a specific store on a given date.
     */
    public function calculateDailySummary(Store $store, ?Carbon $date = null): array
    {
        $date = $date ?: Carbon::today();
        $startOfDay = $date->copy()->startOfDay();
        $endOfDay = $date->copy()->endOfDay();

        // Query sales for this store on this date
        $salesQuery = Sale::where('store_id', $store->id)
            ->whereBetween('sold_at', [$startOfDay, $endOfDay]);

        $saleIds = (clone $salesQuery)->pluck('id');
        $transactionCount = $salesQuery->count();
        $grossSales = (float) (clone $salesQuery)->sum('total_amount');
        $totalDiscounts = (float) (clone $salesQuery)->sum('discount_amount');

        // Query payments breakdown
        $cashSales = (float) Payment::whereIn('sale_id', $saleIds)
            ->where('payment_method', 'cash')
            ->sum('amount');

        $cardSales = (float) Payment::whereIn('sale_id', $saleIds)
            ->where('payment_method', 'card')
            ->sum('amount');

        $giftCardSales = (float) Payment::whereIn('sale_id', $saleIds)
            ->where('payment_method', 'gift_card')
            ->sum('amount');

        // Query refunds
        $refundsQuery = Refund::whereHas('sale', function ($sq) use ($store) {
            $sq->where('store_id', $store->id);
        })->whereBetween('created_at', [$startOfDay, $endOfDay]);

        $totalRefunds = (float) (clone $refundsQuery)->sum('amount');
        $refundCount = $refundsQuery->count();

        // Calculate opening floats for all sessions on this date (open or closed)
        $sessions = CashSession::with(['cashier', 'device'])
            ->where('store_id', $store->id)
            ->where(function ($q) use ($startOfDay, $endOfDay) {
                $q->whereBetween('opened_at', [$startOfDay, $endOfDay])
                  ->orWhere('status', 'open');
            })
            ->get();

        $totalOpeningFloat = (float) $sessions->sum('opening_balance');
        $expectedCash = round($totalOpeningFloat + $cashSales - $totalRefunds, 2);
        $netSales = round($grossSales - $totalRefunds, 2);

        $laneBreakdown = [];
        $totalActualClosing = 0.00;

        foreach ($sessions as $session) {
            $fin = $this->calculateSessionFinancials($session);
            $actual = $session->closing_balance !== null ? (float) $session->closing_balance : $fin['expected_cash'];
            $totalActualClosing += $actual;

            $laneBreakdown[] = [
                'session_uuid' => $session->uuid,
                'session_id' => $session->id,
                'cashier' => $session->cashier->name ?? 'Cashier',
                'device' => $session->device->name ?? 'Register',
                'status' => $session->status,
                'opened_at' => $session->opened_at->toIso8601String(),
                'closed_at' => $session->closed_at?->toIso8601String(),
                'opening_float' => (float) $session->opening_balance,
                'cash_sales' => $fin['cash_sales'],
                'card_sales' => $fin['card_sales'],
                'gross_sales' => $fin['gross_sales'],
                'refunds' => $fin['total_refunds'],
                'expected_cash' => $fin['expected_cash'],
                'closing_cash' => $session->closing_balance !== null ? (float) $session->closing_balance : null,
                'discrepancy' => $session->discrepancy !== null ? (float) $session->discrepancy : 0.00,
            ];
        }

        $netDiscrepancy = round($totalActualClosing - $expectedCash, 2);

        return [
            'store_id' => $store->id,
            'store_name' => $store->name,
            'store_code' => $store->code,
            'report_date' => $date->toDateString(),
            'transaction_count' => $transactionCount,
            'gross_sales' => $grossSales,
            'total_discounts' => $totalDiscounts,
            'net_sales' => $netSales,
            'cash_sales' => $cashSales,
            'card_sales' => $cardSales,
            'gift_card_sales' => $giftCardSales,
            'total_refunds' => $totalRefunds,
            'refund_count' => $refundCount,
            'total_opening_float' => $totalOpeningFloat,
            'expected_cash' => $expectedCash,
            'actual_closing_cash' => round($totalActualClosing, 2),
            'net_discrepancy' => $netDiscrepancy,
            'sessions_count' => count($sessions),
            'open_sessions_count' => $sessions->where('status', 'open')->count(),
            'lane_breakdown' => $laneBreakdown,
        ];
    }

    /**
     * Execute End-of-Day closeout for a store.
     * Closes open cash sessions, commits consolidated metrics, and dispatches EOD SMS.
     */
    public function performCloseout(Store $store, array $options = []): EodReport
    {
        $force = (bool) ($options['force'] ?? false);
        $isAutomated = (bool) ($options['is_automated'] ?? false);
        $userId = $options['user_id'] ?? null;
        $notes = $options['notes'] ?? ($isAutomated ? 'Automated EOD Closeout by System Scheduler' : 'Manual EOD Reconciliation');
        $notifySms = (bool) ($options['notify_sms'] ?? true);
        $closingBalances = $options['closing_balances'] ?? []; // Map of session_id => counted amount

        return DB::transaction(function () use ($store, $force, $isAutomated, $userId, $notes, $notifySms, $closingBalances) {
            $openSessions = CashSession::where('store_id', $store->id)
                ->where('status', 'open')
                ->lockForUpdate()
                ->get();

            $closedCount = 0;

            foreach ($openSessions as $session) {
                $financials = $this->calculateSessionFinancials($session);
                $expected = $financials['expected_cash'];

                // If cashier supplied a counted balance in array, use it; otherwise default to expected
                $counted = isset($closingBalances[$session->id])
                    ? (float) $closingBalances[$session->id]
                    : ($isAutomated ? $expected : (float) ($options['closing_balance'] ?? $expected));

                $discrepancy = round($counted - $expected, 2);

                $session->update([
                    'closed_at' => now(),
                    'closing_balance' => $counted,
                    'expected_balance' => $expected,
                    'discrepancy' => $discrepancy,
                    'notes' => trim(($session->notes ? $session->notes . ' | ' : '') . $notes),
                    'status' => 'closed',
                ]);

                $closedCount++;
            }

            // Calculate consolidated daily summary
            $summary = $this->calculateDailySummary($store);

            // Persist or update EodReport for today
            $report = EodReport::updateOrCreate(
                [
                    'store_id' => $store->id,
                    'report_date' => Carbon::today()->toDateString(),
                ],
                [
                    'generated_by' => $userId,
                    'closed_sessions_count' => $closedCount,
                    'total_opening_float' => $summary['total_opening_float'],
                    'total_cash_sales' => $summary['cash_sales'],
                    'total_card_sales' => $summary['card_sales'],
                    'total_gift_card_sales' => $summary['gift_card_sales'],
                    'gross_sales' => $summary['gross_sales'],
                    'total_discounts' => $summary['total_discounts'],
                    'total_refunds' => $summary['total_refunds'],
                    'net_sales' => $summary['net_sales'],
                    'expected_cash' => $summary['expected_cash'],
                    'actual_closing_cash' => $summary['actual_closing_cash'],
                    'net_discrepancy' => $summary['net_discrepancy'],
                    'is_automated' => $isAutomated,
                    'breakdown_json' => $summary['lane_breakdown'],
                    'notes' => $notes,
                ]
            );

            // Dispatch SMS alert to store manager or store contact
            if ($notifySms) {
                $this->dispatchEodSms($report, $store);
            }

            return $report;
        });
    }

    /**
     * Dispatch an executive EOD summary SMS to store manager.
     */
    public function dispatchEodSms(EodReport $report, Store $store, ?string $overridePhone = null): ?SmsLog
    {
        // Target store phone, manager phone, or override
        $phone = $overridePhone ?: $store->phone;

        if (!$phone) {
            // Fallback: look for store manager
            $manager = User::role('manager')->where('store_id', $store->id)->first();
            $phone = $manager->phone ?? config('sms.admin_phone', '0771234567');
        }

        $currency = $store->currency_symbol ?: 'LKR';
        $grossFormatted = number_format($report->gross_sales, 2);
        $cashFormatted = number_format($report->total_cash_sales, 2);
        $cardFormatted = number_format($report->total_card_sales, 2);
        $discFormatted = number_format($report->net_discrepancy, 2);
        $statusStr = abs((float) $report->net_discrepancy) < 0.01 ? 'Balanced' : "Discrepancy: {$currency} {$discFormatted}";

        $message = "OmniLuxe [{$store->name}] EOD Report {$report->report_date->format('Y-m-d')}: Gross {$currency} {$grossFormatted} (Cash: {$cashFormatted}, Card: {$cardFormatted}). {$report->closed_sessions_count} Lanes Closed. {$statusStr}.";

        return $this->smsService->dispatch(
            to: $phone,
            message: $message,
            eventType: 'eod_summary',
            options: [
                'store_id' => $store->id,
                'metadata' => [
                    'eod_report_uuid' => $report->uuid,
                    'report_date' => $report->report_date->toDateString(),
                    'gross_sales' => (float) $report->gross_sales,
                ],
            ]
        );
    }

    /**
     * Calculate financial breakdown for a specific cash session.
     */
    protected function calculateSessionFinancials(CashSession $session): array
    {
        $openedAt = $session->opened_at;
        $closedAt = $session->closed_at ?? now();

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

        $giftCardSales = (float) Payment::whereIn('sale_id', $saleIds)
            ->where('payment_method', 'gift_card')
            ->sum('amount');

        $totalRefunds = (float) Refund::where('cashier_id', $session->cashier_id)
            ->where('created_at', '>=', $openedAt)
            ->where('created_at', '<=', $closedAt)
            ->sum('amount');

        $openingFloat = (float) $session->opening_balance;
        $expectedCash = round($openingFloat + $cashSales - $totalRefunds, 2);

        return [
            'transaction_count' => $transactionCount,
            'gross_sales' => $grossSales,
            'total_discounts' => $totalDiscounts,
            'cash_sales' => $cashSales,
            'card_sales' => $cardSales,
            'gift_card_sales' => $giftCardSales,
            'total_refunds' => $totalRefunds,
            'opening_float' => $openingFloat,
            'expected_cash' => $expectedCash,
        ];
    }
}
