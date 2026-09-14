<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inventory', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('store_id')->constrained('stores')->cascadeOnDelete();
            $table->foreignId('product_id')->constrained('products')->cascadeOnDelete();
            $table->foreignId('variant_id')->nullable()->constrained('product_variants')->cascadeOnDelete();
            $table->decimal('quantity_on_hand', 12, 2)->default(0.00);
            $table->decimal('quantity_reserved', 12, 2)->default(0.00);
            $table->timestamps();

            $table->unique(['store_id', 'product_id', 'variant_id'], 'store_product_variant_unique');
        });

        Schema::create('stock_movements', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('store_id')->constrained('stores')->cascadeOnDelete();
            $table->foreignId('product_id')->constrained('products')->cascadeOnDelete();
            $table->foreignId('variant_id')->nullable()->constrained('product_variants')->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->enum('type', ['sale', 'refund', 'purchase', 'adjustment', 'transfer_in', 'transfer_out', 'damaged']);
            $table->decimal('quantity', 12, 2);
            $table->decimal('before_quantity', 12, 2);
            $table->decimal('after_quantity', 12, 2);
            $table->string('reference_uuid', 100)->nullable()->index();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['store_id', 'product_id', 'type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('stock_movements');
        Schema::dropIfExists('inventory');
    }
};
