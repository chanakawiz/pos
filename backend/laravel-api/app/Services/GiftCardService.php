<?php

namespace App\Services;

use App\Models\GiftCard;
use App\Models\GiftCardTransaction;
use App\Models\Sale;
use App\Models\Store;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class GiftCardService
{
    /**
     * Issue a new boutique gift card with an initial transaction audit entry.
     */
    public function issueCard(
        float $amount,
        ?int $customerId = null,
        ?int $storeId = null,
        ?int $userId = null,
        ?string $expiresAt = null,
        ?string $notes = null
    ): GiftCard {
        if ($amount <= 0) {
            throw new InvalidArgumentException('Initial gift card amount must be greater than zero.');
        }

        return DB::transaction(function () use ($amount, $customerId, $storeId, $userId, $expiresAt, $notes) {
            $card = GiftCard::create([
                'initial_amount' => $amount,
                'balance' => $amount,
                'currency' => 'LKR',
                'status' => 'active',
                'customer_id' => $customerId,
                'store_id' => $storeId,
                'issued_by' => $userId,
                'expires_at' => $expiresAt ? Carbon::parse($expiresAt) : now()->addYear(),
                'notes' => $notes,
            ]);

            GiftCardTransaction::create([
                'gift_card_id' => $card->id,
                'store_id' => $storeId,
                'user_id' => $userId,
                'type' => 'issue',
                'amount' => $amount,
                'balance_before' => 0.00,
                'balance_after' => $amount,
                'reference' => 'INITIAL_ISSUE',
                'notes' => $notes ?? 'Card issue and credit activation',
            ]);

            return $card->fresh(['customer', 'store', 'issuer', 'transactions']);
        });
    }

    /**
     * Check gift card balance and redemption validity.
     */
    public function checkBalance(string $code): array
    {
        $normalizedCode = strtoupper(trim($code));
        $card = GiftCard::where('code', $normalizedCode)->first();

        if (!$card) {
            return [
                'found' => false,
                'valid' => false,
                'message' => 'Gift card code was not found.',
            ];
        }

        if ($card->status === 'disabled') {
            return [
                'found' => true,
                'valid' => false,
                'code' => $card->code,
                'balance' => (float) $card->balance,
                'message' => 'This gift card has been disabled by boutique concierge.',
            ];
        }

        if ($card->status === 'expired' || ($card->expires_at && $card->expires_at->isPast())) {
            if ($card->status !== 'expired') {
                $card->update(['status' => 'expired']);
            }
            return [
                'found' => true,
                'valid' => false,
                'code' => $card->code,
                'balance' => (float) $card->balance,
                'message' => 'This gift card expired on ' . ($card->expires_at ? $card->expires_at->format('M d, Y') : 'past date') . '.',
            ];
        }

        if ((float) $card->balance <= 0) {
            return [
                'found' => true,
                'valid' => false,
                'code' => $card->code,
                'balance' => 0.00,
                'message' => 'This gift card has a zero balance.',
            ];
        }

        return [
            'found' => true,
            'valid' => true,
            'code' => $card->code,
            'uuid' => $card->uuid,
            'balance' => (float) $card->balance,
            'initial_amount' => (float) $card->initial_amount,
            'currency' => $card->currency,
            'status' => $card->status,
            'expires_at' => $card->expires_at?->toIso8601String(),
            'customer' => $card->customer ? [
                'id' => $card->customer->id,
                'name' => $card->customer->name,
                'phone' => $card->customer->phone,
            ] : null,
            'message' => 'Gift card is active with available store credit.',
        ];
    }

    /**
     * Redeem an amount from the gift card for a sale.
     */
    public function redeemCard(
        string $code,
        float $amount,
        ?Sale $sale = null,
        ?Store $store = null,
        ?User $user = null,
        ?string $notes = null
    ): array {
        if ($amount <= 0) {
            throw new InvalidArgumentException('Redemption amount must be greater than zero.');
        }

        $normalizedCode = strtoupper(trim($code));

        return DB::transaction(function () use ($normalizedCode, $amount, $sale, $store, $user, $notes) {
            $card = GiftCard::where('code', $normalizedCode)->lockForUpdate()->first();

            if (!$card) {
                throw new InvalidArgumentException("Gift card [{$normalizedCode}] not found.");
            }

            if (!$card->isRedeemable()) {
                throw new InvalidArgumentException("Gift card [{$normalizedCode}] is not active or has zero balance.");
            }

            $currentBalance = (float) $card->balance;
            $redeemAmount = min($amount, $currentBalance);
            $newBalance = round($currentBalance - $redeemAmount, 2);

            $card->balance = $newBalance;
            if ($newBalance <= 0) {
                $card->status = 'redeemed';
            }
            $card->save();

            $tx = GiftCardTransaction::create([
                'gift_card_id' => $card->id,
                'sale_id' => $sale?->id,
                'store_id' => $store?->id ?? $sale?->store_id,
                'user_id' => $user?->id,
                'type' => 'redeem',
                'amount' => $redeemAmount,
                'balance_before' => $currentBalance,
                'balance_after' => $newBalance,
                'reference' => $sale?->invoice_number ?? 'POS_REDEMPTION',
                'notes' => $notes ?? 'Sale payment deduction',
            ]);

            return [
                'redeemed_amount' => $redeemAmount,
                'remaining_balance' => $newBalance,
                'transaction' => $tx,
                'card' => $card->fresh(),
            ];
        });
    }

    /**
     * Refund or credit back an amount to the gift card.
     */
    public function refundToCard(
        GiftCard $card,
        float $amount,
        ?Sale $sale = null,
        ?Store $store = null,
        ?User $user = null,
        ?string $notes = null
    ): GiftCardTransaction {
        if ($amount <= 0) {
            throw new InvalidArgumentException('Refund amount must be greater than zero.');
        }

        return DB::transaction(function () use ($card, $amount, $sale, $store, $user, $notes) {
            $lockedCard = GiftCard::where('id', $card->id)->lockForUpdate()->first();

            $before = (float) $lockedCard->balance;
            $after = round($before + $amount, 2);

            $lockedCard->balance = $after;
            if ($lockedCard->status === 'redeemed' && $after > 0) {
                $lockedCard->status = 'active';
            }
            $lockedCard->save();

            return GiftCardTransaction::create([
                'gift_card_id' => $lockedCard->id,
                'sale_id' => $sale?->id,
                'store_id' => $store?->id ?? $sale?->store_id,
                'user_id' => $user?->id,
                'type' => 'refund',
                'amount' => $amount,
                'balance_before' => $before,
                'balance_after' => $after,
                'reference' => $sale?->invoice_number ?? 'RETURN_REFUND',
                'notes' => $notes ?? 'Refund credit back to gift card',
            ]);
        });
    }
}
