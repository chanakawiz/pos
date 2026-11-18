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
        Schema::create('sms_logs', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('store_id')->nullable()->constrained('stores')->nullOnDelete();
            $table->foreignId('customer_id')->nullable()->constrained('customers')->nullOnDelete();
            $table->foreignId('sale_id')->nullable()->constrained('sales')->nullOnDelete();
            $table->string('recipient_phone', 32);
            $table->string('masked_phone', 32);
            $table->text('message');
            $table->string('driver', 32)->default('log');
            $table->string('status', 32)->default('queued'); // queued, sent, failed, delivered
            $table->string('event_type', 64)->default('custom'); // pos_receipt, web_order, order_dispatched, order_delivered, vip_upgrade, rma_update
            $table->string('gateway_reference')->nullable();
            $table->decimal('cost', 8, 4)->default(0.0000);
            $table->text('error_message')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamp('sent_at')->nullable();
            $table->timestamps();

            $table->index(['store_id', 'status']);
            $table->index(['recipient_phone', 'status']);
            $table->index('event_type');
            $table->index('created_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('sms_logs');
    }
};
