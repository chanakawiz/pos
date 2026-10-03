<?php

namespace App\Filament\Widgets;

use App\Models\Sale;
use Carbon\Carbon;
use Filament\Widgets\ChartWidget;

class SalesChartWidget extends ChartWidget
{
    protected static ?string $heading = 'Revenue Trend (Last 14 Days)';

    protected static ?int $sort = 2;

    protected int | string | array $columnSpan = 'full';

    protected function getData(): array
    {
        $dates = collect();
        $revenueData = collect();
        $transactionsData = collect();

        for ($i = 13; $i >= 0; $i--) {
            $date = Carbon::today()->subDays($i);
            $dates->push($date->format('M d'));

            $dayRevenue = (float) Sale::whereDate('sold_at', $date)->sum('total_amount');
            $dayCount = Sale::whereDate('sold_at', $date)->count();

            $revenueData->push($dayRevenue);
            $transactionsData->push($dayCount * 10); // Scaled for dual visibility
        }

        return [
            'datasets' => [
                [
                    'label'           => 'Gross Revenue ($)',
                    'data'            => $revenueData->toArray(),
                    'borderColor'     => '#10b981',
                    'backgroundColor' => 'rgba(16, 185, 129, 0.1)',
                    'fill'            => 'start',
                    'tension'         => 0.4,
                ],
                [
                    'label'           => 'Orders (Count x10)',
                    'data'            => $transactionsData->toArray(),
                    'borderColor'     => '#6366f1',
                    'backgroundColor' => 'rgba(99, 102, 241, 0.1)',
                    'tension'         => 0.4,
                ],
            ],
            'labels' => $dates->toArray(),
        ];
    }

    protected function getType(): string
    {
        return 'line';
    }
}
