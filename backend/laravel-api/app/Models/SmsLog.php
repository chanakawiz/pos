<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SmsLog extends Model
{
    use HasFactory, HasUuid;

    protected $fillable = [
        'uuid',
        'store_id',
        'customer_id',
        'sale_id',
        'recipient_phone',
        'masked_phone',
        'message',
        'driver',
        'status',
        'event_type',
        'gateway_reference',
        'cost',
        'error_message',
        'metadata',
        'sent_at',
    ];

    protected $casts = [
        'cost' => 'decimal:4',
        'metadata' => 'array',
        'sent_at' => 'datetime',
    ];

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function sale(): BelongsTo
    {
        return $this->belongsTo(Sale::class);
    }
}
