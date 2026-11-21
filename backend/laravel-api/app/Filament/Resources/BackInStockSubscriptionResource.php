<?php

namespace App\Filament\Resources;

use App\Filament\Resources\BackInStockSubscriptionResource\Pages;
use App\Models\BackInStockSubscription;
use App\Services\BackInStockService;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class BackInStockSubscriptionResource extends Resource
{
    protected static ?string $model = BackInStockSubscription::class;

    protected static ?string $navigationIcon = 'heroicon-o-bell-alert';

    protected static ?string $navigationGroup = 'Catalog & Inventory';

    protected static ?string $navigationLabel = 'Back-in-Stock Alerts';

    protected static ?int $navigationSort = 7;

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('product.name')
                    ->label('Product')
                    ->searchable()
                    ->weight('bold'),
                Tables\Columns\TextColumn::make('customer_name')
                    ->label('Client')
                    ->searchable()
                    ->default('OmniLuxe Guest'),
                Tables\Columns\TextColumn::make('phone')
                    ->label('Mobile (SMS)')
                    ->placeholder('—'),
                Tables\Columns\TextColumn::make('email')
                    ->label('Email')
                    ->placeholder('—'),
                Tables\Columns\TextColumn::make('store.name')
                    ->label('Preferred Boutique')
                    ->default('Any Boutique'),
                Tables\Columns\BadgeColumn::make('status')
                    ->colors([
                        'warning' => 'subscribed',
                        'success' => 'notified',
                        'danger' => 'cancelled',
                    ]),
                Tables\Columns\TextColumn::make('notified_at')
                    ->label('Alerted At')
                    ->dateTime('M d, H:i')
                    ->placeholder('Awaiting Restock'),
            ])
            ->defaultSort('created_at', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'subscribed' => 'Waiting (Subscribed)',
                        'notified' => 'Notified',
                        'cancelled' => 'Cancelled',
                    ]),
            ])
            ->actions([
                Tables\Actions\Action::make('dispatch_now')
                    ->label('Send Restock Alert')
                    ->icon('heroicon-o-paper-airplane')
                    ->color('success')
                    ->visible(fn (BackInStockSubscription $record) => $record->status === 'subscribed')
                    ->requiresConfirmation()
                    ->action(function (BackInStockSubscription $record) {
                        $count = app(BackInStockService::class)
                            ->notifySubscribersOnRestock($record->product, $record->store);
                        Notification::make()
                            ->title("Dispatched {$count} restock alert(s) for {$record->product->name}")
                            ->success()
                            ->send();
                    }),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListBackInStockSubscriptions::route('/'),
        ];
    }
}
