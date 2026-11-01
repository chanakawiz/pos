<?php

namespace App\Filament\Widgets;

use App\Models\Inventory;
use App\Models\StockMovement;
use App\Models\Store;
use Carbon\Carbon;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;
use Illuminate\Support\Facades\DB;

class StockAgingVelocityWidget extends BaseWidget
{
    protected static ?string $heading = 'Stock Aging & Inter-Branch Transfer Velocity';

    protected static ?int $sort = 5;

    protected int | string | array $columnSpan = 'full';

    public function table(Table $table): Table
    {
        $flagship = Store::where('code', 'STORE-001')->first() ?? Store::first();

        return $table
            ->query(
                Inventory::query()
                    ->with(['product.category', 'store'])
                    ->where('quantity_on_hand', '>', 0)
                    ->orderBy('quantity_on_hand', 'desc')
            )
            ->columns([
                Tables\Columns\TextColumn::make('product.name')
                    ->label('Product')
                    ->weight('bold')
                    ->searchable(),
                Tables\Columns\TextColumn::make('product.sku')
                    ->label('SKU')
                    ->fontFamily('mono')
                    ->color('gray'),
                Tables\Columns\TextColumn::make('store.name')
                    ->label('Current Branch')
                    ->badge()
                    ->color('gray'),
                Tables\Columns\TextColumn::make('quantity_on_hand')
                    ->label('Stock Qty')
                    ->numeric(2)
                    ->weight('semibold')
                    ->alignEnd(),
                Tables\Columns\TextColumn::make('inventory_value')
                    ->label('Valuation (Rs.)')
                    ->state(fn (Inventory $record): float => (float) $record->quantity_on_hand * (float) ($record->product?->cost_price ?? 0))
                    ->formatStateUsing(fn ($state) => 'Rs. ' . number_format((float) $state, 2))
                    ->alignEnd(),
                Tables\Columns\TextColumn::make('days_inactive')
                    ->label('Aging')
                    ->state(function (Inventory $record): int {
                        $lastSold = DB::table('sale_items')
                            ->join('sales', 'sale_items.sale_id', '=', 'sales.id')
                            ->where('sales.store_id', $record->store_id)
                            ->where('sale_items.product_id', $record->product_id)
                            ->latest('sales.sold_at')
                            ->value('sales.sold_at');

                        $lastMovement = StockMovement::where('store_id', $record->store_id)
                            ->where('product_id', $record->product_id)
                            ->latest('created_at')
                            ->value('created_at');

                        $latest = $lastSold
                            ? Carbon::parse($lastSold)
                            : ($lastMovement ? Carbon::parse($lastMovement) : $record->updated_at);

                        return max(0, (int) $latest->diffInDays(now()));
                    })
                    ->formatStateUsing(fn ($state) => "{$state} days")
                    ->sortable()
                    ->alignCenter(),
                Tables\Columns\TextColumn::make('velocity_tier')
                    ->label('Turnover Status')
                    ->state(function (Inventory $record): string {
                        $lastSold = DB::table('sale_items')
                            ->join('sales', 'sale_items.sale_id', '=', 'sales.id')
                            ->where('sales.store_id', $record->store_id)
                            ->where('sale_items.product_id', $record->product_id)
                            ->latest('sales.sold_at')
                            ->value('sales.sold_at');

                        $lastMovement = StockMovement::where('store_id', $record->store_id)
                            ->where('product_id', $record->product_id)
                            ->latest('created_at')
                            ->value('created_at');

                        $latest = $lastSold
                            ? Carbon::parse($lastSold)
                            : ($lastMovement ? Carbon::parse($lastMovement) : $record->updated_at);

                        $days = max(0, (int) $latest->diffInDays(now()));

                        if ($days <= 14) return 'Fast Mover';
                        if ($days <= 30) return 'Steady';
                        if ($days <= 60) return 'Slow Moving';
                        return 'Stagnant';
                    })
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'Fast Mover' => 'success',
                        'Steady' => 'info',
                        'Slow Moving' => 'warning',
                        'Stagnant' => 'danger',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('transfer_advice')
                    ->label('Omnichannel Action')
                    ->state(function (Inventory $record) use ($flagship): string {
                        $lastSold = DB::table('sale_items')
                            ->join('sales', 'sale_items.sale_id', '=', 'sales.id')
                            ->where('sales.store_id', $record->store_id)
                            ->where('sale_items.product_id', $record->product_id)
                            ->latest('sales.sold_at')
                            ->value('sales.sold_at');

                        $lastMovement = StockMovement::where('store_id', $record->store_id)
                            ->where('product_id', $record->product_id)
                            ->latest('created_at')
                            ->value('created_at');

                        $latest = $lastSold
                            ? Carbon::parse($lastSold)
                            : ($lastMovement ? Carbon::parse($lastMovement) : $record->updated_at);

                        $days = max(0, (int) $latest->diffInDays(now()));

                        if ($days > 30 && $record->store_id !== $flagship?->id) {
                            return "Transfer to {$flagship->name}";
                        }
                        if ($days > 60) {
                            return 'VIP Markdown';
                        }
                        if ($days <= 14) {
                            return 'Optimal Stock';
                        }
                        return 'Monitor Sell-Through';
                    })
                    ->badge()
                    ->color(fn (string $state): string => match (true) {
                        str_contains($state, 'Transfer') => 'warning',
                        str_contains($state, 'Markdown') => 'danger',
                        str_contains($state, 'Optimal') => 'success',
                        default => 'gray',
                    }),
            ])
            ->actions([
                Tables\Actions\Action::make('transfer')
                    ->label('Transfer')
                    ->icon('heroicon-m-arrows-right-left')
                    ->color('primary')
                    ->url(fn (Inventory $record): string => '/admin/stock-transfers/create'),
            ])
            ->paginated([5, 10]);
    }
}
