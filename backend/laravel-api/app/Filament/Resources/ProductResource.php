<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ProductResource\Pages;
use App\Models\Product;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Support\Str;

class ProductResource extends Resource
{
    protected static ?string $model = Product::class;

    protected static ?string $navigationIcon = 'heroicon-o-cube';

    protected static ?string $navigationGroup = 'Catalog & Inventory';

    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Tabs::make('Product Details')
                    ->tabs([
                        Forms\Components\Tabs\Tab::make('General Information')
                            ->schema([
                                Forms\Components\Grid::make(2)
                                    ->schema([
                                        Forms\Components\TextInput::make('name')
                                            ->label('Product Name (English)')
                                            ->placeholder('e.g. Anchor Full Cream Milk Powder 400g')
                                            ->required()
                                            ->maxLength(255),

                                        Forms\Components\TextInput::make('sinhala_name')
                                            ->label('Product Name (සිංහල / Sinhala)')
                                            ->placeholder('උදා: ඇන්කර් කිරිපිටි 400g')
                                            ->maxLength(255),
                                    ]),

                                Forms\Components\Grid::make(3)
                                    ->schema([
                                        Forms\Components\Select::make('category_id')
                                            ->label('Category')
                                            ->relationship('category', 'name')
                                            ->searchable()
                                            ->preload()
                                            ->createOptionForm([
                                                Forms\Components\TextInput::make('name')->required(),
                                                Forms\Components\TextInput::make('slug')->required(),
                                            ]),

                                        Forms\Components\Select::make('brand_id')
                                            ->label('Brand')
                                            ->relationship('brand', 'name')
                                            ->searchable()
                                            ->preload()
                                            ->createOptionForm([
                                                Forms\Components\TextInput::make('name')->required(),
                                                Forms\Components\TextInput::make('slug')->required(),
                                            ]),

                                        Forms\Components\Select::make('unit')
                                            ->label('Unit of Measure')
                                            ->options([
                                                'piece' => 'Piece / Unit (pcs)',
                                                'kg' => 'Kilogram (kg)',
                                                'g' => 'Gram (g)',
                                                'liter' => 'Liter (L)',
                                                'ml' => 'Milliliter (ml)',
                                                'pack' => 'Pack / Box',
                                                'bottle' => 'Bottle',
                                            ])
                                            ->default('piece')
                                            ->required(),
                                    ]),

                                Forms\Components\Textarea::make('description')
                                    ->rows(3)
                                    ->columnSpanFull(),
                            ]),

                        Forms\Components\Tabs\Tab::make('Barcode & Identifiers')
                            ->schema([
                                Forms\Components\Grid::make(2)
                                    ->schema([
                                        Forms\Components\TextInput::make('sku')
                                            ->label('SKU (Stock Keeping Unit)')
                                            ->default(fn () => 'SKU-'.strtoupper(Str::random(8)))
                                            ->required()
                                            ->unique(ignoreRecord: true)
                                            ->maxLength(100),

                                        Forms\Components\TextInput::make('barcode')
                                            ->label('Barcode / EAN-13 (Scan here)')
                                            ->placeholder('Scan product barcode with scanner')
                                            ->helperText('Use any USB/Bluetooth barcode reader or type barcode numbers')
                                            ->unique(ignoreRecord: true)
                                            ->maxLength(100),
                                    ]),
                            ]),

                        Forms\Components\Tabs\Tab::make('Smart Items & Warranty')
                            ->schema([
                                Forms\Components\Grid::make(2)
                                    ->schema([
                                        Forms\Components\TextInput::make('warranty_period')
                                            ->label('Warranty Period')
                                            ->placeholder('e.g. 12 Months Official / 6 Months Store')
                                            ->maxLength(100)
                                            ->helperText('Printed automatically on invoice for mobile/electronics warranty'),

                                        Forms\Components\Toggle::make('requires_serial')
                                            ->label('Requires Serial / IMEI Scan')
                                            ->helperText('Enables IMEI/Serial number prompt during checkout')
                                            ->default(false),
                                    ]),
                            ]),

                        Forms\Components\Tabs\Tab::make('Pricing & Taxes')
                            ->schema([
                                Forms\Components\Grid::make(3)
                                    ->schema([
                                        Forms\Components\TextInput::make('cost_price')
                                            ->label('Cost Price')
                                            ->numeric()
                                            ->prefix('$')
                                            ->default(0.00)
                                            ->required(),

                                        Forms\Components\TextInput::make('selling_price')
                                            ->label('Retail Selling Price')
                                            ->numeric()
                                            ->prefix('$')
                                            ->default(0.00)
                                            ->required(),

                                        Forms\Components\TextInput::make('tax_rate')
                                            ->label('Tax Rate (%)')
                                            ->numeric()
                                            ->suffix('%')
                                            ->default(0.00)
                                            ->required(),
                                    ]),
                            ]),

                        Forms\Components\Tabs\Tab::make('Inventory & Stock Levels')
                            ->schema([
                                Forms\Components\Grid::make(2)
                                    ->schema([
                                        Forms\Components\TextInput::make('initial_stock')
                                            ->label('Initial Stock Quantity (Store 1)')
                                            ->helperText('Initial inventory count in the product unit; up to three decimals')
                                            ->numeric()
                                            ->step(0.001)
                                            ->minValue(0)
                                            ->rules(['decimal:0,3'])
                                            ->default(10)
                                            ->visible(fn (string $operation) => $operation === 'create'),

                                        Forms\Components\TextInput::make('min_stock_level')
                                            ->label('Low Stock Alert Level')
                                            ->helperText('Trigger warning when stock drops to or below this level')
                                            ->numeric()
                                            ->default(5)
                                            ->required(),
                                    ]),

                                Forms\Components\Grid::make(2)
                                    ->schema([
                                        Forms\Components\Toggle::make('is_active')
                                            ->label('Active for Sale')
                                            ->default(true),

                                        Forms\Components\Toggle::make('has_variants')
                                            ->label('Has Product Variants')
                                            ->default(false),
                                    ]),
                            ]),

                        Forms\Components\Tabs\Tab::make('Media')
                            ->schema([
                                Forms\Components\FileUpload::make('image_path')
                                    ->label('Product Image')
                                    ->image()
                                    ->directory('products'),
                            ]),
                    ])
                    ->columnSpanFull(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\ImageColumn::make('image_path')
                    ->label('Image')
                    ->circular(),

                Tables\Columns\TextColumn::make('name')
                    ->label('Product Name')
                    ->description(fn (Product $record): ?string => $record->sinhala_name)
                    ->searchable(['name', 'sinhala_name'])
                    ->sortable()
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('barcode')
                    ->label('Barcode')
                    ->fontFamily('mono')
                    ->searchable()
                    ->copyable(),

                Tables\Columns\TextColumn::make('category.name')
                    ->label('Category')
                    ->badge()
                    ->sortable(),

                Tables\Columns\TextColumn::make('brand.name')
                    ->label('Brand')
                    ->badge()
                    ->color('primary')
                    ->sortable(),

                Tables\Columns\TextColumn::make('cost_price')
                    ->label('Cost')
                    ->money('USD')
                    ->toggleable(isToggledHiddenByDefault: true),

                Tables\Columns\TextColumn::make('selling_price')
                    ->label('Price')
                    ->money('USD')
                    ->sortable()
                    ->weight('bold'),

                Tables\Columns\IconColumn::make('is_active')
                    ->label('Active')
                    ->boolean(),

                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('category')
                    ->relationship('category', 'name'),
                Tables\Filters\SelectFilter::make('brand')
                    ->relationship('brand', 'name'),
                Tables\Filters\TernaryFilter::make('is_active')
                    ->label('Active'),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
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
            'index' => Pages\ListProducts::route('/'),
            'create' => Pages\CreateProduct::route('/create'),
            'edit' => Pages\EditProduct::route('/{record}/edit'),
        ];
    }
}
