<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    private const COLUMNS = [
        'inventory' => ['quantity_on_hand', 'quantity_reserved'],
        'stock_movements' => ['quantity', 'before_quantity', 'after_quantity'],
        'sale_items' => ['quantity'],
        'refund_items' => ['quantity'],
        'purchase_items' => ['quantity'],
    ];

    public function up(): void
    {
        $this->changePrecision(15, 3);
    }

    public function down(): void
    {
        // Refuse a rollback that would silently round sold/refunded or audited stock.
        foreach (self::COLUMNS as $table => $columns) {
            foreach ($columns as $column) {
                if (DB::table($table)->whereRaw("ABS({$column} - ROUND({$column}, 2)) > 0.000001")
                    ->orWhereRaw("ABS({$column}) > 9999999999.99")->exists()) {
                    throw new RuntimeException('Cannot reduce quantity precision while three-decimal or expanded-range data exists.');
                }
            }
        }
        $this->changePrecision(12, 2);
    }

    private function changePrecision(int $precision, int $scale): void
    {
        foreach (self::COLUMNS as $name => $columns) {
            Schema::table($name, function (Blueprint $table) use ($name, $columns, $precision, $scale) {
                foreach ($columns as $column) {
                    $definition = $table->decimal($column, $precision, $scale);
                    if ($name === 'inventory') {
                        $definition->default(0);
                    }
                    $definition->change();
                }
            });
        }
    }
};
