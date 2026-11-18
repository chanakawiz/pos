<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Sale;
use App\Models\SmsLog;
use App\Services\SmsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SmsController extends Controller
{
    public function __construct(protected SmsService $smsService) {}

    /**
     * Re-send or dispatch a digital e-receipt SMS for a sale to a specified phone number.
     */
    public function resendReceipt(Request $request, string $uuid): JsonResponse
    {
        $validated = $request->validate([
            'phone' => 'nullable|string|max:32',
        ]);

        $sale = Sale::with(['store', 'customer'])->where('uuid', $uuid)->firstOrFail();

        $phone = $validated['phone'] ?? null;
        $smsLog = $this->smsService->sendSaleReceipt($sale, $phone);

        if (!$smsLog) {
            return response()->json([
                'status' => 'error',
                'message' => 'Unable to send SMS: No valid recipient phone number provided for this sale.',
            ], 422);
        }

        return response()->json([
            'status' => $smsLog->status === 'sent' ? 'success' : 'failed',
            'message' => $smsLog->status === 'sent'
                ? "Digital e-receipt SMS sent to {$smsLog->masked_phone}."
                : "SMS delivery failed: {$smsLog->error_message}",
            'data' => [
                'log_uuid' => $smsLog->uuid,
                'status' => $smsLog->status,
                'recipient_phone' => $smsLog->masked_phone,
                'gateway_reference' => $smsLog->gateway_reference,
                'driver' => $smsLog->driver,
                'cost' => (float) $smsLog->cost,
                'sent_at' => $smsLog->sent_at?->toIso8601String(),
            ],
        ], $smsLog->status === 'sent' ? 200 : 502);
    }

    /**
     * List SMS audit logs with store and status filtering.
     */
    public function logs(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = SmsLog::query()
            ->with(['store:id,uuid,name,code', 'customer:id,uuid,name,phone'])
            ->latest('id');

        // Scope to store if cashier or store-assigned user
        if ($user && $user->store_id && $user->role !== 'super_admin') {
            $query->where('store_id', $user->store_id);
        } elseif ($request->filled('store_uuid')) {
            $query->whereHas('store', fn ($q) => $q->where('uuid', $request->store_uuid));
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('event_type')) {
            $query->where('event_type', $request->event_type);
        }

        $perPage = min((int) ($request->get('per_page', 25)), 100);
        $logs = $query->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $logs->items(),
            'meta' => [
                'current_page' => $logs->currentPage(),
                'last_page' => $logs->lastPage(),
                'total' => $logs->total(),
                'per_page' => $logs->perPage(),
            ],
        ]);
    }

    /**
     * Test SMS dispatch connectivity for staff / administrator.
     */
    public function testSend(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone' => 'required|string|max:32',
            'message' => 'nullable|string|max:160',
            'driver' => 'nullable|string|in:log,mock,notify_lk,twilio,dialog_esms',
        ]);

        $message = $validated['message'] ?? 'OmniLuxe Store: This is a gateway test message. Omnichannel retail connectivity operational.';
        $options = [];
        if (!empty($validated['driver'])) {
            $options['driver'] = $validated['driver'];
        }

        $log = $this->smsService->dispatch($validated['phone'], $message, 'test', $options);

        return response()->json([
            'status' => $log->status === 'sent' ? 'success' : 'failed',
            'message' => $log->status === 'sent'
                ? "Test message successfully dispatched via [{$log->driver}]"
                : "Test message failed: {$log->error_message}",
            'data' => [
                'log_uuid' => $log->uuid,
                'driver' => $log->driver,
                'status' => $log->status,
                'gateway_reference' => $log->gateway_reference,
                'recipient' => $log->masked_phone,
            ],
        ]);
    }
}
