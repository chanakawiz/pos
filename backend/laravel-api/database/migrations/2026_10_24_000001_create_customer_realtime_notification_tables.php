<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Customer real-time messaging foundation (single central database).
 *
 * - customers.user_id: hard link between a login account and its customer
 *   profile. Private WebSocket channels and notification APIs authorize on
 *   this FK only (never on name/email guessing).
 * - customer_device_tokens: Firebase FCM registration tokens per device.
 * - customer_notifications: persisted notification inbox. Reverb and FCM are
 *   delivery transports only; this table is the source of truth that the web
 *   store and mobile app read from.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('customers', function (Blueprint $table) {
            $table->foreignId('user_id')
                ->nullable()
                ->after('uuid')
                ->unique()
                ->constrained('users')
                ->nullOnDelete();
        });

        // Backfill: link existing customer-role accounts by exact email match.
        $customerUsers = DB::table('users')->where('role', 'customer')->get(['id', 'email']);
        foreach ($customerUsers as $user) {
            DB::table('customers')
                ->whereNull('user_id')
                ->where('email', $user->email)
                ->orderBy('id')
                ->limit(1)
                ->update(['user_id' => $user->id]);
        }

        Schema::create('customer_device_tokens', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained('customers')->cascadeOnDelete();
            $table->string('token', 512)->unique();
            $table->string('platform', 20); // ios | android | web
            $table->timestamp('last_seen_at')->nullable();
            $table->timestamps();

            $table->index(['customer_id', 'platform']);
        });

        Schema::create('customer_notifications', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('customer_id')->constrained('customers')->cascadeOnDelete();
            $table->string('type', 30); // order | loyalty | promo | system
            $table->string('title', 150);
            $table->string('body', 500);
            $table->json('data')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamps();

            $table->index(['customer_id', 'read_at']);
            $table->index(['customer_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('customer_notifications');
        Schema::dropIfExists('customer_device_tokens');

        Schema::table('customers', function (Blueprint $table) {
            $table->dropConstrainedForeignId('user_id');
        });
    }
};
