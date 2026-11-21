<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PromotionResource\Pages;
use App\Models\Promotion;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class PromotionResource extends Resource
{
    protected static ?string $model = Promotion::class;

    protected static ?string $navigationIcon = 'heroicon-o-ticket';

    protected static ?string $navigationGroup = 'Sales & Fulfillment';

    protected static ?string $navigationLabel = 'Promotions & Coupons';

    protected static ?int $navigationSort = 4;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Campaign Identity & Discount Rule')
                    ->columns(2)
                    ->schema([
                        Forms\Components\TextInput::make('code')
                            ->label('Promo / Coupon Code')
                            ->placeholder('e.g. LUXE15, FLASH20')
                            ->required()
                            ->unique(ignoreRecord: true)
                            ->maxLength(64),
                        Forms\Components\TextInput::make('name')
                            ->label('Campaign Title')
                            ->placeholder('e.g. Holiday Luxury 15% Off')
                            ->required()
                            ->maxLength(191),
                        Forms\Components\Select::make('type')
                            ->label('Discount Type')
                            ->options([
                                'percentage' => 'Percentage Off (%)',
                                'fixed_amount' => 'Fixed Amount Off (LKR)',
                                'buy_x_get_y' => 'Buy X Get Y Free',
                            ])
                            ->default('percentage')
                            ->reactive()
                            ->required(),
                        Forms\Components\TextInput::make('value')
                            ->label('Discount Value (% or LKR)')
                            ->numeric()
                            ->default(10)
                            ->visible(fn (Forms\Get $get) => $get('type') !== 'buy_x_get_y'),
                        Forms\Components\TextInput::make('buy_quantity')
                            ->label('Buy Quantity (X)')
                            ->numeric()
                            ->default(2)
                            ->visible(fn (Forms\Get $get) => $get('type') === 'buy_x_get_y'),
                        Forms\Components\TextInput::make('get_quantity')
                            ->label('Get Free Quantity (Y)')
                            ->numeric()
                            ->default(1)
                            ->visible(fn (Forms\Get $get) => $get('type') === 'buy_x_get_y'),
                        Forms\Components\Textarea::make('description')
                            ->label('Campaign Description')
                            ->columnSpanFull(),
                    ]),

                Forms\Components\Section::make('Eligibility, Caps & Omnichannel Schedule')
                    ->columns(2)
                    ->schema([
                        Forms\Components\TextInput::make('min_order_amount')
                            ->label('Minimum Order Amount (LKR)')
                            ->numeric()
                            ->prefix('Rs.')
                            ->default(0),
                        Forms\Components\TextInput::make('max_discount_amount')
                            ->label('Maximum Discount Cap (LKR)')
                            ->numeric()
                            ->prefix('Rs.')
                            ->nullable(),
                        Forms\Components\TextInput::make('max_uses')
                            ->label('Global Usage Limit')
                            ->numeric()
                            ->nullable(),
                        Forms\Components\TextInput::make('max_uses_per_customer')
                            ->label('Max Uses Per Customer')
                            ->numeric()
                            ->nullable(),
                        Forms\Components\CheckboxList::make('allowed_channels')
                            ->label('Eligible Channels')
                            ->options([
                                'web' => 'Web Storefront',
                                'mobile' => 'Consumer Mobile App',
                                'pos' => 'In-Store POS (Desktop & Handheld)',
                            ])
                            ->default(['web', 'mobile', 'pos'])
                            ->columns(3)
                            ->columnSpanFull(),
                        Forms\Components\Select::make('applicable_category_id')
                            ->label('Department Scope (Optional)')
                            ->relationship('category', 'name')
                            ->searchable()
                            ->preload(),
                        Forms\Components\Select::make('vip_tier_required')
                            ->label('Minimum VIP Tier (Optional)')
                            ->options([
                                'silver' => 'Silver Privilege+',
                                'gold' => 'Gold Elite+',
                                'black' => 'Black Diamond Only',
                            ])
                            ->nullable(),
                        Forms\Components\DateTimePicker::make('starts_at')
                            ->label('Campaign Starts At'),
                        Forms\Components\DateTimePicker::make('ends_at')
                            ->label('Campaign Ends At'),
                        Forms\Components\Toggle::make('is_auto_apply')
                            ->label('Auto-Apply Seasonal Campaign'),
                        Forms\Components\Toggle::make('is_active')
                            ->label('Campaign Active')
                            ->default(true),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('code')
                    ->label('Code')
                    ->searchable()
                    ->copyable()
                    ->weight('bold')
                    ->fontFamily('mono')
                    ->color('primary'),
                Tables\Columns\TextColumn::make('name')
                    ->label('Campaign')
                    ->searchable()
                    ->limit(30),
                Tables\Columns\BadgeColumn::make('type')
                    ->colors([
                        'success' => 'percentage',
                        'warning' => 'fixed_amount',
                        'info' => 'buy_x_get_y',
                    ])
                    ->formatStateUsing(fn (Promotion $record) => $record->discount_label),
                Tables\Columns\TextColumn::make('uses_count')
                    ->label('Redemptions')
                    ->formatStateUsing(fn (Promotion $record) => $record->max_uses
                        ? "{$record->uses_count} / {$record->max_uses}"
                        : (string) $record->uses_count)
                    ->sortable(),
                Tables\Columns\TextColumn::make('vip_tier_required')
                    ->label('VIP Gate')
                    ->default('All Shoppers')
                    ->formatStateUsing(fn ($state) => $state ? ucfirst($state) . '+' : 'All Shoppers'),
                Tables\Columns\IconColumn::make('is_active')
                    ->label('Active')
                    ->boolean(),
                Tables\Columns\TextColumn::make('ends_at')
                    ->label('Expires')
                    ->dateTime('M d, Y')
                    ->placeholder('No Expiry')
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('is_active')
                    ->label('Active Status'),
                Tables\Filters\SelectFilter::make('type')
                    ->options([
                        'percentage' => 'Percentage',
                        'fixed_amount' => 'Fixed Amount',
                        'buy_x_get_y' => 'Buy X Get Y',
                    ]),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\Action::make('toggle_active')
                    ->label(fn (Promotion $record) => $record->is_active ? 'Pause' : 'Activate')
                    ->icon(fn (Promotion $record) => $record->is_active ? 'heroicon-o-pause-circle' : 'heroicon-o-play-circle')
                    ->color(fn (Promotion $record) => $record->is_active ? 'warning' : 'success')
                    ->action(function (Promotion $record) {
                        $record->update(['is_active' => ! $record->is_active]);
                        Notification::make()
                            ->title($record->is_active ? "Activated {$record->code}" : "Paused {$record->code}")
                            ->success()
                            ->send();
                    }),
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
            'index' => Pages\ListPromotions::route('/'),
            'create' => Pages\CreatePromotion::route('/create'),
            'edit' => Pages\EditPromotion::route('/{record}/edit'),
        ];
    }
}
