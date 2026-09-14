<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HeldBill extends Model
{
    use HasFactory, HasUuid;

    protected $fillable = [
        'uuid',
        'store_id',
        'device_id',
        'cashier_id',
        'customer_id',
        'hold_reference',
        'cart_items_json',
        'subtotal',
        'held_at',
    ];

    protected $casts = [
        'cart_items_json' => 'array',
        'subtotal' => 'decimal:2',
        'held_at' => 'datetime',
    ];

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class);
    }

    public function cashier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'cashier_id');
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }
}
