<?php

namespace App\Filament\Resources;

use App\Filament\Resources\StocktakeResource\Pages;
use App\Models\Stocktake;
use App\Services\StocktakeService;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class StocktakeResource extends Resource
{
    protected static ?string $model = Stocktake::class;

    protected static ?string $navigationIcon = 'heroicon-o-clipboard-document-check';

    protected static ?string $navigationGroup = 'Catalog & Inventory';

    protected static ?string $navigationLabel = 'Stocktakes & Audits';

    protected static ?int $navigationSort = 6;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Cycle Count Audit Details')
                    ->columns(2)
                    ->schema([
                        Forms\Components\TextInput::make('stocktake_number')
                            ->disabled()
                            ->dehydrated(false),
                        Forms\Components\Select::make('store_id')
                            ->relationship('store', 'name')
                            ->required()
                            ->disabled(fn ($record) => $record !== null),
                        Forms\Components\Select::make('status')
                            ->options([
                                'in_progress' => 'In Progress',
                                'completed' => 'Completed & Adjusted',
                                'cancelled' => 'Cancelled',
                            ])
                            ->default('in_progress')
                            ->disabled(),
                        Forms\Components\TextInput::make('total_items_counted')
                            ->numeric()
                            ->disabled(),
                        Forms\Components\TextInput::make('net_quantity_variance')
                            ->numeric()
                            ->disabled(),
                        Forms\Components\TextInput::make('net_value_variance')
                            ->prefix('Rs.')
                            ->numeric()
                            ->disabled(),
                        Forms\Components\Textarea::make('notes')
                            ->columnSpanFull(),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('stocktake_number')
                    ->label('Audit Ref')
                    ->searchable()
                    ->copyable()
                    ->fontFamily('mono')
                    ->weight('bold')
                    ->color('primary'),
                Tables\Columns\TextColumn::make('store.name')
                    ->label('Boutique')
                    ->sortable(),
                Tables\Columns\TextColumn::make('user.name')
                    ->label('Auditor')
                    ->default('Staff'),
                Tables\Columns\TextColumn::make('total_items_counted')
                    ->label('SKUs Counted')
                    ->sortable(),
                Tables\Columns\TextColumn::make('variance_items_count')
                    ->label('Discrepancies')
                    ->badge()
                    ->color(fn ($state) => (int) $state > 0 ? 'warning' : 'success'),
                Tables\Columns\TextColumn::make('net_value_variance')
                    ->label('Net Value Var.')
                    ->money('LKR')
                    ->color(fn ($state) => (float) $state < 0 ? 'danger' : ((float) $state > 0 ? 'success' : 'gray'))
                    ->sortable(),
                Tables\Columns\BadgeColumn::make('status')
                    ->colors([
                        'warning' => 'in_progress',
                        'success' => 'completed',
                        'danger' => 'cancelled',
                    ]),
                Tables\Columns\TextColumn::make('completed_at')
                    ->label('Completed')
                    ->dateTime('M d, H:i')
                    ->placeholder('Active'),
            ])
            ->defaultSort('created_at', 'desc')
            ->actions([
                Tables\Actions\Action::make('finalize')
                    ->label('Finalize & Adjust')
                    ->icon('heroicon-o-check-badge')
                    ->color('success')
                    ->visible(fn (Stocktake $record) => $record->status === 'in_progress')
                    ->requiresConfirmation()
                    ->action(function (Stocktake $record) {
                        app(StocktakeService::class)->finalizeStocktake($record, auth()->user(), true);
                        Notification::make()
                            ->title("Stocktake {$record->stocktake_number} finalized & inventory adjusted")
                            ->success()
                            ->send();
                    }),
                Tables\Actions\EditAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListStocktakes::route('/'),
            'edit' => Pages\EditStocktake::route('/{record}/edit'),
        ];
    }
}
