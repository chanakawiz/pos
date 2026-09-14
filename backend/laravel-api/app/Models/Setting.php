<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Setting extends Model
{
    use HasFactory;

    protected $fillable = [
        'store_id',
        'group',
        'key',
        'value',
        'is_public',
    ];

    protected $casts = [
        'is_public' => 'boolean',
    ];

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public static function get(string $key, ?int $storeId = null, $default = null)
    {
        $setting = static::where('key', $key)
            ->where(function ($q) use ($storeId) {
                if ($storeId) {
                    $q->where('store_id', $storeId)->orWhereNull('store_id');
                } else {
                    $q->whereNull('store_id');
                }
            })
            ->first();

        return $setting ? $setting->value : $default;
    }
}
