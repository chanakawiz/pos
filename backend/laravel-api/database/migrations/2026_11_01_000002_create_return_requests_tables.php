<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('return_requests', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->string('request_number', 50)->unique();
            $table->foreignId('sale_id')->constrained('sales')->cascadeOnDelete();
            $table->foreignId('customer_id')->nullable()->constrained('customers')->nullOnDelete();
            $table->enum('type', ['return', 'exchange', 'warranty_claim'])->default('return');
            $table->enum('status', ['pending', 'approved', 'rejected', 'completed'])->default('pending')->index();
            $table->string('reason', 100);
            $table->text('customer_notes')->nullable();
            $table->text('staff_notes')->nullable();
            $table->foreignId('actioned_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('actioned_at')->nullable();
            $table->timestamps();

            $table->index(['sale_id', 'status']);
        });

        Schema::create('return_request_items', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('return_request_id')->constrained('return_requests')->cascadeOnDelete();
            $table->foreignId('sale_item_id')->constrained('sale_items')->cascadeOnDelete();
            $table->decimal('quantity', 12, 3)->default(1.000);
            $table->enum('requested_action', ['refund', 'exchange_size', 'repair_warranty'])->default('refund');
            $table->string('item_condition', 50)->default('unopened'); // unopened, opened_unused, defective
            $table->string('replacement_notes', 255)->nullable(); // e.g. "Request UK 10 instead of UK 9"
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('return_request_items');
        Schema::dropIfExists('return_requests');
    }
};
