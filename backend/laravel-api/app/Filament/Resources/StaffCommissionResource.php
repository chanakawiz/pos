<?php

namespace App\Filament\Resources;

use App\Filament\Resources\StaffCommissionResource\Pages;
use App\Models\StaffCommission;
use App\Services\CommissionService;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class StaffCommissionResource extends Resource
{
    protected static ?string $model = StaffCommission::class;

    protected static ?string $navigationIcon = 'heroicon-o-trophy';

    protected static ?string $navigationGroup = 'Analytics & Reports';

    protected static ?string $navigationLabel = 'Staff Commissions';

    protected static ?int $navigationSort = 5;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Associate Commission Entry')
                    ->columns(2)
                    ->schema([
                        Forms\Components\Select::make('user_id')
                            ->label('Associate')
                            ->relationship('user', 'name')
                            ->disabled(),
                        Forms\Components\Select::make('store_id')
                            ->label('Boutique')
                            ->relationship('store', 'name')
                            ->disabled(),
                        Forms\Components\TextInput::make('sale_amount')
                            ->prefix('Rs.')
                            ->numeric()
                            ->disabled(),
                        Forms\Components\TextInput::make('commission_rate')
                            ->suffix('%')
                            ->numeric()
                            ->disabled(),
                        Forms\Components\TextInput::make('commission_amount')
                            ->prefix('Rs.')
                            ->numeric()
                            ->required(),
                        Forms\Components\Select::make('status')
                            ->options([
                                'pending' => 'Pending Review',
                                'approved' => 'Approved',
                                'paid' => 'Paid Out',
                                'reversed' => 'Reversed (Refunded)',
                            ])
                            ->required(),
                        Forms\Components\Textarea::make('notes')->columnSpanFull(),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('user.name')
                    ->label('Associate')
                    ->searchable()
                    ->weight('bold'),
                Tables\Columns\TextColumn::make('store.name')
                    ->label('Boutique')
                    ->sortable(),
                Tables\Columns\TextColumn::make('sale.invoice_number')
                    ->label('Invoice #')
                    ->fontFamily('mono')
                    ->default('—')
                    ->searchable(),
                Tables\Columns\TextColumn::make('sale_amount')
                    ->label('Sale Value')
                    ->money('LKR')
                    ->sortable(),
                Tables\Columns\TextColumn::make('commission_rate')
                    ->label('Rate')
                    ->suffix('%'),
                Tables\Columns\TextColumn::make('commission_amount')
                    ->label('Earned')
                    ->money('LKR')
                    ->weight('bold')
                    ->color('success')
                    ->sortable(),
                Tables\Columns\BadgeColumn::make('status')
                    ->colors([
                        'warning' => 'pending',
                        'info' => 'approved',
                        'success' => 'paid',
                        'danger' => 'reversed',
                    ]),
                Tables\Columns\TextColumn::make('earned_at')
                    ->label('Earned At')
                    ->dateTime('M d, H:i')
                    ->sortable(),
            ])
            ->defaultSort('earned_at', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'pending' => 'Pending',
                        'approved' => 'Approved',
                        'paid' => 'Paid',
                        'reversed' => 'Reversed',
                    ]),
            ])
            ->actions([
                Tables\Actions\Action::make('mark_paid')
                    ->label('Approve & Pay')
                    ->icon('heroicon-o-banknotes')
                    ->color('success')
                    ->visible(fn (StaffCommission $record) => in_array($record->status, ['pending', 'approved'], true))
                    ->requiresConfirmation()
                    ->action(function (StaffCommission $record) {
                        app(CommissionService::class)->markPaid($record);
                        Notification::make()
                            ->title("Commission settled for {$record->user?->name}")
                            ->success()
                            ->send();
                    }),
                Tables\Actions\EditAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListStaffCommissions::route('/'),
            'edit' => Pages\EditStaffCommission::route('/{record}/edit'),
        ];
    }
}
