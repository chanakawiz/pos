<?php

namespace App\Filament\Widgets;

use App\Models\Inventory;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\DB;

class LowStockWidget extends BaseWidget
{
    protected static ?string $heading = 'Critical Low Stock Alerts';

    protected static ?int $sort = 3;

    protected int | string | array $columnSpan = 'full';

    public function table(Table $table): Table
    {
        return $table
            ->query(
                Inventory::query()
                    ->with(['product.category', 'store'])
                    ->whereColumn(
                        'quantity_on_hand',
                        '<=',
                        DB::raw('(SELECT min_stock_level FROM products WHERE products.id = inventory.product_id)')
                    )
                    ->orderBy('quantity_on_hand', 'asc')
            )
            ->columns([
                Tables\Columns\TextColumn::make('product.name')
                    ->label('Product')
                    ->weight('bold')
                    ->searchable(),
                Tables\Columns\TextColumn::make('product.sku')
                    ->label('SKU')
                    ->fontFamily('mono'),
                Tables\Columns\TextColumn::make('product.category.name')
                    ->label('Category')
                    ->badge(),
                Tables\Columns\TextColumn::make('store.name')
                    ->label('Store Branch'),
                Tables\Columns\TextColumn::make('quantity_on_hand')
                    ->label('Current Stock')
                    ->numeric(2)
                    ->color(fn ($state) => $state <= 0 ? 'danger' : 'warning')
                    ->weight('bold'),
                Tables\Columns\TextColumn::make('product.min_stock_level')
                    ->label('Safety Level')
                    ->numeric(),
            ])
            ->paginated([5, 10]);
    }
}
