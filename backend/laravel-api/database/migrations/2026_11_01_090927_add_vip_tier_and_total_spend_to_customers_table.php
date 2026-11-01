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
        Schema::table('customers', function (Blueprint $table) {
            $table->string('vip_tier', 20)->default('silver')->index()->after('loyalty_points');
            $table->decimal('total_spend', 14, 2)->default(0.00)->after('vip_tier');
            $table->timestamp('tier_updated_at')->nullable()->after('total_spend');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('customers', function (Blueprint $table) {
            $table->dropColumn(['vip_tier', 'total_spend', 'tier_updated_at']);
        });
    }
};
