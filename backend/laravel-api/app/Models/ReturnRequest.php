<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class ReturnRequest extends Model
{
    use HasFactory, HasUuid;

    protected $fillable = [
        'uuid',
        'request_number',
        'sale_id',
        'customer_id',
        'type',
        'status',
        'reason',
        'customer_notes',
        'staff_notes',
        'actioned_by',
        'actioned_at',
    ];

    protected $casts = [
        'actioned_at' => 'datetime',
    ];

    protected static function boot()
    {
        parent::boot();
        static::creating(function ($model) {
            if (empty($model->request_number)) {
                $model->request_number = 'RET-' . date('Ymd') . '-' . strtoupper(Str::random(5));
            }
        });
    }

    public function sale(): BelongsTo
    {
        return $this->belongsTo(Sale::class);
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(ReturnRequestItem::class);
    }

    public function staff(): BelongsTo
    {
        return $this->belongsTo(User::class, 'actioned_by');
    }
}
