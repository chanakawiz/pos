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
        Schema::create('wishlist_items', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('customer_id')->nullable()->constrained('customers')->cascadeOnDelete();
            $table->string('session_token', 120)->nullable();
            $table->foreignId('product_id')->constrained('products')->cascadeOnDelete();
            $table->string('variant_label', 100)->nullable();
            $table->timestamps();

            $table->index(['customer_id', 'product_id']);
            $table->index(['session_token', 'product_id']);
        });

        Schema::create('back_in_stock_subscriptions', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('product_id')->constrained('products')->cascadeOnDelete();
            $table->foreignId('store_id')->nullable()->constrained('stores')->nullOnDelete();
            $table->foreignId('customer_id')->nullable()->constrained('customers')->nullOnDelete();
            $table->string('customer_name', 191)->nullable();
            $table->string('phone', 50)->nullable();
            $table->string('email', 191)->nullable();
            $table->enum('status', ['subscribed', 'notified', 'cancelled'])->default('subscribed');
            $table->timestamp('notified_at')->nullable();
            $table->timestamps();

            $table->index(['product_id', 'status']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('back_in_stock_subscriptions');
        Schema::dropIfExists('wishlist_items');
    }
};
