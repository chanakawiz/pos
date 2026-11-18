<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class EodReport extends Model
{
    use HasFactory, HasUuid;

    protected $fillable = [
        'uuid',
        'store_id',
        'report_date',
        'generated_by',
        'closed_sessions_count',
        'total_opening_float',
        'total_cash_sales',
        'total_card_sales',
        'total_gift_card_sales',
        'gross_sales',
        'total_discounts',
        'total_refunds',
        'net_sales',
        'expected_cash',
        'actual_closing_cash',
        'net_discrepancy',
        'is_automated',
        'breakdown_json',
        'notes',
    ];

    protected $casts = [
        'report_date' => 'date',
        'total_opening_float' => 'decimal:2',
        'total_cash_sales' => 'decimal:2',
        'total_card_sales' => 'decimal:2',
        'total_gift_card_sales' => 'decimal:2',
        'gross_sales' => 'decimal:2',
        'total_discounts' => 'decimal:2',
        'total_refunds' => 'decimal:2',
        'net_sales' => 'decimal:2',
        'expected_cash' => 'decimal:2',
        'actual_closing_cash' => 'decimal:2',
        'net_discrepancy' => 'decimal:2',
        'is_automated' => 'boolean',
        'breakdown_json' => 'array',
    ];

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public function generatedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'generated_by');
    }

    public function scopeForStore($query, int $storeId)
    {
        return $query->where('store_id', $storeId);
    }

    public function scopeForDate($query, $date)
    {
        return $query->whereDate('report_date', $date);
    }
}
