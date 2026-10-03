<?php

namespace App\Filament\Resources;

use App\Filament\Resources\InventoryResource\Pages;
use App\Models\Inventory;
use App\Models\StockMovement;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class InventoryResource extends Resource
{
    protected static ?string $model = Inventory::class;

    protected static ?string $navigationIcon = 'heroicon-o-archive-box';

    protected static ?string $navigationGroup = 'Inventory & Catalog';

    protected static ?int $navigationSort = 2;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Select::make('store_id')
                    ->label('Store Branch')
                    ->relationship('store', 'name')
                    ->required()
                    ->searchable()
                    ->preload(),

                Forms\Components\Select::make('product_id')
                    ->label('Product')
                    ->relationship('product', 'name')
                    ->required()
                    ->searchable()
                    ->preload(),

                Forms\Components\TextInput::make('quantity_on_hand')
                    ->label('Quantity On Hand')
                    ->required()
                    ->numeric()
                    ->default(0.00),

                Forms\Components\TextInput::make('quantity_reserved')
                    ->label('Quantity Reserved (Cart Holds)')
                    ->numeric()
                    ->default(0.00),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('store.name')
                    ->label('Store')
                    ->sortable()
                    ->searchable(),

                Tables\Columns\TextColumn::make('product.name')
                    ->label('Product (English / Sinhala)')
                    ->description(fn (Inventory $record) => $record->product?->sinhala_name)
                    ->sortable()
                    ->searchable()
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('product.sku')
                    ->label('SKU')
                    ->fontFamily('mono')
                    ->searchable(),

                Tables\Columns\TextColumn::make('product.barcode')
                    ->label('Barcode')
                    ->fontFamily('mono')
                    ->searchable(),

                Tables\Columns\TextColumn::make('quantity_on_hand')
                    ->label('Available Stock')
                    ->numeric(2)
                    ->color(fn ($state, $record) => $state <= ($record->product?->min_stock_level ?? 5) ? 'danger' : 'success')
                    ->weight('bold')
                    ->sortable(),

                Tables\Columns\TextColumn::make('quantity_reserved')
                    ->label('Reserved')
                    ->numeric(2)
                    ->sortable(),

                Tables\Columns\TextColumn::make('product.selling_price')
                    ->label('Selling Price')
                    ->money('USD'),

                Tables\Columns\TextColumn::make('updated_at')
                    ->label('Last Updated')
                    ->dateTime()
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('store')
                    ->relationship('store', 'name'),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index'  => Pages\ListInventories::route('/'),
            'create' => Pages\CreateInventory::route('/create'),
            'edit'   => Pages\EditInventory::route('/{record}/edit'),
        ];
    }
}
