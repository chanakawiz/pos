<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class GiftCardTransaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'uuid',
        'gift_card_id',
        'sale_id',
        'store_id',
        'user_id',
        'type',
        'amount',
        'balance_before',
        'balance_after',
        'reference',
        'notes',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'balance_before' => 'decimal:2',
        'balance_after' => 'decimal:2',
    ];

    protected static function boot(): void
    {
        parent::boot();

        static::creating(function (GiftCardTransaction $tx) {
            if (empty($tx->uuid)) {
                $tx->uuid = (string) Str::uuid();
            }
        });
    }

    public function giftCard(): BelongsTo
    {
        return $this->belongsTo(GiftCard::class);
    }

    public function sale(): BelongsTo
    {
        return $this->belongsTo(Sale::class);
    }

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
