<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PurchaseResource\Pages;
use App\Models\Product;
use App\Models\Purchase;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class PurchaseResource extends Resource
{
    protected static ?string $model = Purchase::class;

    protected static ?string $navigationIcon = 'heroicon-o-clipboard-document-check';

    protected static ?string $navigationGroup = 'Purchasing & Supply';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('purchase_number')
                    ->default(fn () => 'PO-'.strtoupper(uniqid()))
                    ->required()
                    ->maxLength(100),
                Forms\Components\Select::make('supplier_id')
                    ->relationship('supplier', 'name')
                    ->required()
                    ->searchable()
                    ->preload(),
                Forms\Components\Select::make('store_id')
                    ->relationship('store', 'name')
                    ->required()
                    ->searchable()
                    ->preload(),
                Forms\Components\Select::make('user_id')
                    ->relationship('user', 'name')
                    ->required()
                    ->searchable()
                    ->preload(),
                Forms\Components\Select::make('status')
                    ->options([
                        'pending' => 'Pending',
                        'ordered' => 'Ordered',
                        'received' => 'Received',
                        'cancelled' => 'Cancelled',
                    ])
                    ->default('pending')
                    ->required(),
                Forms\Components\DateTimePicker::make('purchased_at')
                    ->default(now())
                    ->required(),
                Forms\Components\TextInput::make('total_amount')
                    ->numeric()
                    ->prefix('$')
                    ->default(0.00)
                    ->required(),
                Forms\Components\Textarea::make('notes')
                    ->columnSpanFull(),

                Forms\Components\Section::make('Purchase Items')
                    ->schema([
                        Forms\Components\Repeater::make('items')
                            ->relationship()
                            ->schema([
                                Forms\Components\Select::make('product_id')
                                    ->relationship('product', 'name')
                                    ->required()
                                    ->searchable()
                                    ->preload()
                                    ->reactive()
                                    ->afterStateUpdated(function ($state, Forms\Set $set) {
                                        $product = Product::find($state);
                                        if ($product) {
                                            $set('unit_cost', $product->cost_price);
                                        }
                                    })
                                    ->columnSpan(4),
                                Forms\Components\TextInput::make('quantity')
                                    ->numeric()
                                    ->step(0.001)
                                    ->minValue(0.001)
                                    ->rules(['decimal:0,3'])
                                    ->default(1)
                                    ->required()
                                    ->reactive()
                                    ->afterStateUpdated(function (Forms\Get $get, Forms\Set $set) {
                                        $qty = (float) ($get('quantity') ?? 0);
                                        $cost = (float) ($get('unit_cost') ?? 0);
                                        $set('total', round($qty * $cost, 2));
                                    })
                                    ->columnSpan(2),
                                Forms\Components\TextInput::make('unit_cost')
                                    ->numeric()
                                    ->prefix('$')
                                    ->required()
                                    ->reactive()
                                    ->afterStateUpdated(function (Forms\Get $get, Forms\Set $set) {
                                        $qty = (float) ($get('quantity') ?? 0);
                                        $cost = (float) ($get('unit_cost') ?? 0);
                                        $set('total', round($qty * $cost, 2));
                                    })
                                    ->columnSpan(3),
                                Forms\Components\TextInput::make('total')
                                    ->numeric()
                                    ->prefix('$')
                                    ->required()
                                    ->columnSpan(3),
                            ])
                            ->columns(12)
                            ->defaultItems(1),
                    ])
                    ->collapsible(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('purchase_number')
                    ->searchable()
                    ->sortable()
                    ->weight('bold'),
                Tables\Columns\TextColumn::make('supplier.name')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('store.name')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\BadgeColumn::make('status')
                    ->colors([
                        'warning' => 'pending',
                        'primary' => 'ordered',
                        'success' => 'received',
                        'danger' => 'cancelled',
                    ]),
                Tables\Columns\TextColumn::make('total_amount')
                    ->money('USD')
                    ->sortable(),
                Tables\Columns\TextColumn::make('purchased_at')
                    ->dateTime()
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'pending' => 'Pending',
                        'ordered' => 'Ordered',
                        'received' => 'Received',
                        'cancelled' => 'Cancelled',
                    ]),
                Tables\Filters\SelectFilter::make('supplier')
                    ->relationship('supplier', 'name'),
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
            'index' => Pages\ListPurchases::route('/'),
            'create' => Pages\CreatePurchase::route('/create'),
            'edit' => Pages\EditPurchase::route('/{record}/edit'),
        ];
    }
}
