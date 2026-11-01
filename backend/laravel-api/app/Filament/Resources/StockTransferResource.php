<?php

namespace App\Filament\Resources;

use App\Filament\Resources\StockTransferResource\Pages;
use App\Models\StockTransfer;
use App\Services\StockTransferService;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class StockTransferResource extends Resource
{
    protected static ?string $model = StockTransfer::class;

    protected static ?string $navigationIcon = 'heroicon-o-arrows-right-left';

    protected static ?string $navigationGroup = 'Catalog & Inventory';

    protected static ?string $navigationLabel = 'Stock Transfers';

    protected static ?int $navigationSort = 3;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Transfer Manifest')
                    ->columns(2)
                    ->schema([
                        Forms\Components\TextInput::make('transfer_number')
                            ->disabled()
                            ->required(),
                        Forms\Components\Select::make('status')
                            ->options([
                                'draft' => 'Draft',
                                'pending_approval' => 'Pending Approval',
                                'in_transit' => 'In Transit',
                                'received' => 'Received',
                                'cancelled' => 'Cancelled',
                            ])
                            ->required(),
                        Forms\Components\Select::make('source_store_id')
                            ->relationship('sourceStore', 'name')
                            ->required(),
                        Forms\Components\Select::make('destination_store_id')
                            ->relationship('destinationStore', 'name')
                            ->required(),
                        Forms\Components\Textarea::make('notes')
                            ->columnSpanFull(),
                    ]),

                Forms\Components\Section::make('Audit & Timestamps')
                    ->columns(3)
                    ->schema([
                        Forms\Components\Select::make('requested_by')
                            ->relationship('requestedBy', 'name')
                            ->disabled(),
                        Forms\Components\Select::make('approved_by')
                            ->relationship('approvedBy', 'name')
                            ->disabled(),
                        Forms\Components\Select::make('received_by')
                            ->relationship('receivedBy', 'name')
                            ->disabled(),
                        Forms\Components\DateTimePicker::make('dispatched_at')
                            ->disabled(),
                        Forms\Components\DateTimePicker::make('received_at')
                            ->disabled(),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('transfer_number')
                    ->searchable()
                    ->sortable()
                    ->weight('bold')
                    ->copyable(),
                Tables\Columns\TextColumn::make('sourceStore.name')
                    ->label('Source Outlet')
                    ->sortable()
                    ->searchable(),
                Tables\Columns\TextColumn::make('destinationStore.name')
                    ->label('Destination')
                    ->sortable()
                    ->searchable(),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'draft' => 'gray',
                        'pending_approval' => 'warning',
                        'in_transit' => 'info',
                        'received' => 'success',
                        'cancelled' => 'danger',
                        default => 'gray',
                    })
                    ->sortable(),
                Tables\Columns\TextColumn::make('items_count')
                    ->counts('items')
                    ->label('Items'),
                Tables\Columns\TextColumn::make('dispatched_at')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('received_at')
                    ->dateTime()
                    ->sortable(),
            ])
            ->defaultSort('created_at', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'draft' => 'Draft',
                        'pending_approval' => 'Pending Approval',
                        'in_transit' => 'In Transit',
                        'received' => 'Received',
                        'cancelled' => 'Cancelled',
                    ]),
                Tables\Filters\SelectFilter::make('sourceStore')
                    ->relationship('sourceStore', 'name'),
                Tables\Filters\SelectFilter::make('destinationStore')
                    ->relationship('destinationStore', 'name'),
            ])
            ->actions([
                // Quick Dispatch Action
                Tables\Actions\Action::make('dispatch')
                    ->label('Dispatch')
                    ->icon('heroicon-o-truck')
                    ->color('primary')
                    ->requiresConfirmation()
                    ->modalHeading('Dispatch Stock Transfer')
                    ->modalDescription('Deduct stock from the source store and place items in transit manifest.')
                    ->action(function (StockTransfer $record) {
                        try {
                            app(StockTransferService::class)->dispatchTransfer($record, auth()->user());

                            Notification::make()
                                ->title('Transfer Dispatched')
                                ->body("Transfer #{$record->transfer_number} is now in transit.")
                                ->success()
                                ->send();
                        } catch (\Exception $e) {
                            Notification::make()
                                ->title('Dispatch Failed')
                                ->body($e->getMessage())
                                ->danger()
                                ->send();
                        }
                    })
                    ->visible(fn (StockTransfer $record): bool => in_array($record->status, ['draft', 'pending_approval'])),

                // Quick Receive Action
                Tables\Actions\Action::make('receive')
                    ->label('Receive')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->requiresConfirmation()
                    ->modalHeading('Receive Stock Transfer')
                    ->modalDescription('Add in-transit items to destination store inventory.')
                    ->action(function (StockTransfer $record) {
                        try {
                            app(StockTransferService::class)->receiveTransfer($record, auth()->user());

                            Notification::make()
                                ->title('Transfer Received')
                                ->body("Transfer #{$record->transfer_number} received into destination stock.")
                                ->success()
                                ->send();
                        } catch (\Exception $e) {
                            Notification::make()
                                ->title('Receive Failed')
                                ->body($e->getMessage())
                                ->danger()
                                ->send();
                        }
                    })
                    ->visible(fn (StockTransfer $record): bool => $record->status === 'in_transit'),

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
            'index' => Pages\ListStockTransfers::route('/'),
            'edit' => Pages\EditStockTransfer::route('/{record}/edit'),
        ];
    }
}
