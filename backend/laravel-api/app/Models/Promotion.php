<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Promotion extends Model
{
    use HasFactory, HasUuid;

    protected $fillable = [
        'uuid',
        'code',
        'name',
        'description',
        'type',
        'value',
        'buy_quantity',
        'get_quantity',
        'min_order_amount',
        'max_discount_amount',
        'max_uses',
        'max_uses_per_customer',
        'uses_count',
        'allowed_channels',
        'applicable_category_id',
        'vip_tier_required',
        'is_auto_apply',
        'is_active',
        'starts_at',
        'ends_at',
    ];

    protected $casts = [
        'value' => 'decimal:2',
        'min_order_amount' => 'decimal:2',
        'max_discount_amount' => 'decimal:2',
        'allowed_channels' => 'array',
        'is_auto_apply' => 'boolean',
        'is_active' => 'boolean',
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
    ];

    public function setCodeAttribute(string $value): void
    {
        $this->attributes['code'] = strtoupper(trim($value));
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class, 'applicable_category_id');
    }

    public function redemptions(): HasMany
    {
        return $this->hasMany(PromotionRedemption::class);
    }

    public function scopeLive($query)
    {
        $now = now();

        return $query->where('is_active', true)
            ->where(fn ($q) => $q->whereNull('starts_at')->orWhere('starts_at', '<=', $now))
            ->where(fn ($q) => $q->whereNull('ends_at')->orWhere('ends_at', '>=', $now))
            ->where(fn ($q) => $q->whereNull('max_uses')->orWhereColumn('uses_count', '<', 'max_uses'));
    }

    public function getDiscountLabelAttribute(): string
    {
        return match ($this->type) {
            'percentage' => rtrim(rtrim((string) $this->value, '0'), '.') . '% OFF',
            'fixed_amount' => 'LKR ' . number_format((float) $this->value, 0) . ' OFF',
            'buy_x_get_y' => "Buy {$this->buy_quantity} Get {$this->get_quantity} Free",
            default => 'Promo',
        };
    }
}
