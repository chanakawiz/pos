<?php

namespace App\Filament\Widgets;

use App\Models\CashSession;
use App\Models\Inventory;
use App\Models\Sale;
use Carbon\Carbon;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;
use Illuminate\Support\Facades\DB;

class StatsOverviewWidget extends BaseWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        $today = Carbon::today();

        // 1. Today's Gross Revenue
        $todayRevenue = (float) Sale::whereDate('sold_at', $today)->sum('total_amount');
        $yesterdayRevenue = (float) Sale::whereDate('sold_at', Carbon::yesterday())->sum('total_amount');
        $revenueDiff = $yesterdayRevenue > 0
            ? round((($todayRevenue - $yesterdayRevenue) / $yesterdayRevenue) * 100, 1)
            : ($todayRevenue > 0 ? 100 : 0);

        // 2. Today's Completed Sales Count
        $todaySalesCount = Sale::whereDate('sold_at', $today)->count();

        // 3. Active Cash Register Sessions
        $activeSessionsCount = CashSession::where('status', 'open')->count();

        // 4. Products Low or Out of Stock
        $lowStockCount = Inventory::whereColumn(
            'quantity_on_hand',
            '<=',
            DB::raw('(SELECT min_stock_level FROM products WHERE products.id = inventory.product_id)')
        )->count();

        return [
            Stat::make('Today Gross Revenue', '$' . number_format($todayRevenue, 2))
                ->description(($revenueDiff >= 0 ? "+{$revenueDiff}%" : "{$revenueDiff}%") . ' vs yesterday')
                ->descriptionIcon($revenueDiff >= 0 ? 'heroicon-m-arrow-trending-up' : 'heroicon-m-arrow-trending-down')
                ->color($revenueDiff >= 0 ? 'success' : 'danger')
                ->chart([
                    (float) Sale::whereDate('sold_at', Carbon::today()->subDays(6))->sum('total_amount'),
                    (float) Sale::whereDate('sold_at', Carbon::today()->subDays(5))->sum('total_amount'),
                    (float) Sale::whereDate('sold_at', Carbon::today()->subDays(4))->sum('total_amount'),
                    (float) Sale::whereDate('sold_at', Carbon::today()->subDays(3))->sum('total_amount'),
                    (float) Sale::whereDate('sold_at', Carbon::today()->subDays(2))->sum('total_amount'),
                    $yesterdayRevenue,
                    $todayRevenue,
                ]),

            Stat::make("Today's Transactions", number_format($todaySalesCount))
                ->description('Completed customer checkouts')
                ->descriptionIcon('heroicon-m-shopping-bag')
                ->color('primary'),

            Stat::make('Active Registers', number_format($activeSessionsCount))
                ->description('Open cashier lane shifts')
                ->descriptionIcon('heroicon-m-banknotes')
                ->color($activeSessionsCount > 0 ? 'success' : 'gray'),

            Stat::make('Low Stock Alerts', number_format($lowStockCount))
                ->description('Products needing restock')
                ->descriptionIcon('heroicon-m-exclamation-triangle')
                ->color($lowStockCount > 0 ? 'warning' : 'success'),
        ];
    }
}
