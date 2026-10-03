<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Product extends Model
{
    use HasFactory, HasUuid, SoftDeletes;

    protected $fillable = [
        'uuid',
        'category_id',
        'brand_id',
        'name',
        'sinhala_name',
        'sku',
        'barcode',
        'description',
        'unit',
        'warranty_period',
        'requires_serial',
        'cost_price',
        'selling_price',
        'tax_rate',
        'min_stock_level',
        'image_path',
        'has_variants',
        'is_active',
        'version',
    ];

    protected $casts = [
        'requires_serial' => 'boolean',
        'cost_price' => 'decimal:2',
        'selling_price' => 'decimal:2',
        'tax_rate' => 'decimal:2',
        'min_stock_level' => 'integer',
        'has_variants' => 'boolean',
        'is_active' => 'boolean',
        'version' => 'integer',
    ];

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function brand(): BelongsTo
    {
        return $this->belongsTo(Brand::class);
    }

    public function variants(): HasMany
    {
        return $this->hasMany(ProductVariant::class);
    }

    public function inventories(): HasMany
    {
        return $this->hasMany(Inventory::class);
    }

    public function stockMovements(): HasMany
    {
        return $this->hasMany(StockMovement::class);
    }

    public function saleItems(): HasMany
    {
        return $this->hasMany(SaleItem::class);
    }

    public function getStockForStore(int $storeId): float
    {
        return (float) $this->inventories()->where('store_id', $storeId)->sum('quantity_on_hand');
    }
}
