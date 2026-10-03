<?php

namespace App\Filament\Resources;

use App\Filament\Resources\StockMovementResource\Pages;
use App\Models\StockMovement;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class StockMovementResource extends Resource
{
    protected static ?string $model = StockMovement::class;

    protected static ?string $navigationIcon = 'heroicon-o-arrows-right-left';

    protected static ?string $navigationGroup = 'Inventory & Catalog';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Select::make('store_id')
                    ->relationship('store', 'name')
                    ->disabled(),
                Forms\Components\Select::make('product_id')
                    ->relationship('product', 'name')
                    ->disabled(),
                Forms\Components\TextInput::make('type')
                    ->disabled(),
                Forms\Components\TextInput::make('quantity')
                    ->disabled(),
                Forms\Components\TextInput::make('before_quantity')
                    ->disabled(),
                Forms\Components\TextInput::make('after_quantity')
                    ->disabled(),
                Forms\Components\TextInput::make('reference_uuid')
                    ->disabled(),
                Forms\Components\Textarea::make('notes')
                    ->disabled()
                    ->columnSpanFull(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Timestamp')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('product.name')
                    ->searchable()
                    ->sortable()
                    ->weight('bold'),
                Tables\Columns\TextColumn::make('store.name')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\BadgeColumn::make('type')
                    ->colors([
                        'success' => fn ($state): bool => in_array($state, ['purchase', 'transfer_in', 'refund']),
                        'danger'  => fn ($state): bool => in_array($state, ['sale', 'damaged', 'transfer_out']),
                        'warning' => 'adjustment',
                    ]),
                Tables\Columns\TextColumn::make('quantity')
                    ->numeric(2)
                    ->color(fn ($record) => in_array($record->type, ['sale', 'damaged', 'transfer_out']) ? 'danger' : 'success')
                    ->sortable(),
                Tables\Columns\TextColumn::make('before_quantity')
                    ->numeric(2),
                Tables\Columns\TextColumn::make('after_quantity')
                    ->numeric(2),
                Tables\Columns\TextColumn::make('reference_uuid')
                    ->label('Ref / Transaction')
                    ->limit(12)
                    ->fontFamily('mono')
                    ->searchable(),
                Tables\Columns\TextColumn::make('user.name')
                    ->label('User')
                    ->searchable(),
            ])
            ->defaultSort('created_at', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('type')
                    ->options([
                        'sale'         => 'Sale',
                        'refund'       => 'Refund',
                        'purchase'     => 'Purchase',
                        'adjustment'   => 'Adjustment',
                        'transfer_in'  => 'Transfer In',
                        'transfer_out' => 'Transfer Out',
                        'damaged'      => 'Damaged',
                    ]),
                Tables\Filters\SelectFilter::make('store')
                    ->relationship('store', 'name'),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
            ])
            ->bulkActions([]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListStockMovements::route('/'),
        ];
    }
}
