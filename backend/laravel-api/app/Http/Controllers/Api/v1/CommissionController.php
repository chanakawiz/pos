<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\StaffCommission;
use App\Services\CommissionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CommissionController extends Controller
{
    public function __construct(
        protected CommissionService $commissionService
    ) {}

    /**
     * Store / network associate sales & commission leaderboard.
     */
    public function leaderboard(Request $request): JsonResponse
    {
        $days = min(365, max(1, (int) $request->query('days', 30)));
        $storeId = $request->filled('store_id') ? (int) $request->query('store_id') : null;

        $leaderboard = $this->commissionService->getLeaderboard($storeId, $days);

        return response()->json([
            'status' => 'success',
            'period_days' => $days,
            'data' => $leaderboard,
        ]);
    }

    /**
     * Personal earnings & monthly target progress for the authenticated associate.
     */
    public function me(Request $request): JsonResponse
    {
        $days = min(365, max(1, (int) $request->query('days', 30)));
        $summary = $this->commissionService->getAssociateSummary($request->user(), $days);

        return response()->json([
            'status' => 'success',
            'data' => $summary,
        ]);
    }

    /**
     * Mark a staff commission payout as settled/paid.
     */
    public function markPaid(string $uuid): JsonResponse
    {
        $commission = StaffCommission::where('uuid', $uuid)->firstOrFail();
        $paid = $this->commissionService->markPaid($commission);

        return response()->json([
            'status' => 'success',
            'message' => 'Commission marked as paid.',
            'data' => $paid,
        ]);
    }
}
