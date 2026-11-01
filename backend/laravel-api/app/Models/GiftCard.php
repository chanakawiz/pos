<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class GiftCard extends Model
{
    use HasFactory;

    protected $fillable = [
        'uuid',
        'code',
        'pin_hash',
        'initial_amount',
        'balance',
        'currency',
        'status',
        'customer_id',
        'store_id',
        'issued_by',
        'expires_at',
        'notes',
    ];

    protected $casts = [
        'initial_amount' => 'decimal:2',
        'balance' => 'decimal:2',
        'expires_at' => 'datetime',
    ];

    protected static function boot(): void
    {
        parent::boot();

        static::creating(function (GiftCard $card) {
            if (empty($card->uuid)) {
                $card->uuid = (string) Str::uuid();
            }
            if (empty($card->code)) {
                $card->code = self::generateUniqueCode();
            }
        });
    }

    /**
     * Generate an elegant boutique alphanumeric gift card code: GC-XXXX-XXXX-XXXX
     */
    public static function generateUniqueCode(): string
    {
        do {
            $p1 = strtoupper(Str::random(4));
            $p2 = strtoupper(Str::random(4));
            $p3 = strtoupper(Str::random(4));
            $code = "GC-{$p1}-{$p2}-{$p3}";
        } while (self::where('code', $code)->exists());

        return $code;
    }

    public function isRedeemable(): bool
    {
        if ($this->status !== 'active') {
            return false;
        }

        if ((float) $this->balance <= 0) {
            return false;
        }

        if ($this->expires_at && $this->expires_at->isPast()) {
            return false;
        }

        return true;
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public function issuer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'issued_by');
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(GiftCardTransaction::class)->orderByDesc('id');
    }
}
