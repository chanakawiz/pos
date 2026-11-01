<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StockTransferItem extends Model
{
    use HasFactory, HasUuid;

    protected $fillable = [
        'uuid',
        'stock_transfer_id',
        'product_id',
        'variant_id',
        'quantity_requested',
        'quantity_sent',
        'quantity_received',
    ];

    protected $casts = [
        'quantity_requested' => 'decimal:3',
        'quantity_sent' => 'decimal:3',
        'quantity_received' => 'decimal:3',
    ];

    public function transfer(): BelongsTo
    {
        return $this->belongsTo(StockTransfer::class, 'stock_transfer_id');
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
