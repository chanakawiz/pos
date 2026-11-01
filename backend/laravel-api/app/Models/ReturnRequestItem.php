<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ReturnRequestItem extends Model
{
    use HasFactory, HasUuid;

    protected $fillable = [
        'uuid',
        'return_request_id',
        'sale_item_id',
        'quantity',
        'requested_action',
        'item_condition',
        'replacement_notes',
    ];

    protected $casts = [
        'quantity' => 'decimal:3',
    ];

    public function returnRequest(): BelongsTo
    {
        return $this->belongsTo(ReturnRequest::class);
    }

    public function saleItem(): BelongsTo
    {
        return $this->belongsTo(SaleItem::class);
    }
}
