<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('eod_reports', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('store_id')->constrained('stores')->cascadeOnDelete();
            $table->date('report_date');
            $table->foreignId('generated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->integer('closed_sessions_count')->default(0);
            $table->decimal('total_opening_float', 12, 2)->default(0.00);
            $table->decimal('total_cash_sales', 12, 2)->default(0.00);
            $table->decimal('total_card_sales', 12, 2)->default(0.00);
            $table->decimal('total_gift_card_sales', 12, 2)->default(0.00);
            $table->decimal('gross_sales', 12, 2)->default(0.00);
            $table->decimal('total_discounts', 12, 2)->default(0.00);
            $table->decimal('total_refunds', 12, 2)->default(0.00);
            $table->decimal('net_sales', 12, 2)->default(0.00);
            $table->decimal('expected_cash', 12, 2)->default(0.00);
            $table->decimal('actual_closing_cash', 12, 2)->default(0.00);
            $table->decimal('net_discrepancy', 12, 2)->default(0.00);
            $table->boolean('is_automated')->default(false);
            $table->json('breakdown_json')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['store_id', 'report_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('eod_reports');
    }
};
