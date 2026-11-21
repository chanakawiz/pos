<?php

namespace App\Services;

use App\Models\Sale;
use App\Models\StaffCommission;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class CommissionService
{
    /**
     * Record staff sales commission automatically when a sale is finalized.
     */
    public function recordSaleCommission(Sale $sale): ?StaffCommission
    {
        $cashier = $sale->cashier;
        if (! $cashier || ! $cashier->isStaff()) {
            return null;
        }

        // Prevent duplicate commissions on idempotent retries
        $existing = StaffCommission::where('sale_id', $sale->id)->first();
        if ($existing) {
            return $existing;
        }

        $rate = (float) ($cashier->commission_rate ?? 2.50);
        $saleAmount = (float) $sale->total_amount;
        if ($rate <= 0 || $saleAmount <= 0) {
            return null;
        }

        $commissionAmount = round($saleAmount * ($rate / 100.0), 2);

        return StaffCommission::create([
            'user_id' => $cashier->id,
            'store_id' => $sale->store_id,
            'sale_id' => $sale->id,
            'sale_amount' => $saleAmount,
            'commission_rate' => $rate,
            'commission_amount' => $commissionAmount,
            'status' => 'pending',
            'notes' => "Sale {$sale->invoice_number}",
            'earned_at' => $sale->sold_at ?? Carbon::now(),
        ]);
    }

    /**
     * Adjust or reverse earned commission when a customer return / refund occurs.
     */
    public function reverseSaleCommission(Sale $sale, float $refundAmount): ?StaffCommission
    {
        $commission = StaffCommission::where('sale_id', $sale->id)
            ->whereIn('status', ['pending', 'approved'])
            ->first();

        if (! $commission || $refundAmount <= 0) {
            return null;
        }

        $netSale = max(0.00, round((float) $sale->total_amount - (float) $sale->refunds()->sum('amount'), 2));

        if ($netSale <= 0.01) {
            $commission->update([
                'commission_amount' => 0.00,
                'status' => 'reversed',
                'notes' => trim(($commission->notes ?? '') . ' | Fully reversed due to refund'),
            ]);
        } else {
            $recalculated = round($netSale * ((float) $commission->commission_rate / 100.0), 2);
            $commission->update([
                'sale_amount' => $netSale,
                'commission_amount' => $recalculated,
                'notes' => trim(($commission->notes ?? '') . " | Adjusted after refund (-{$refundAmount})"),
            ]);
        }

        return $commission->fresh();
    }

    /**
     * Rank retail associates by net sales volume, commissions earned, and target attainment.
     */
    public function getLeaderboard(?int $storeId = null, int $days = 30): Collection
    {
        $since = Carbon::now()->subDays(max(1, $days));

        $staff = User::with('store:id,name,code')
            ->whereIn('role', ['cashier', 'manager', 'admin', 'super_admin'])
            ->where('is_active', true)
            ->when($storeId, fn ($q) => $q->where('store_id', $storeId))
            ->get();

        return $staff->map(function (User $user) use ($since) {
            $commissions = StaffCommission::where('user_id', $user->id)
                ->where('earned_at', '>=', $since)
                ->where('status', '!=', 'reversed')
                ->get();

            $totalSales = round((float) $commissions->sum('sale_amount'), 2);
            $totalCommission = round((float) $commissions->sum('commission_amount'), 2);
            $pendingCommission = round((float) $commissions->whereIn('status', ['pending', 'approved'])->sum('commission_amount'), 2);
            $paidCommission = round((float) $commissions->where('status', 'paid')->sum('commission_amount'), 2);
            $salesCount = $commissions->count();
            $avgTicket = $salesCount > 0 ? round($totalSales / $salesCount, 2) : 0.00;
            $target = (float) ($user->monthly_sales_target ?? 500000.00);
            $attainment = $target > 0 ? round(min(999.9, ($totalSales / $target) * 100.0), 1) : 0.0;

            return [
                'user_id' => $user->id,
                'user_uuid' => $user->uuid,
                'name' => $user->name,
                'role' => $user->role,
                'store_name' => $user->store?->name ?? 'Head Office',
                'commission_rate' => (float) ($user->commission_rate ?? 2.50),
                'monthly_target' => $target,
                'sales_count' => $salesCount,
                'total_sales' => $totalSales,
                'average_ticket' => $avgTicket,
                'total_commission' => $totalCommission,
                'pending_commission' => $pendingCommission,
                'paid_commission' => $paidCommission,
                'target_attainment_percent' => $attainment,
            ];
        })
            ->sortByDesc('total_sales')
            ->values()
            ->map(fn ($row, $idx) => ['rank' => $idx + 1, ...$row]);
    }

    /**
     * Personal associate commission summary & recent earnings ledger.
     */
    public function getAssociateSummary(User $user, int $days = 30): array
    {
        $since = Carbon::now()->subDays(max(1, $days));

        $entries = StaffCommission::with('sale:id,uuid,invoice_number,total_amount')
            ->where('user_id', $user->id)
            ->where('earned_at', '>=', $since)
            ->latest('earned_at')
            ->limit(25)
            ->get();

        $active = $entries->where('status', '!=', 'reversed');
        $totalSales = round((float) $active->sum('sale_amount'), 2);
        $totalEarned = round((float) $active->sum('commission_amount'), 2);
        $pending = round((float) $active->whereIn('status', ['pending', 'approved'])->sum('commission_amount'), 2);
        $paid = round((float) $active->where('status', 'paid')->sum('commission_amount'), 2);
        $target = (float) ($user->monthly_sales_target ?? 500000.00);
        $attainment = $target > 0 ? round(min(999.9, ($totalSales / $target) * 100.0), 1) : 0.0;

        return [
            'associate_name' => $user->name,
            'commission_rate' => (float) ($user->commission_rate ?? 2.50),
            'monthly_target' => $target,
            'period_days' => $days,
            'sales_count' => $active->count(),
            'total_sales' => $totalSales,
            'total_commission' => $totalEarned,
            'pending_commission' => $pending,
            'paid_commission' => $paid,
            'target_attainment_percent' => $attainment,
            'recent_commissions' => $entries->map(fn (StaffCommission $c) => [
                'uuid' => $c->uuid,
                'invoice_number' => $c->sale?->invoice_number ?? $c->notes,
                'sale_amount' => (float) $c->sale_amount,
                'commission_rate' => (float) $c->commission_rate,
                'commission_amount' => (float) $c->commission_amount,
                'status' => $c->status,
                'earned_at' => $c->earned_at->toIso8601String(),
            ])->values(),
        ];
    }

    /**
     * Mark commission record as paid out to associate.
     */
    public function markPaid(StaffCommission $commission): StaffCommission
    {
        $commission->update([
            'status' => 'paid',
            'paid_at' => Carbon::now(),
        ]);

        return $commission->fresh();
    }
}
