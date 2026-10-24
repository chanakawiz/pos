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
        'credit_limit',
        'balance',
        'version',
    ];

    protected $casts = [
        'loyalty_points' => 'integer',
        'credit_limit' => 'decimal:2',
        'balance' => 'decimal:2',
        'version' => 'integer',
    ];

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
