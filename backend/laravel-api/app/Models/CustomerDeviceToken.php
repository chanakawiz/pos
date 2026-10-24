<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CustomerDeviceToken extends Model
{
    protected $fillable = ['customer_id', 'token', 'platform', 'last_seen_at'];

    protected $hidden = ['token'];

    protected $casts = ['last_seen_at' => 'datetime'];

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }
}
