<?php

namespace App\Filament\Resources;

use App\Filament\Resources\GiftCardResource\Pages;
use App\Models\GiftCard;
use App\Services\GiftCardService;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class GiftCardResource extends Resource
{
    protected static ?string $model = GiftCard::class;

    protected static ?string $navigationIcon = 'heroicon-o-gift';

    protected static ?string $navigationGroup = 'Sales & Fulfillment';

    protected static ?string $navigationLabel = 'VIP Gift Cards';

    protected static ?int $navigationSort = 3;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Gift Card Identity & Balance')
                    ->columns(2)
                    ->schema([
                        Forms\Components\TextInput::make('code')
                            ->default(fn () => GiftCard::generateUniqueCode())
                            ->disabled(fn ($record) => $record !== null)
                            ->dehydrated()
                            ->required()
                            ->maxLength(32),
                        Forms\Components\Select::make('status')
                            ->options([
                                'active' => 'Active (Available)',
                                'redeemed' => 'Redeemed (Zero Balance)',
                                'expired' => 'Expired',
                                'disabled' => 'Disabled / Revoked',
                            ])
                            ->default('active')
                            ->required(),
                        Forms\Components\TextInput::make('initial_amount')
                            ->label('Initial Face Value (Rs.)')
                            ->numeric()
                            ->prefix('Rs.')
                            ->required()
                            ->disabled(fn ($record) => $record !== null),
                        Forms\Components\TextInput::make('balance')
                            ->label('Current Balance (Rs.)')
                            ->numeric()
                            ->prefix('Rs.')
                            ->required(),
                    ]),

                Forms\Components\Section::make('Cardholder & Boutique Association')
                    ->columns(2)
                    ->schema([
                        Forms\Components\Select::make('customer_id')
                            ->label('Assigned Customer / VIP Member')
                            ->relationship('customer', 'name')
                            ->searchable()
                            ->preload(),
                        Forms\Components\Select::make('store_id')
                            ->label('Issuing Boutique Outlet')
                            ->relationship('store', 'name')
                            ->searchable()
                            ->preload(),
                        Forms\Components\DateTimePicker::make('expires_at')
                            ->label('Expiration Date')
                            ->default(now()->addYear()),
                        Forms\Components\Textarea::make('notes')
                            ->label('Concierge Notes & Occasion')
                            ->columnSpanFull(),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('code')
                    ->label('Card Code')
                    ->searchable()
                    ->copyable()
                    ->copyMessage('Gift card code copied!')
                    ->weight('bold')
                    ->fontFamily('mono')
                    ->color('primary'),
                Tables\Columns\TextColumn::make('customer.name')
                    ->label('Cardholder')
                    ->searchable()
                    ->default('Boutique Bearer'),
                Tables\Columns\TextColumn::make('balance')
                    ->label('Available Balance')
                    ->money('LKR')
                    ->sortable()
                    ->weight('semibold')
                    ->color(fn ($state) => $state > 0 ? 'success' : 'danger'),
                Tables\Columns\TextColumn::make('initial_amount')
                    ->label('Face Value')
                    ->money('LKR')
                    ->sortable()
                    ->color('gray'),
                Tables\Columns\BadgeColumn::make('status')
                    ->colors([
                        'success' => 'active',
                        'warning' => 'redeemed',
                        'danger' => 'expired',
                        'secondary' => 'disabled',
                    ]),
                Tables\Columns\TextColumn::make('store.name')
                    ->label('Issued At')
                    ->default('Head Office'),
                Tables\Columns\TextColumn::make('expires_at')
                    ->label('Expires')
                    ->dateTime('M d, Y')
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'active' => 'Active',
                        'redeemed' => 'Redeemed',
                        'expired' => 'Expired',
                        'disabled' => 'Disabled',
                    ]),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\Action::make('toggle_status')
                    ->label(fn (GiftCard $record) => $record->status === 'disabled' ? 'Enable' : 'Disable')
                    ->icon(fn (GiftCard $record) => $record->status === 'disabled' ? 'heroicon-o-check-circle' : 'heroicon-o-no-symbol')
                    ->color(fn (GiftCard $record) => $record->status === 'disabled' ? 'success' : 'danger')
                    ->requiresConfirmation()
                    ->action(function (GiftCard $record) {
                        $newStatus = $record->status === 'disabled' ? ($record->balance > 0 ? 'active' : 'redeemed') : 'disabled';
                        $record->update(['status' => $newStatus]);
                        Notification::make()
                            ->title("Card status updated to {$newStatus}")
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

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListGiftCards::route('/'),
            'create' => Pages\CreateGiftCard::route('/create'),
            'edit' => Pages\EditGiftCard::route('/{record}/edit'),
        ];
    }
}
