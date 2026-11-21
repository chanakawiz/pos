<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Stocktake extends Model
{
    use HasFactory, HasUuid;

    protected $fillable = [
        'uuid',
        'stocktake_number',
        'store_id',
        'user_id',
        'status',
        'total_items_counted',
        'variance_items_count',
        'net_quantity_variance',
        'net_value_variance',
        'notes',
        'started_at',
        'completed_at',
    ];

    protected $casts = [
        'net_quantity_variance' => 'decimal:3',
        'net_value_variance' => 'decimal:2',
        'started_at' => 'datetime',
        'completed_at' => 'datetime',
    ];

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(StocktakeItem::class);
    }
}
