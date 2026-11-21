<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StocktakeItem extends Model
{
    use HasFactory, HasUuid;

    protected $fillable = [
        'uuid',
        'stocktake_id',
        'product_id',
        'variant_id',
        'expected_quantity',
        'counted_quantity',
        'variance_quantity',
        'unit_cost',
        'variance_value',
        'notes',
    ];

    protected $casts = [
        'expected_quantity' => 'decimal:3',
        'counted_quantity' => 'decimal:3',
        'variance_quantity' => 'decimal:3',
        'unit_cost' => 'decimal:2',
        'variance_value' => 'decimal:2',
    ];

    public function stocktake(): BelongsTo
    {
        return $this->belongsTo(Stocktake::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function variant(): BelongsTo
    {
        return $this->belongsTo(ProductVariant::class);
    }
}
