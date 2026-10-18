<?php

namespace App\Models;

use App\Services\SyncRevision;
use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Inventory extends Model
{
    use HasFactory, HasUuid;

    protected $table = 'inventory';

    protected $fillable = [
        'uuid',
        'store_id',
        'product_id',
        'variant_id',
        'quantity_on_hand',
        'quantity_reserved',
    ];

    protected $casts = [
        'quantity_on_hand' => 'decimal:3',
        'quantity_reserved' => 'decimal:3',
    ];

    public function save(array $options = [])
    {
        return $this->getConnection()->transaction(function () use ($options) {
            $version = SyncRevision::next($this->getConnection());
            $productIds = array_filter([$this->getOriginal('product_id'), $this->product_id]);
            $saved = parent::save($options);
            if ($saved) {
                $this->getConnection()->table('products')->whereIn('id', $productIds)->update(['version' => $version]);
            }

            return $saved;
        });
    }

    public function delete()
    {
        return $this->getConnection()->transaction(function () {
            $version = SyncRevision::next($this->getConnection());
            $deleted = parent::delete();
            if ($deleted) {
                $this->getConnection()->table('products')->where('id', $this->product_id)->update(['version' => $version]);
            }

            return $deleted;
        });
    }

    protected function incrementOrDecrement($column, $amount, $extra, $method)
    {
        return $this->getConnection()->transaction(function () use ($column, $amount, $extra, $method) {
            $version = SyncRevision::next($this->getConnection());
            $result = parent::incrementOrDecrement($column, $amount, $extra, $method);
            if ($result) {
                $this->getConnection()->table('products')->where('id', $this->product_id)->update(['version' => $version]);
            }

            return $result;
        });
    }

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function variant(): BelongsTo
    {
        return $this->belongsTo(ProductVariant::class, 'variant_id');
    }
}
