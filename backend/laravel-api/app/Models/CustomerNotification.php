<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CustomerNotification extends Model
{
    use HasUuid;

    public const TYPE_ORDER = 'order';
    public const TYPE_LOYALTY = 'loyalty';
    public const TYPE_PROMO = 'promo';
    public const TYPE_SYSTEM = 'system';

    protected $fillable = ['uuid', 'customer_id', 'type', 'title', 'body', 'data', 'read_at'];

    protected $casts = [
        'data' => 'array',
        'read_at' => 'datetime',
    ];

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function scopeUnread(Builder $query): Builder
    {
        return $query->whereNull('read_at');
    }

    /**
     * Public projection shared by the REST API, Reverb payloads and FCM data.
     * Never includes internal ids, cost data or staff identities.
     */
    public function toClientArray(): array
    {
        return [
            'uuid' => $this->uuid,
            'type' => $this->type,
            'title' => $this->title,
            'body' => $this->body,
            'data' => $this->data ?? (object) [],
            'read' => $this->read_at !== null,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
