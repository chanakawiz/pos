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
        Schema::table('users', function (Blueprint $table) {
            $table->decimal('commission_rate', 5, 2)->default(2.50)->after('role');
            $table->decimal('monthly_sales_target', 12, 2)->default(500000.00)->after('commission_rate');
        });

        Schema::create('staff_commissions', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('store_id')->constrained('stores')->cascadeOnDelete();
            $table->foreignId('sale_id')->nullable()->constrained('sales')->nullOnDelete();
            $table->decimal('sale_amount', 12, 2);
            $table->decimal('commission_rate', 5, 2);
            $table->decimal('commission_amount', 12, 2);
            $table->enum('status', ['pending', 'approved', 'paid', 'reversed'])->default('pending');
            $table->string('notes', 255)->nullable();
            $table->timestamp('earned_at')->useCurrent();
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status', 'earned_at']);
            $table->index(['store_id', 'earned_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('staff_commissions');

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['commission_rate', 'monthly_sales_target']);
        });
    }
};
