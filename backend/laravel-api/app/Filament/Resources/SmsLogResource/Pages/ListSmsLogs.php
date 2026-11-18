<?php

namespace App\Filament\Resources\SmsLogResource\Pages;

use App\Filament\Resources\SmsLogResource;
use App\Services\SmsService;
use Filament\Actions;
use Filament\Forms;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\ListRecords;

class ListSmsLogs extends ListRecords
{
    protected static string $resource = SmsLogResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\Action::make('sendTestSms')
                ->label('Test Gateway Dispatch')
                ->icon('heroicon-o-paper-airplane')
                ->color('primary')
                ->form([
                    Forms\Components\TextInput::make('phone')
                        ->label('Recipient Phone (E.g. 0771234567 or +94771234567)')
                        ->required(),
                    Forms\Components\Select::make('driver')
                        ->label('SMS Driver')
                        ->options([
                            'notify_lk' => 'Notify.lk (Sri Lanka)',
                            'twilio' => 'Twilio (International)',
                            'dialog_esms' => 'Dialog Axiata eSMS',
                            'log' => 'Log (Local debug)',
                            'mock' => 'Mock (Simulation)',
                        ])
                        ->default(config('sms.default', 'log'))
                        ->required(),
                    Forms\Components\Textarea::make('message')
                        ->label('Test Message')
                        ->default('OmniLuxe Store: Omnichannel SMS Gateway test message. System connectivity verified 100%.')
                        ->required(),
                ])
                ->action(function (array $data, SmsService $smsService) {
                    $log = $smsService->dispatch(
                        $data['phone'],
                        $data['message'],
                        'test',
                        ['driver' => $data['driver']]
                    );

                    if ($log->status === 'sent') {
                        Notification::make()
                            ->title('Test SMS Dispatched')
                            ->body("Successfully dispatched via [{$log->driver}] to {$log->masked_phone}. Ref: {$log->gateway_reference}")
                            ->success()
                            ->send();
                    } else {
                        Notification::make()
                            ->title('Test SMS Failed')
                            ->body("Gateway error: {$log->error_message}")
                            ->danger()
                            ->send();
                    }
                }),
        ];
    }
}
