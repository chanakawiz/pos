<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ReturnRequestResource\Pages;
use App\Models\ReturnRequest;
use App\Services\OrderTrackingService;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class ReturnRequestResource extends Resource
{
    protected static ?string $model = ReturnRequest::class;

    protected static ?string $navigationIcon = 'heroicon-o-arrow-path';

    protected static ?string $navigationGroup = 'Sales & Fulfillment';

    protected static ?string $navigationLabel = 'Returns & Exchanges';

    protected static ?int $navigationSort = 2;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('RMA Request Details')
                    ->columns(2)
                    ->schema([
                        Forms\Components\TextInput::make('request_number')
                            ->disabled()
                            ->required(),
                        Forms\Components\Select::make('sale_id')
                            ->relationship('sale', 'invoice_number')
                            ->required()
                            ->disabled(),
                        Forms\Components\Select::make('customer_id')
                            ->relationship('customer', 'name')
                            ->disabled(),
                        Forms\Components\Select::make('type')
                            ->options([
                                'return' => 'Return / Refund',
                                'exchange' => 'Size / Variant Exchange',
                                'warranty_claim' => 'Warranty Claim',
                            ])
                            ->required(),
                        Forms\Components\Select::make('status')
                            ->options([
                                'pending' => 'Pending Concierge Review',
                                'approved' => 'Approved (Awaiting Items)',
                                'completed' => 'Completed & Settled',
                                'rejected' => 'Rejected',
                            ])
                            ->required(),
                        Forms\Components\TextInput::make('reason')
                            ->required()
                            ->maxLength(100),
                    ]),

                Forms\Components\Section::make('Customer & Concierge Communication')
                    ->schema([
                        Forms\Components\Textarea::make('customer_notes')
                            ->label('Customer Notes / Exchange Instructions')
                            ->disabled(),
                        Forms\Components\Textarea::make('staff_notes')
                            ->label('Concierge Internal & Customer Notes')
                            ->placeholder('Add review findings, exchange product details, or return receipt references...'),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('request_number')
                    ->searchable()
                    ->sortable()
                    ->weight('bold')
                    ->copyable(),
                Tables\Columns\TextColumn::make('sale.invoice_number')
                    ->label('Invoice')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('customer.name')
                    ->searchable()
                    ->sortable()
                    ->default('Walk-in Customer'),
                Tables\Columns\TextColumn::make('type')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'exchange' => 'primary',
                        'warranty_claim' => 'warning',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'pending' => 'warning',
                        'approved' => 'info',
                        'completed' => 'success',
                        'rejected' => 'danger',
                        default => 'gray',
                    })
                    ->sortable(),
                Tables\Columns\TextColumn::make('items_count')
                    ->counts('items')
                    ->label('Items'),
                Tables\Columns\TextColumn::make('reason')
                    ->limit(35)
                    ->searchable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Submitted')
                    ->dateTime()
                    ->sortable(),
            ])
            ->defaultSort('created_at', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'pending' => 'Pending Review',
                        'approved' => 'Approved',
                        'completed' => 'Completed',
                        'rejected' => 'Rejected',
                    ]),
                Tables\Filters\SelectFilter::make('type')
                    ->options([
                        'return' => 'Return',
                        'exchange' => 'Exchange',
                        'warranty_claim' => 'Warranty Claim',
                    ]),
            ])
            ->actions([
                // Concierge Approve Action
                Tables\Actions\Action::make('approve')
                    ->label('Approve')
                    ->icon('heroicon-o-check')
                    ->color('success')
                    ->modalHeading('Approve Return / Exchange Request')
                    ->modalDescription('Authorize this return and notify the customer via SMS & real-time notification.')
                    ->form([
                        Forms\Components\Textarea::make('staff_notes')
                            ->label('Concierge Instructions / Replacement Details')
                            ->required()
                            ->default('Approved. Please package item in original box for courier pickup or counter handover.'),
                        Forms\Components\TextInput::make('loyalty_points_credit')
                            ->label('Credit Privilege Loyalty Points (Optional)')
                            ->numeric()
                            ->default(0)
                            ->helperText('Award instant store credit points to the customer profile upon approval.'),
                    ])
                    ->action(function (ReturnRequest $record, array $data) {
                        app(OrderTrackingService::class)->actionReturnRequest(
                            $record,
                            'approved',
                            $data['staff_notes'],
                            auth()->user(),
                            (int) ($data['loyalty_points_credit'] ?? 0)
                        );

                        Notification::make()
                            ->title('Return Request Approved')
                            ->body("Request #{$record->request_number} has been approved.")
                            ->success()
                            ->send();
                    })
                    ->visible(fn (ReturnRequest $record): bool => $record->status === 'pending'),

                // Concierge Reject Action
                Tables\Actions\Action::make('reject')
                    ->label('Reject')
                    ->icon('heroicon-o-x-mark')
                    ->color('danger')
                    ->modalHeading('Reject Return Request')
                    ->form([
                        Forms\Components\Textarea::make('staff_notes')
                            ->label('Rejection Reason')
                            ->required()
                            ->placeholder('Specify why this return cannot be accepted...'),
                    ])
                    ->action(function (ReturnRequest $record, array $data) {
                        app(OrderTrackingService::class)->actionReturnRequest(
                            $record,
                            'rejected',
                            $data['staff_notes'],
                            auth()->user()
                        );

                        Notification::make()
                            ->title('Return Request Rejected')
                            ->body("Request #{$record->request_number} has been rejected.")
                            ->warning()
                            ->send();
                    })
                    ->visible(fn (ReturnRequest $record): bool => $record->status === 'pending'),

                // Concierge Mark Complete Action
                Tables\Actions\Action::make('complete')
                    ->label('Complete')
                    ->icon('heroicon-o-check-badge')
                    ->color('info')
                    ->requiresConfirmation()
                    ->modalHeading('Complete Return / Exchange')
                    ->modalDescription('Confirm that returned items have been inspected and replacement/refund has been provided.')
                    ->action(function (ReturnRequest $record) {
                        app(OrderTrackingService::class)->actionReturnRequest(
                            $record,
                            'completed',
                            $record->staff_notes,
                            auth()->user()
                        );

                        Notification::make()
                            ->title('Return Settled & Completed')
                            ->body("Request #{$record->request_number} marked as completed.")
                            ->success()
                            ->send();
                    })
                    ->visible(fn (ReturnRequest $record): bool => $record->status === 'approved'),

                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListReturnRequests::route('/'),
            'edit' => Pages\EditReturnRequest::route('/{record}/edit'),
        ];
    }
}
