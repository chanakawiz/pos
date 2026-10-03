<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CashSessionResource\Pages;
use App\Models\CashSession;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class CashSessionResource extends Resource
{
    protected static ?string $model = CashSession::class;

    protected static ?string $navigationIcon = 'heroicon-o-banknotes';

    protected static ?string $navigationGroup = 'POS & Registers';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Select::make('store_id')
                    ->relationship('store', 'name')
                    ->required()
                    ->searchable()
                    ->preload(),
                Forms\Components\Select::make('device_id')
                    ->relationship('device', 'device_name')
                    ->searchable()
                    ->preload(),
                Forms\Components\Select::make('cashier_id')
                    ->relationship('cashier', 'name')
                    ->required()
                    ->searchable()
                    ->preload(),
                Forms\Components\Select::make('status')
                    ->options([
                        'open'   => 'Open',
                        'closed' => 'Closed',
                    ])
                    ->default('open')
                    ->required(),
                Forms\Components\DateTimePicker::make('opened_at')
                    ->default(now())
                    ->required(),
                Forms\Components\DateTimePicker::make('closed_at'),
                Forms\Components\TextInput::make('opening_balance')
                    ->numeric()
                    ->prefix('$')
                    ->default(0.00)
                    ->required(),
                Forms\Components\TextInput::make('closing_balance')
                    ->numeric()
                    ->prefix('$'),
                Forms\Components\TextInput::make('expected_balance')
                    ->numeric()
                    ->prefix('$'),
                Forms\Components\TextInput::make('discrepancy')
                    ->numeric()
                    ->prefix('$'),
                Forms\Components\Textarea::make('notes')
                    ->columnSpanFull(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('store.name')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('cashier.name')
                    ->searchable()
                    ->sortable()
                    ->weight('bold'),
                Tables\Columns\TextColumn::make('device.device_name')
                    ->label('Terminal')
                    ->searchable(),
                Tables\Columns\BadgeColumn::make('status')
                    ->colors([
                        'success' => 'open',
                        'secondary' => 'closed',
                    ]),
                Tables\Columns\TextColumn::make('opening_balance')
                    ->money('USD')
                    ->sortable(),
                Tables\Columns\TextColumn::make('closing_balance')
                    ->money('USD')
                    ->sortable(),
                Tables\Columns\TextColumn::make('discrepancy')
                    ->money('USD')
                    ->color(fn ($state) => $state < 0 ? 'danger' : ($state > 0 ? 'warning' : 'success'))
                    ->sortable(),
                Tables\Columns\TextColumn::make('opened_at')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('closed_at')
                    ->dateTime()
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'open'   => 'Open',
                        'closed' => 'Closed',
                    ]),
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
            'index'  => Pages\ListCashSessions::route('/'),
            'create' => Pages\CreateCashSession::route('/create'),
            'edit'   => Pages\EditCashSession::route('/{record}/edit'),
        ];
    }
}
