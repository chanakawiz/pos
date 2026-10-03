<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->string('warranty_period', 100)->nullable()->after('unit');
            $table->boolean('requires_serial')->default(false)->after('warranty_period');
        });

        Schema::table('sale_items', function (Blueprint $table) {
            $table->string('serial_number', 100)->nullable()->after('quantity');
            $table->string('warranty_notes', 255)->nullable()->after('serial_number');
        });
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropColumn(['warranty_period', 'requires_serial']);
        });

        Schema::table('sale_items', function (Blueprint $table) {
            $table->dropColumn(['serial_number', 'warranty_notes']);
        });
    }
};
