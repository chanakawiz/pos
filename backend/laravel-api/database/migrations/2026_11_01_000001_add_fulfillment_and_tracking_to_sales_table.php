<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('sales', function (Blueprint $table) {
            $table->enum('fulfillment_status', [
                'unfulfilled',
                'processing',
                'packed',
                'dispatched',
                'delivered',
                'returned'
            ])->default('unfulfilled')->after('payment_status');

            $table->string('courier_name', 100)->nullable()->after('fulfillment_status');
            $table->string('tracking_number', 100)->nullable()->index()->after('courier_name');
            $table->timestamp('estimated_delivery_at')->nullable()->after('tracking_number');
            $table->timestamp('dispatched_at')->nullable()->after('estimated_delivery_at');
            $table->timestamp('delivered_at')->nullable()->after('dispatched_at');

            $table->index(['fulfillment_status', 'sold_at']);
        });
    }

    public function down(): void
    {
        Schema::table('sales', function (Blueprint $table) {
            $table->dropIndex(['fulfillment_status', 'sold_at']);
            $table->dropColumn([
                'fulfillment_status',
                'courier_name',
                'tracking_number',
                'estimated_delivery_at',
                'dispatched_at',
                'delivered_at',
            ]);
        });
    }
};
