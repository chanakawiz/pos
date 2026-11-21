<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StaffCommission extends Model
{
    use HasFactory, HasUuid;

    protected $fillable = [
        'uuid',
        'user_id',
        'store_id',
        'sale_id',
        'sale_amount',
        'commission_rate',
        'commission_amount',
        'status',
        'notes',
        'earned_at',
        'paid_at',
    ];

    protected $casts = [
        'sale_amount' => 'decimal:2',
        'commission_rate' => 'decimal:2',
        'commission_amount' => 'decimal:2',
        'earned_at' => 'datetime',
        'paid_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public function sale(): BelongsTo
    {
        return $this->belongsTo(Sale::class);
    }
}
