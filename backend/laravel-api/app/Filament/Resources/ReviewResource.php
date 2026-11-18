<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ReviewResource\Pages;
use App\Models\ProductReview;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class ReviewResource extends Resource
{
    protected static ?string $model = ProductReview::class;

    protected static ?string $navigationIcon = 'heroicon-o-star';

    protected static ?string $navigationGroup = 'Catalog & Inventory';

    protected static ?string $navigationLabel = 'Customer Reviews';

    protected static ?int $navigationSort = 5;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Review Details')
                    ->schema([
                        Forms\Components\Select::make('product_id')
                            ->relationship('product', 'name')
                            ->searchable()
                            ->required(),
                        Forms\Components\Select::make('customer_id')
                            ->relationship('customer', 'name')
                            ->searchable()
                            ->nullable(),
                        Forms\Components\TextInput::make('customer_name')
                            ->required()
                            ->maxLength(100),
                        Forms\Components\TextInput::make('customer_email')
                            ->email()
                            ->maxLength(150),
                        Forms\Components\Select::make('rating')
                            ->options([
                                5 => '★★★★★ (5 Stars - Exceptional)',
                                4 => '★★★★☆ (4 Stars - Very Good)',
                                3 => '★★★☆☆ (3 Stars - Average)',
                                2 => '★★☆☆☆ (2 Stars - Below Average)',
                                1 => '★☆☆☆☆ (1 Star - Poor)',
                            ])
                            ->required(),
                        Forms\Components\Select::make('status')
                            ->options([
                                'approved' => 'Approved (Live on Store)',
                                'pending' => 'Pending Moderation',
                                'rejected' => 'Rejected',
                            ])
                            ->required(),
                        Forms\Components\Toggle::make('is_verified_purchase')
                            ->label('Verified Buyer (Purchased via POS or Web Store)')
                            ->default(false),
                        Forms\Components\TextInput::make('helpful_votes')
                            ->numeric()
                            ->default(0),
                        Forms\Components\TextInput::make('title')
                            ->columnSpanFull()
                            ->maxLength(150),
                        Forms\Components\Textarea::make('comment')
                            ->required()
                            ->rows(4)
                            ->columnSpanFull(),
                    ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Date')
                    ->dateTime('M j, Y')
                    ->sortable(),

                Tables\Columns\TextColumn::make('product.name')
                    ->label('Product')
                    ->searchable()
                    ->sortable()
                    ->weight('bold')
                    ->limit(28),

                Tables\Columns\TextColumn::make('rating')
                    ->label('Rating')
                    ->badge()
                    ->formatStateUsing(fn (int $state): string => str_repeat('★', $state) . ' (' . $state . '/5)')
                    ->colors([
                        'success' => fn ($state) => $state >= 4,
                        'warning' => fn ($state) => $state === 3,
                        'danger' => fn ($state) => $state <= 2,
                    ])
                    ->sortable(),

                Tables\Columns\TextColumn::make('customer_name')
                    ->label('Reviewer')
                    ->searchable(),

                Tables\Columns\IconColumn::make('is_verified_purchase')
                    ->label('Verified')
                    ->boolean()
                    ->trueIcon('heroicon-s-check-badge')
                    ->falseIcon('heroicon-o-minus')
                    ->trueColor('success')
                    ->falseColor('gray'),

                Tables\Columns\TextColumn::make('title')
                    ->label('Title')
                    ->limit(25)
                    ->placeholder('—'),

                Tables\Columns\TextColumn::make('status')
                    ->label('Status')
                    ->badge()
                    ->colors([
                        'success' => 'approved',
                        'warning' => 'pending',
                        'danger' => 'rejected',
                    ]),

                Tables\Columns\TextColumn::make('helpful_votes')
                    ->label('Helpful')
                    ->numeric()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->defaultSort('created_at', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'approved' => 'Approved',
                        'pending' => 'Pending',
                        'rejected' => 'Rejected',
                    ]),
                Tables\Filters\SelectFilter::make('rating')
                    ->options([
                        5 => '5 Stars',
                        4 => '4 Stars',
                        3 => '3 Stars',
                        2 => '2 Stars',
                        1 => '1 Star',
                    ]),
                Tables\Filters\TernaryFilter::make('is_verified_purchase')
                    ->label('Verified Buyers Only'),
            ])
            ->actions([
                Tables\Actions\Action::make('approve')
                    ->label('Approve')
                    ->icon('heroicon-o-check')
                    ->color('success')
                    ->requiresConfirmation()
                    ->visible(fn (ProductReview $record): bool => $record->status !== 'approved')
                    ->action(function (ProductReview $record) {
                        $record->update(['status' => 'approved']);
                        Notification::make()
                            ->title('Review Approved')
                            ->body("Review published for {$record->product->name}")
                            ->success()
                            ->send();
                    }),

                Tables\Actions\Action::make('reject')
                    ->label('Reject')
                    ->icon('heroicon-o-x-mark')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->visible(fn (ProductReview $record): bool => $record->status !== 'rejected')
                    ->action(function (ProductReview $record) {
                        $record->update(['status' => 'rejected']);
                        Notification::make()
                            ->title('Review Rejected')
                            ->body("Review hidden for {$record->product->name}")
                            ->warning()
                            ->send();
                    }),

                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
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
            'index' => Pages\ListReviews::route('/'),
            'create' => Pages\CreateReview::route('/create'),
            'edit' => Pages\EditReview::route('/{record}/edit'),
        ];
    }
}
