<?php

namespace App\Filament\Pages;

use App\Filament\Widgets\BranchPerformanceChartWidget;
use App\Filament\Widgets\BranchPerformanceStatsWidget;
use App\Filament\Widgets\CashierVelocityWidget;
use App\Filament\Widgets\StockAgingVelocityWidget;
use Filament\Pages\Page;

class BranchPerformance extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-presentation-chart-line';

    protected static ?string $navigationGroup = 'Analytics & Reports';

    protected static ?string $navigationLabel = 'Branch Analytics';

    protected static ?string $title = 'Multi-Branch Performance & Inventory Health';

    protected static ?int $navigationSort = 1;

    protected static string $view = 'filament.pages.branch-performance';

    protected function getHeaderWidgets(): array
    {
        return [
            BranchPerformanceStatsWidget::class,
            BranchPerformanceChartWidget::class,
            CashierVelocityWidget::class,
            StockAgingVelocityWidget::class,
        ];
    }
}
