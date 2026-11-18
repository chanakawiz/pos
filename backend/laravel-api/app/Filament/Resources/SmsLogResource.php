<?php

namespace App\Filament\Resources;

use App\Filament\Resources\SmsLogResource\Pages;
use App\Models\SmsLog;
use App\Services\SmsService;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class SmsLogResource extends Resource
{
    protected static ?string $model = SmsLog::class;

    protected static ?string $navigationIcon = 'heroicon-o-chat-bubble-bottom-center-text';

    protected static ?string $navigationGroup = 'Settings & System';

    protected static ?string $navigationLabel = 'SMS Delivery Logs';

    protected static ?int $navigationSort = 15;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('SMS Message & Dispatch Details')
                    ->schema([
                        Forms\Components\TextInput::make('recipient_phone')
                            ->label('Recipient Phone')
                            ->disabled(),
                        Forms\Components\TextInput::make('masked_phone')
                            ->label('Masked Display')
                            ->disabled(),
                        Forms\Components\TextInput::make('driver')
                            ->label('Gateway Driver')
                            ->disabled(),
                        Forms\Components\TextInput::make('status')
                            ->label('Status')
                            ->disabled(),
                        Forms\Components\TextInput::make('event_type')
                            ->label('Event Trigger')
                            ->disabled(),
                        Forms\Components\TextInput::make('gateway_reference')
                            ->label('Gateway Reference')
                            ->disabled(),
                        Forms\Components\TextInput::make('cost')
                            ->label('Estimated Cost')
                            ->prefix('Rs.')
                            ->disabled(),
                        Forms\Components\DateTimePicker::make('sent_at')
                            ->label('Dispatched At')
                            ->disabled(),
                        Forms\Components\Textarea::make('message')
                            ->label('Message Content')
                            ->rows(4)
                            ->columnSpanFull()
                            ->disabled(),
                        Forms\Components\Textarea::make('error_message')
                            ->label('Gateway Error (if failed)')
                            ->columnSpanFull()
                            ->visible(fn (?SmsLog $record) => !empty($record?->error_message))
                            ->disabled(),
                        Forms\Components\KeyValue::make('metadata')
                            ->label('Context Metadata')
                            ->columnSpanFull()
                            ->disabled(),
                    ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Timestamp')
                    ->dateTime('M j, Y • H:i:s')
                    ->sortable(),

                Tables\Columns\TextColumn::make('masked_phone')
                    ->label('Recipient')
                    ->searchable(['recipient_phone', 'masked_phone'])
                    ->weight('bold')
                    ->copyable()
                    ->copyMessage('Phone number copied'),

                Tables\Columns\TextColumn::make('event_type')
                    ->label('Event')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'pos_receipt' => 'POS E-Receipt',
                        'web_order' => 'Web Store Order',
                        'order_dispatched' => 'Courier Dispatch',
                        'order_delivered' => 'Delivered',
                        'vip_upgrade' => 'VIP Tier Upgrade',
                        'rma_update' => 'RMA Concierge',
                        default => ucfirst(str_replace('_', ' ', $state)),
                    })
                    ->colors([
                        'info' => 'pos_receipt',
                        'primary' => 'web_order',
                        'warning' => 'order_dispatched',
                        'success' => fn ($state) => in_array($state, ['vip_upgrade', 'order_delivered']),
                        'gray' => 'custom',
                    ]),

                Tables\Columns\TextColumn::make('driver')
                    ->label('Driver')
                    ->badge()
                    ->colors([
                        'success' => 'notify_lk',
                        'primary' => 'twilio',
                        'info' => 'dialog_esms',
                        'gray' => fn ($state) => in_array($state, ['log', 'mock']),
                    ]),

                Tables\Columns\TextColumn::make('status')
                    ->label('Status')
                    ->badge()
                    ->colors([
                        'success' => 'sent',
                        'danger' => 'failed',
                        'warning' => 'queued',
                        'info' => 'delivered',
                    ]),

                Tables\Columns\TextColumn::make('sale.invoice_number')
                    ->label('Invoice')
                    ->placeholder('—')
                    ->searchable(),

                Tables\Columns\TextColumn::make('store.name')
                    ->label('Store')
                    ->placeholder('OmniLuxe Central')
                    ->limit(20),

                Tables\Columns\TextColumn::make('gateway_reference')
                    ->label('Gateway Ref')
                    ->limit(15)
                    ->placeholder('—')
                    ->toggleable(isToggledHiddenByDefault: true),

                Tables\Columns\TextColumn::make('cost')
                    ->label('Cost')
                    ->money('LKR')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->defaultSort('created_at', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'sent' => 'Sent / Delivered',
                        'failed' => 'Failed',
                        'queued' => 'Queued',
                    ]),
                Tables\Filters\SelectFilter::make('event_type')
                    ->options([
                        'pos_receipt' => 'POS E-Receipt',
                        'web_order' => 'Web Store Order',
                        'order_dispatched' => 'Courier Dispatch',
                        'vip_upgrade' => 'VIP Upgrade',
                    ]),
                Tables\Filters\SelectFilter::make('driver')
                    ->options([
                        'notify_lk' => 'Notify.lk',
                        'twilio' => 'Twilio',
                        'dialog_esms' => 'Dialog eSMS',
                        'log' => 'Log (Development)',
                        'mock' => 'Mock (Test)',
                    ]),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\Action::make('resend')
                    ->label('Resend')
                    ->icon('heroicon-o-arrow-path')
                    ->color('warning')
                    ->requiresConfirmation()
                    ->modalHeading('Resend SMS Message')
                    ->modalDescription('Are you sure you want to re-dispatch this SMS to the recipient via the configured gateway?')
                    ->action(function (SmsLog $record, SmsService $smsService) {
                        $newLog = $smsService->dispatch(
                            $record->recipient_phone,
                            $record->message,
                            $record->event_type,
                            [
                                'store_id' => $record->store_id,
                                'customer_id' => $record->customer_id,
                                'sale_id' => $record->sale_id,
                                'driver' => $record->driver,
                            ]
                        );

                        if ($newLog->status === 'sent') {
                            Notification::make()
                                ->title('SMS Resent Successfully')
                                ->body("Dispatched to {$record->masked_phone} (Ref: {$newLog->gateway_reference})")
                                ->success()
                                ->send();
                        } else {
                            Notification::make()
                                ->title('SMS Resend Failed')
                                ->body($newLog->error_message ?: 'Gateway returned an error')
                                ->danger()
                                ->send();
                        }
                    }),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListSmsLogs::route('/'),
            'view' => Pages\ViewSmsLog::route('/{record}'),
        ];
    }
}
