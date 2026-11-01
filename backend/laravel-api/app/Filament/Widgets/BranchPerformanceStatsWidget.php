<?php

namespace App\Filament\Widgets;

use App\Services\BranchAnalyticsService;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class BranchPerformanceStatsWidget extends BaseWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        /** @var BranchAnalyticsService $analytics */
        $analytics = app(BranchAnalyticsService::class);
        $kpis = $analytics->getExecutiveKpis();

        $marginColor = $kpis['margin_percent'] >= 35.0 ? 'success' : ($kpis['margin_percent'] >= 20.0 ? 'warning' : 'danger');
        $accuracyColor = $kpis['accuracy_rate'] >= 98.0 ? 'success' : ($kpis['accuracy_rate'] >= 90.0 ? 'warning' : 'danger');

        return [
            Stat::make('Network Gross Margin', $kpis['margin_percent'] . '%')
                ->description('Rs. ' . number_format($kpis['gross_margin'], 2) . ' profit margin')
                ->descriptionIcon('heroicon-m-chart-pie')
                ->color($marginColor),

            Stat::make('Top Performing Branch', $kpis['top_branch_name'])
                ->description('Rs. ' . number_format($kpis['top_branch_revenue'], 2) . ' gross revenue')
                ->descriptionIcon('heroicon-m-building-storefront')
                ->color('primary'),

            Stat::make('Cash Reconciliation Accuracy', $kpis['accuracy_rate'] . '%')
                ->description('Closed cashier shift balance rate')
                ->descriptionIcon('heroicon-m-check-badge')
                ->color($accuracyColor),

            Stat::make('Network Inventory Valuation', 'Rs. ' . number_format($kpis['network_inventory_valuation'], 2))
                ->description(number_format($kpis['network_inventory_units']) . ' active luxury units')
                ->descriptionIcon('heroicon-m-cube')
                ->color('success'),
        ];
    }
}
