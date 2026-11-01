<?php

namespace App\Filament\Resources\GiftCardResource\Pages;

use App\Filament\Resources\GiftCardResource;
use App\Models\GiftCardTransaction;
use Filament\Resources\Pages\CreateRecord;
use Illuminate\Database\Eloquent\Model;

class CreateGiftCard extends CreateRecord
{
    protected static string $resource = GiftCardResource::class;

    protected function handleRecordCreation(array $data): Model
    {
        // Set balance equal to initial amount if not explicitly provided
        if (!isset($data['balance']) || $data['balance'] === null) {
            $data['balance'] = $data['initial_amount'];
        }

        $data['issued_by'] = auth()->id();

        $record = parent::handleRecordCreation($data);

        // Record initial issue transaction
        GiftCardTransaction::create([
            'gift_card_id' => $record->id,
            'store_id' => $record->store_id,
            'user_id' => auth()->id(),
            'type' => 'issue',
            'amount' => $record->initial_amount,
            'balance_before' => 0.00,
            'balance_after' => $record->initial_amount,
            'reference' => 'ERP_ADMIN_ISSUE',
            'notes' => $record->notes ?? 'Issued via Central ERP Control Room',
        ]);

        return $record;
    }
}
