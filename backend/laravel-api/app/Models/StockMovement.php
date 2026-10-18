<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StockMovement extends Model
{
    use HasFactory, HasUuid;

    protected $fillable = [
        'uuid',
        'store_id',
        'product_id',
        'variant_id',
        'user_id',
        'type',
        'quantity',
        'before_quantity',
        'after_quantity',
        'reference_uuid',
        'notes',
    ];

    protected $casts = [
        'quantity' => 'decimal:3',
        'before_quantity' => 'decimal:3',
        'after_quantity' => 'decimal:3',
    ];

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function variant(): BelongsTo
    {
        return $this->belongsTo(ProductVariant::class, 'variant_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
