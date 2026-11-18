<?php

namespace App\Filament\Resources\EodReportResource\Pages;

use App\Filament\Resources\EodReportResource;
use App\Models\Store;
use App\Services\EodCloseoutService;
use Filament\Actions;
use Filament\Forms;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\ListRecords;

class ListEodReports extends ListRecords
{
    protected static string $resource = EodReportResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\Action::make('run_eod_closeout')
                ->label('Run EOD Reconciliation')
                ->icon('heroicon-o-arrow-path-rounded-square')
                ->color('primary')
                ->form([
                    Forms\Components\Select::make('store_id')
                        ->label('Store Location')
                        ->options(Store::where('is_active', true)->pluck('name', 'id'))
                        ->default(Store::value('id'))
                        ->required(),
                    Forms\Components\Toggle::make('force')
                        ->label('Force Close All Open Registers')
                        ->default(true),
                    Forms\Components\Toggle::make('notify_sms')
                        ->label('Send Executive SMS Digest to Store Manager')
                        ->default(true),
                    Forms\Components\Textarea::make('notes')
                        ->label('Audit Notes')
                        ->placeholder('e.g. Verified by Store Manager at shift end.'),
                ])
                ->action(function (array $data, EodCloseoutService $service) {
                    $store = Store::findOrFail($data['store_id']);
                    $report = $service->performCloseout($store, [
                        'force' => (bool) $data['force'],
                        'notify_sms' => (bool) $data['notify_sms'],
                        'notes' => $data['notes'] ?? 'Manual EOD Reconciliation via Filament ERP',
                        'user_id' => auth()->id(),
                        'is_automated' => false,
                    ]);

                    Notification::make()
                        ->title("EOD Closeout Finalized for {$store->name}")
                        ->body("Closed {$report->closed_sessions_count} registers. Net Sales: LKR " . number_format($report->net_sales, 2))
                        ->success()
                        ->send();
                }),
        ];
    }
}
