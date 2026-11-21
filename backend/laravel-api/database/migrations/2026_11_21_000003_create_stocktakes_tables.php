<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('stocktakes', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->string('stocktake_number', 64)->unique();
            $table->foreignId('store_id')->constrained('stores')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->enum('status', ['in_progress', 'completed', 'cancelled'])->default('in_progress');
            $table->unsignedInteger('total_items_counted')->default(0);
            $table->unsignedInteger('variance_items_count')->default(0);
            $table->decimal('net_quantity_variance', 12, 3)->default(0.000);
            $table->decimal('net_value_variance', 12, 2)->default(0.00);
            $table->text('notes')->nullable();
            $table->timestamp('started_at')->useCurrent();
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();

            $table->index(['store_id', 'status']);
        });

        Schema::create('stocktake_items', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('stocktake_id')->constrained('stocktakes')->cascadeOnDelete();
            $table->foreignId('product_id')->constrained('products')->cascadeOnDelete();
            $table->foreignId('variant_id')->nullable()->constrained('product_variants')->nullOnDelete();
            $table->decimal('expected_quantity', 12, 3)->default(0.000);
            $table->decimal('counted_quantity', 12, 3)->default(0.000);
            $table->decimal('variance_quantity', 12, 3)->default(0.000);
            $table->decimal('unit_cost', 12, 2)->default(0.00);
            $table->decimal('variance_value', 12, 2)->default(0.00);
            $table->string('notes', 255)->nullable();
            $table->timestamps();

            $table->unique(['stocktake_id', 'product_id', 'variant_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('stocktake_items');
        Schema::dropIfExists('stocktakes');
    }
};
