<?php

namespace App\Services;

use App\Models\CashSession;
use App\Models\Inventory;
use App\Models\Product;
use App\Models\Sale;
use App\Models\StockMovement;
use App\Models\Store;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class BranchAnalyticsService
{
    /**
     * Compute comparative revenue, cost of goods sold, and gross margins across all stores.
     */
    public function getBranchPerformanceSummary(?Carbon $startDate = null, ?Carbon $endDate = null): Collection
    {
        $stores = Store::where('is_active', true)->get();

        return $stores->map(function (Store $store) use ($startDate, $endDate) {
            $salesQuery = Sale::where('store_id', $store->id)
                ->where('sale_status', 'completed');

            if ($startDate) {
                $salesQuery->where('sold_at', '>=', $startDate);
            }
            if ($endDate) {
                $salesQuery->where('sold_at', '<=', $endDate);
            }

            $revenue = (float) $salesQuery->sum('total_amount');
            $ordersCount = (int) $salesQuery->count();

            // Cost of Goods Sold (COGS)
            $cogsQuery = DB::table('sale_items')
                ->join('sales', 'sale_items.sale_id', '=', 'sales.id')
                ->where('sales.store_id', $store->id)
                ->where('sales.sale_status', 'completed');

            if ($startDate) {
                $cogsQuery->where('sales.sold_at', '>=', $startDate);
            }
            if ($endDate) {
                $cogsQuery->where('sales.sold_at', '<=', $endDate);
            }

            $cogs = (float) $cogsQuery->sum(DB::raw('sale_items.quantity * COALESCE(sale_items.unit_cost, 0)'));
            $grossMargin = $revenue - $cogs;
            $marginPercent = $revenue > 0 ? round(($grossMargin / $revenue) * 100, 2) : 0.0;
            $aov = $ordersCount > 0 ? round($revenue / $ordersCount, 2) : 0.0;

            // Channel splits
            $onlineRevenue = (float) (clone $salesQuery)->where('source', 'online')->sum('total_amount');
            $offlineRevenue = (float) (clone $salesQuery)->where('source', 'offline')->sum('total_amount');

            // Inventory telemetry for this branch
            $inventoryStats = DB::table('inventory')
                ->join('products', 'inventory.product_id', '=', 'products.id')
                ->where('inventory.store_id', $store->id)
                ->selectRaw('SUM(inventory.quantity_on_hand) as total_units, SUM(inventory.quantity_on_hand * products.cost_price) as total_value')
                ->first();

            return [
                'store_id' => $store->id,
                'store_code' => $store->code,
                'store_name' => $store->name,
                'address' => $store->address,
                'revenue' => $revenue,
                'cogs' => $cogs,
                'gross_margin' => $grossMargin,
                'margin_percent' => $marginPercent,
                'orders_count' => $ordersCount,
                'aov' => $aov,
                'online_revenue' => $onlineRevenue,
                'offline_revenue' => $offlineRevenue,
                'inventory_units' => (float) ($inventoryStats?->total_units ?? 0.0),
                'inventory_value' => (float) ($inventoryStats?->total_value ?? 0.0),
            ];
        });
    }

    /**
     * Compute cashier sales velocity, drawer discrepancies, and balance accuracy.
     */
    public function getCashierPerformance(?Carbon $startDate = null, ?Carbon $endDate = null): Collection
    {
        $cashiers = User::whereIn('role', ['cashier', 'manager', 'admin', 'super_admin'])
            ->with('store')
            ->get();

        return $cashiers->map(function (User $cashier) use ($startDate, $endDate) {
            $salesQuery = Sale::where('cashier_id', $cashier->id)
                ->where('sale_status', 'completed');

            if ($startDate) {
                $salesQuery->where('sold_at', '>=', $startDate);
            }
            if ($endDate) {
                $salesQuery->where('sold_at', '<=', $endDate);
            }

            $salesCount = (int) $salesQuery->count();
            $totalVolume = (float) $salesQuery->sum('total_amount');
            $aov = $salesCount > 0 ? round($totalVolume / $salesCount, 2) : 0.0;

            // Cash sessions audit
            $sessionsQuery = CashSession::where('cashier_id', $cashier->id);
            if ($startDate) {
                $sessionsQuery->where('opened_at', '>=', $startDate);
            }
            if ($endDate) {
                $sessionsQuery->where('opened_at', '<=', $endDate);
            }

            $sessionsCount = (int) $sessionsQuery->count();
            $discrepancyTotal = (float) $sessionsQuery->sum('discrepancy');
            $discrepantSessions = (int) (clone $sessionsQuery)->where('discrepancy', '!=', 0)->count();

            $accuracyPercent = $sessionsCount > 0
                ? round((($sessionsCount - $discrepantSessions) / $sessionsCount) * 100, 1)
                : 100.0;

            $status = $accuracyPercent >= 98.0
                ? 'balanced'
                : ($accuracyPercent >= 90.0 ? 'minor_variance' : 'review_needed');

            return [
                'cashier_id' => $cashier->id,
                'cashier_name' => $cashier->name,
                'email' => $cashier->email,
                'role' => $cashier->role,
                'store_name' => $cashier->store?->name ?? 'Unassigned',
                'sales_count' => $salesCount,
                'total_volume' => $totalVolume,
                'aov' => $aov,
                'sessions_count' => $sessionsCount,
                'discrepant_sessions' => $discrepantSessions,
                'discrepancy_total' => $discrepancyTotal,
                'accuracy_percent' => $accuracyPercent,
                'status' => $status,
            ];
        })->sortByDesc('total_volume')->values();
    }

    /**
     * Compute inventory aging and inter-branch transfer recommendations.
     */
    public function getStockAgingAndRecommendations(int $limit = 50): Collection
    {
        $flagship = Store::where('code', 'STORE-001')->first() ?? Store::first();

        $inventories = Inventory::with(['product.category', 'store'])
            ->where('quantity_on_hand', '>', 0)
            ->get();

        return $inventories->map(function (Inventory $inv) use ($flagship) {
            $product = $inv->product;
            $store = $inv->store;

            // Determine latest activity date for this product at this branch
            $lastSold = DB::table('sale_items')
                ->join('sales', 'sale_items.sale_id', '=', 'sales.id')
                ->where('sales.store_id', $inv->store_id)
                ->where('sale_items.product_id', $inv->product_id)
                ->latest('sales.sold_at')
                ->value('sales.sold_at');

            $lastMovement = StockMovement::where('store_id', $inv->store_id)
                ->where('product_id', $inv->product_id)
                ->latest('created_at')
                ->value('created_at');

            $latestActivity = $lastSold
                ? Carbon::parse($lastSold)
                : ($lastMovement ? Carbon::parse($lastMovement) : $inv->updated_at);

            $daysInactive = max(0, (int) $latestActivity->diffInDays(now()));

            // Classify velocity
            if ($daysInactive <= 14) {
                $velocity = 'fast_moving';
                $velocityLabel = 'Fast Mover (0-14d)';
                $badgeColor = 'success';
                $recommendation = 'Healthy Velocity • Monitor Min Stock';
            } elseif ($daysInactive <= 30) {
                $velocity = 'steady';
                $velocityLabel = 'Steady (15-30d)';
                $badgeColor = 'info';
                $recommendation = 'Optimal Shelf Presence';
            } elseif ($daysInactive <= 60) {
                $velocity = 'slow_moving';
                $velocityLabel = 'Slow Moving (31-60d)';
                $badgeColor = 'warning';
                $recommendation = ($store && $flagship && $store->id !== $flagship->id)
                    ? "Transfer to {$flagship->name}"
                    : 'Targeted Marketing / Display Refresh';
            } else {
                $velocity = 'stagnant';
                $velocityLabel = 'Stagnant / Dead (>60d)';
                $badgeColor = 'danger';
                $recommendation = ($store && $flagship && $store->id !== $flagship->id)
                    ? "Urgent Transfer to {$flagship->name}"
                    : 'VIP Markdown / Clearance Promotion';
            }

            $stockValue = round((float) $inv->quantity_on_hand * (float) ($product?->cost_price ?? 0), 2);

            return [
                'inventory_id' => $inv->id,
                'product_id' => $product?->id,
                'product_name' => $product?->name ?? 'Unknown',
                'sku' => $product?->sku ?? 'N/A',
                'category' => $product?->category?->name ?? 'Uncategorized',
                'store_id' => $store?->id,
                'store_name' => $store?->name ?? 'Unknown Branch',
                'quantity_on_hand' => (float) $inv->quantity_on_hand,
                'cost_price' => (float) ($product?->cost_price ?? 0),
                'selling_price' => (float) ($product?->selling_price ?? 0),
                'stock_value' => $stockValue,
                'days_inactive' => $daysInactive,
                'last_activity' => $latestActivity->toFormattedDateString(),
                'velocity' => $velocity,
                'velocity_label' => $velocityLabel,
                'badge_color' => $badgeColor,
                'recommendation' => $recommendation,
            ];
        })->sortByDesc('days_inactive')->take($limit)->values();
    }

    /**
     * Compute executive KPI summary cards across the entire retail network.
     */
    public function getExecutiveKpis(?Carbon $startDate = null, ?Carbon $endDate = null): array
    {
        $salesQuery = Sale::where('sale_status', 'completed');
        if ($startDate) {
            $salesQuery->where('sold_at', '>=', $startDate);
        }
        if ($endDate) {
            $salesQuery->where('sold_at', '<=', $endDate);
        }

        $totalRevenue = (float) $salesQuery->sum('total_amount');
        $totalOrders = (int) $salesQuery->count();

        $cogsQuery = DB::table('sale_items')
            ->join('sales', 'sale_items.sale_id', '=', 'sales.id')
            ->where('sales.sale_status', 'completed');
        if ($startDate) {
            $cogsQuery->where('sales.sold_at', '>=', $startDate);
        }
        if ($endDate) {
            $cogsQuery->where('sales.sold_at', '<=', $endDate);
        }

        $totalCogs = (float) $cogsQuery->sum(DB::raw('sale_items.quantity * COALESCE(sale_items.unit_cost, 0)'));
        $grossMargin = $totalRevenue - $totalCogs;
        $marginPercent = $totalRevenue > 0 ? round(($grossMargin / $totalRevenue) * 100, 1) : 0.0;

        // Cash reconciliation accuracy
        $sessionsQuery = CashSession::query();
        if ($startDate) {
            $sessionsQuery->where('opened_at', '>=', $startDate);
        }
        if ($endDate) {
            $sessionsQuery->where('opened_at', '<=', $endDate);
        }
        $totalSessions = (int) $sessionsQuery->count();
        $discrepantSessions = (int) (clone $sessionsQuery)->where('discrepancy', '!=', 0)->count();
        $accuracyRate = $totalSessions > 0
            ? round((($totalSessions - $discrepantSessions) / $totalSessions) * 100, 1)
            : 100.0;

        // Network inventory valuation
        $inventoryStats = DB::table('inventory')
            ->join('products', 'inventory.product_id', '=', 'products.id')
            ->selectRaw('SUM(inventory.quantity_on_hand) as units, SUM(inventory.quantity_on_hand * products.cost_price) as valuation')
            ->first();

        // Top branch
        $branchSummary = $this->getBranchPerformanceSummary($startDate, $endDate);
        $topBranch = $branchSummary->sortByDesc('revenue')->first();

        return [
            'total_revenue' => $totalRevenue,
            'total_orders' => $totalOrders,
            'gross_margin' => $grossMargin,
            'margin_percent' => $marginPercent,
            'accuracy_rate' => $accuracyRate,
            'network_inventory_units' => (float) ($inventoryStats?->units ?? 0),
            'network_inventory_valuation' => (float) ($inventoryStats?->valuation ?? 0),
            'top_branch_name' => $topBranch['store_name'] ?? 'N/A',
            'top_branch_revenue' => $topBranch['revenue'] ?? 0.0,
        ];
    }
}
