<?php

namespace App\Models;

use App\Traits\HasUuid;
use App\Traits\TracksSyncVersion;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Customer extends Model
{
    use HasFactory, HasUuid, SoftDeletes, TracksSyncVersion;

    protected $fillable = [
        'uuid',
        'user_id',
        'name',
        'phone',
        'email',
        'address',
        'loyalty_points',
        'vip_tier',
        'total_spend',
        'tier_updated_at',
        'credit_limit',
        'balance',
        'version',
    ];

    protected $casts = [
        'loyalty_points' => 'integer',
        'total_spend' => 'decimal:2',
        'tier_updated_at' => 'datetime',
        'credit_limit' => 'decimal:2',
        'balance' => 'decimal:2',
        'version' => 'integer',
    ];

    protected $appends = [
        'tier_title',
        'tier_discount_percent',
        'points_multiplier',
    ];

    public function getTierTitleAttribute(): string
    {
        return match ($this->vip_tier) {
            'black' => 'Black Diamond',
            'gold' => 'Gold Elite',
            default => 'Silver Privilege',
        };
    }

    public function getTierDiscountPercentAttribute(): float
    {
        return match ($this->vip_tier) {
            'black' => 10.0,
            'gold' => 5.0,
            default => 0.0,
        };
    }

    public function getPointsMultiplierAttribute(): float
    {
        return match ($this->vip_tier) {
            'black' => 2.0,
            'gold' => 1.5,
            default => 1.0,
        };
    }

    public function sales(): HasMany
    {
        return $this->hasMany(Sale::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function deviceTokens(): HasMany
    {
        return $this->hasMany(CustomerDeviceToken::class);
    }

    public function notifications(): HasMany
    {
        return $this->hasMany(CustomerNotification::class);
    }

    /**
     * Private Reverb channel name (without the "private-" prefix).
     */
    public function broadcastChannelName(): string
    {
        return 'customer.'.$this->uuid;
    }
}
