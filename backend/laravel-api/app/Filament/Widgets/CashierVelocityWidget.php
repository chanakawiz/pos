<?php

namespace App\Filament\Widgets;

use App\Models\User;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;
use Illuminate\Database\Eloquent\Builder;

class CashierVelocityWidget extends BaseWidget
{
    protected static ?string $heading = 'Cashier Sales Velocity & Drawer Reconciliation Accuracy';

    protected static ?int $sort = 4;

    protected int | string | array $columnSpan = 'full';

    public function table(Table $table): Table
    {
        return $table
            ->query(
                User::query()
                    ->whereIn('role', ['cashier', 'manager', 'admin'])
                    ->with(['store'])
                    ->withCount([
                        'sales' => fn (Builder $q) => $q->where('sale_status', 'completed'),
                        'cashSessions',
                    ])
                    ->withSum([
                        'sales' => fn (Builder $q) => $q->where('sale_status', 'completed'),
                    ], 'total_amount')
                    ->withSum('cashSessions', 'discrepancy')
                    ->orderByDesc('sales_sum_total_amount')
            )
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->label('Staff Member')
                    ->weight('bold')
                    ->searchable(),
                Tables\Columns\TextColumn::make('store.name')
                    ->label('Assigned Branch')
                    ->badge()
                    ->color('gray'),
                Tables\Columns\TextColumn::make('role')
                    ->label('Role')
                    ->formatStateUsing(fn (string $state): string => ucfirst(str_replace('_', ' ', $state)))
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'cashier' => 'info',
                        'manager' => 'warning',
                        'admin', 'super_admin' => 'success',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('sales_count')
                    ->label('Bills Finalized')
                    ->numeric()
                    ->sortable()
                    ->alignEnd(),
                Tables\Columns\TextColumn::make('sales_sum_total_amount')
                    ->label('Total Revenue Handled')
                    ->formatStateUsing(fn ($state) => 'Rs. ' . number_format((float) ($state ?? 0), 2))
                    ->sortable()
                    ->weight('bold')
                    ->alignEnd(),
                Tables\Columns\TextColumn::make('cash_sessions_count')
                    ->label('Shift Registers')
                    ->numeric()
                    ->alignCenter(),
                Tables\Columns\TextColumn::make('cash_sessions_sum_discrepancy')
                    ->label('Drawer Discrepancy')
                    ->formatStateUsing(function ($state) {
                        $val = (float) ($state ?? 0);
                        if ($val == 0) {
                            return 'Rs. 0.00 (Balanced)';
                        }
                        $prefix = $val > 0 ? '+Rs. ' : '-Rs. ';
                        return $prefix . number_format(abs($val), 2);
                    })
                    ->color(function ($state) {
                        $val = (float) ($state ?? 0);
                        if ($val == 0) return 'success';
                        if (abs($val) <= 1000) return 'warning';
                        return 'danger';
                    })
                    ->weight('semibold')
                    ->alignEnd(),
                Tables\Columns\TextColumn::make('audit_status')
                    ->label('Integrity Health')
                    ->state(function (User $record): string {
                        $discrepancy = abs((float) ($record->cash_sessions_sum_discrepancy ?? 0));
                        $sessions = (int) ($record->cash_sessions_count ?? 0);
                        if ($sessions === 0) return 'No Shifts';
                        if ($discrepancy == 0) return '100% Balanced';
                        if ($discrepancy <= 1000) return 'Minor Variance';
                        return 'Audit Required';
                    })
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        '100% Balanced' => 'success',
                        'Minor Variance' => 'warning',
                        'Audit Required' => 'danger',
                        default => 'gray',
                    }),
            ])
            ->paginated([5, 10]);
    }
}
