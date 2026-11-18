<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\EodReport;
use App\Models\Store;
use App\Services\EodCloseoutService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EodController extends Controller
{
    public function __construct(
        protected EodCloseoutService $eodService
    ) {}

    /**
     * Get real-time status of registers (open sessions, cash at risk).
     */
    public function status(Request $request): JsonResponse
    {
        $user = $request->user();
        $storeId = $request->query('store_id', $user->store_id);

        $status = $this->eodService->getRegisterStatus($storeId ? (int) $storeId : null);

        return response()->json([
            'status' => 'success',
            'data' => $status,
        ]);
    }

    /**
     * Get computed or stored daily EOD financial summary.
     */
    public function summary(Request $request): JsonResponse
    {
        $user = $request->user();
        $storeId = $request->query('store_id', $user->store_id) ?: Store::value('id');
        $store = Store::findOrFail($storeId);

        $dateStr = $request->query('date', Carbon::today()->toDateString());
        $date = Carbon::parse($dateStr);

        // Check if an official EOD report already exists for this date
        $persisted = EodReport::where('store_id', $store->id)
            ->whereDate('report_date', $date)
            ->first();

        $liveSummary = $this->eodService->calculateDailySummary($store, $date);

        return response()->json([
            'status' => 'success',
            'store' => [
                'id' => $store->id,
                'name' => $store->name,
                'code' => $store->code,
                'currency' => $store->currency_symbol ?: 'LKR',
            ],
            'is_finalized' => (bool) $persisted,
            'eod_report' => $persisted,
            'summary' => $liveSummary,
        ]);
    }

    /**
     * Perform End-of-Day closeout: close all open sessions, persist EOD Z-Report, and dispatch SMS.
     */
    public function closeout(Request $request): JsonResponse
    {
        $request->validate([
            'store_id' => 'nullable|exists:stores,id',
            'force' => 'nullable|boolean',
            'closing_balances' => 'nullable|array',
            'notes' => 'nullable|string|max:500',
            'notify_sms' => 'nullable|boolean',
        ]);

        $user = $request->user();
        $storeId = $request->input('store_id', $user->store_id) ?: Store::value('id');
        $store = Store::findOrFail($storeId);

        $report = $this->eodService->performCloseout($store, [
            'force' => (bool) $request->input('force', true),
            'closing_balances' => $request->input('closing_balances', []),
            'notes' => $request->input('notes'),
            'user_id' => $user->id,
            'is_automated' => false,
            'notify_sms' => (bool) $request->input('notify_sms', true),
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'End-of-Day closeout finalized successfully.',
            'type' => 'CONSOLIDATED-Z-REPORT',
            'report' => $report,
        ]);
    }

    /**
     * List historical EOD reports with pagination.
     */
    public function history(Request $request): JsonResponse
    {
        $user = $request->user();
        $storeId = $request->query('store_id', $user->store_id);

        $query = EodReport::with(['store', 'generatedBy'])
            ->orderBy('report_date', 'desc');

        if ($storeId) {
            $query->where('store_id', $storeId);
        }

        $reports = $query->paginate(15);

        return response()->json([
            'status' => 'success',
            'data' => $reports,
        ]);
    }

    /**
     * Resend EOD summary SMS to store manager.
     */
    public function resendSms(Request $request, string $uuid): JsonResponse
    {
        $request->validate([
            'phone' => 'nullable|string|max:20',
        ]);

        $report = EodReport::with('store')->where('uuid', $uuid)->firstOrFail();
        $phone = $request->input('phone');

        $smsLog = $this->eodService->dispatchEodSms($report, $report->store, $phone);

        return response()->json([
            'status' => 'success',
            'message' => 'EOD Summary SMS queued successfully.',
            'sms_log' => $smsLog,
        ]);
    }
}
