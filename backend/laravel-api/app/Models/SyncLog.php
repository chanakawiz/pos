<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SyncLog extends Model
{
    use HasFactory, HasUuid;

    protected $fillable = [
        'uuid',
        'device_id',
        'sync_type',
        'batch_size',
        'status',
        'error_details',
        'synced_at',
    ];

    protected $casts = [
        'batch_size' => 'integer',
        'synced_at' => 'datetime',
    ];

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class);
    }
}
