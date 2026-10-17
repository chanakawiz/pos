<?php

namespace App\Models;

use App\Traits\HasUuid;
use App\Traits\TracksSyncVersion;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Category extends Model
{
    use HasFactory, HasUuid, SoftDeletes, TracksSyncVersion;

    protected $fillable = [
        'uuid',
        'parent_id',
        'name',
        'slug',
        'image_path',
        'display_order',
        'is_active',
        'version',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'display_order' => 'integer',
        'version' => 'integer',
    ];

    public function parent(): BelongsTo
    {
        return $this->belongsTo(Category::class, 'parent_id');
    }

    public function children(): HasMany
    {
        return $this->hasMany(Category::class, 'parent_id');
    }

    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }
}
