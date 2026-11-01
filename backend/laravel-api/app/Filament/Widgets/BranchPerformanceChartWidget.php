<?php

namespace App\Filament\Widgets;

use App\Services\BranchAnalyticsService;
use Filament\Widgets\ChartWidget;

class BranchPerformanceChartWidget extends ChartWidget
{
    protected static ?string $heading = 'Multi-Branch Revenue & Gross Margin Comparison';

    protected static ?int $sort = 2;

    protected int | string | array $columnSpan = 1;

    protected function getData(): array
    {
        /** @var BranchAnalyticsService $analytics */
        $analytics = app(BranchAnalyticsService::class);
        $summary = $analytics->getBranchPerformanceSummary();

        $labels = [];
        $revenues = [];
        $grossMargins = [];
        $cogs = [];

        foreach ($summary as $branch) {
            $labels[] = $branch['store_name'];
            $revenues[] = $branch['revenue'];
            $grossMargins[] = $branch['gross_margin'];
            $cogs[] = $branch['cogs'];
        }

        return [
            'datasets' => [
                [
                    'label' => 'Gross Revenue (Rs.)',
                    'data' => $revenues,
                    'backgroundColor' => '#233C32', // Forest Green
                    'borderRadius' => 6,
                ],
                [
                    'label' => 'Gross Margin (Rs.)',
                    'data' => $grossMargins,
                    'backgroundColor' => '#C29B38', // Champagne Gold
                    'borderRadius' => 6,
                ],
                [
                    'label' => 'Cost of Goods Sold (Rs.)',
                    'data' => $cogs,
                    'backgroundColor' => '#A3A899', // Sage Muted
                    'borderRadius' => 6,
                ],
            ],
            'labels' => $labels,
        ];
    }

    protected function getType(): string
    {
        return 'bar';
    }
}
