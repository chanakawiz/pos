<?php

namespace App\Filament\Resources;

use App\Filament\Resources\SaleResource\Pages;
use App\Models\Sale;
use App\Services\OrderTrackingService;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class SaleResource extends Resource
{
    protected static ?string $model = Sale::class;

    protected static ?string $navigationIcon = 'heroicon-o-shopping-bag';

    protected static ?string $navigationGroup = 'Sales & Fulfillment';

    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Order Identification')
                    ->columns(2)
                    ->schema([
                        Forms\Components\TextInput::make('invoice_number')
                            ->required()
                            ->maxLength(100),
                        Forms\Components\Select::make('store_id')
                            ->relationship('store', 'name')
                            ->required(),
                        Forms\Components\Select::make('customer_id')
                            ->relationship('customer', 'name'),
                        Forms\Components\Select::make('cashier_id')
                            ->relationship('cashier', 'name')
                            ->required(),
                    ]),

                Forms\Components\Section::make('Fulfillment & Telemetry')
                    ->columns(3)
                    ->schema([
                        Forms\Components\Select::make('fulfillment_status')
                            ->options([
                                'unfulfilled' => 'Unfulfilled',
                                'processing' => 'Processing',
                                'packed' => 'Packed',
                                'dispatched' => 'Dispatched',
                                'delivered' => 'Delivered',
                                'returned' => 'Returned',
                            ])
                            ->required()
                            ->default('unfulfilled'),
                        Forms\Components\TextInput::make('courier_name')
                            ->placeholder('e.g. Prompt Express, Domex, DHL')
                            ->maxLength(100),
                        Forms\Components\TextInput::make('tracking_number')
                            ->placeholder('e.g. PRM-99881')
                            ->maxLength(100),
                        Forms\Components\DateTimePicker::make('estimated_delivery_at'),
                        Forms\Components\DateTimePicker::make('dispatched_at'),
                        Forms\Components\DateTimePicker::make('delivered_at'),
                    ]),

                Forms\Components\Section::make('Financials & Status')
                    ->columns(3)
                    ->schema([
                        Forms\Components\TextInput::make('subtotal')
                            ->required()
                            ->numeric()
                            ->default(0.00),
                        Forms\Components\TextInput::make('discount_amount')
                            ->required()
                            ->numeric()
                            ->default(0.00),
                        Forms\Components\TextInput::make('tax_amount')
                            ->required()
                            ->numeric()
                            ->default(0.00),
                        Forms\Components\TextInput::make('total_amount')
                            ->required()
                            ->numeric()
                            ->default(0.00),
                        Forms\Components\Select::make('payment_status')
                            ->options([
                                'unpaid' => 'Unpaid',
                                'partial' => 'Partial',
                                'paid' => 'Paid',
                                'refunded' => 'Refunded',
                            ])
                            ->required(),
                        Forms\Components\Select::make('sale_status')
                            ->options([
                                'completed' => 'Completed',
                                'cancelled' => 'Cancelled',
                                'held' => 'Held',
                            ])
                            ->required(),
                        Forms\Components\DateTimePicker::make('sold_at')
                            ->required(),
                    ]),

                Forms\Components\Textarea::make('notes')
                    ->columnSpanFull(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('invoice_number')
                    ->searchable()
                    ->sortable()
                    ->weight('bold')
                    ->copyable(),
                Tables\Columns\TextColumn::make('customer.name')
                    ->searchable()
                    ->sortable()
                    ->default('Walk-in Customer'),
                Tables\Columns\TextColumn::make('total_amount')
                    ->numeric(decimalPlaces: 2)
                    ->prefix('Rs. ')
                    ->sortable()
                    ->weight('bold'),
                Tables\Columns\TextColumn::make('payment_status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'paid' => 'success',
                        'partial' => 'warning',
                        'refunded' => 'danger',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('fulfillment_status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'delivered' => 'success',
                        'dispatched' => 'primary',
                        'packed' => 'info',
                        'processing' => 'warning',
                        'returned' => 'danger',
                        default => 'gray',
                    })
                    ->sortable(),
                Tables\Columns\TextColumn::make('courier_name')
                    ->toggleable(isToggledHiddenByDefault: false)
                    ->searchable(),
                Tables\Columns\TextColumn::make('tracking_number')
                    ->toggleable(isToggledHiddenByDefault: false)
                    ->searchable()
                    ->copyable(),
                Tables\Columns\TextColumn::make('store.name')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('sold_at')
                    ->dateTime()
                    ->sortable(),
            ])
            ->defaultSort('created_at', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('fulfillment_status')
                    ->options([
                        'unfulfilled' => 'Unfulfilled',
                        'processing' => 'Processing',
                        'packed' => 'Packed',
                        'dispatched' => 'Dispatched',
                        'delivered' => 'Delivered',
                        'returned' => 'Returned',
                    ]),
                Tables\Filters\SelectFilter::make('payment_status')
                    ->options([
                        'unpaid' => 'Unpaid',
                        'partial' => 'Partial',
                        'paid' => 'Paid',
                        'refunded' => 'Refunded',
                    ]),
                Tables\Filters\SelectFilter::make('store')
                    ->relationship('store', 'name'),
            ])
            ->actions([
                // Quick Dispatch Action
                Tables\Actions\Action::make('dispatch')
                    ->label('Dispatch')
                    ->icon('heroicon-o-truck')
                    ->color('primary')
                    ->modalHeading('Dispatch Order with Courier')
                    ->modalDescription('Assign tracking details and notify the customer immediately.')
                    ->form([
                        Forms\Components\TextInput::make('courier_name')
                            ->label('Courier Service')
                            ->required()
                            ->default('Prompt Express')
                            ->maxLength(100),
                        Forms\Components\TextInput::make('tracking_number')
                            ->label('Tracking Number')
                            ->required()
                            ->maxLength(100),
                        Forms\Components\DatePicker::make('estimated_delivery_at')
                            ->label('Estimated Delivery Date')
                            ->default(now()->addDays(2)),
                    ])
                    ->action(function (Sale $record, array $data) {
                        app(OrderTrackingService::class)->updateFulfillment(
                            $record,
                            'dispatched',
                            $data['tracking_number'],
                            $data['courier_name'],
                            $data['estimated_delivery_at'] ?? null
                        );

                        Notification::make()
                            ->title('Order Dispatched')
                            ->body("Order #{$record->invoice_number} dispatched via {$data['courier_name']}.")
                            ->success()
                            ->send();
                    })
                    ->visible(fn (Sale $record): bool => in_array($record->fulfillment_status, ['unfulfilled', 'processing', 'packed'])),

                // Mark Delivered Action
                Tables\Actions\Action::make('mark_delivered')
                    ->label('Delivered')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->requiresConfirmation()
                    ->modalHeading('Confirm Order Delivery')
                    ->modalDescription('Mark this order as delivered to recipient and notify customer.')
                    ->action(function (Sale $record) {
                        app(OrderTrackingService::class)->updateFulfillment($record, 'delivered');

                        Notification::make()
                            ->title('Order Delivered')
                            ->body("Order #{$record->invoice_number} marked as delivered.")
                            ->success()
                            ->send();
                    })
                    ->visible(fn (Sale $record): bool => $record->fulfillment_status === 'dispatched'),

                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListSales::route('/'),
            'create' => Pages\CreateSale::route('/create'),
            'edit' => Pages\EditSale::route('/{record}/edit'),
        ];
    }
}
