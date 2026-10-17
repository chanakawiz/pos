<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sync_revisions', function (Blueprint $table) {
            $table->unsignedTinyInteger('id')->primary();
            $table->unsignedBigInteger('version');
        });

        Schema::create('sync_tombstones', function (Blueprint $table) {
            $table->string('entity_type', 32);
            $table->uuid('entity_uuid');
            $table->unsignedBigInteger('version')->index();
            $table->timestamp('deleted_at');
            $table->primary(['entity_type', 'entity_uuid']);
        });

        // Re-baseline existing records beyond every legacy per-record checkpoint.
        DB::transaction(function () {
            $tables = ['products', 'categories', 'customers'];
            $version = max(array_map(fn ($table) => (int) DB::table($table)->max('version'), $tables)) + 1;
            DB::table('sync_revisions')->insert(['id' => 1, 'version' => $version]);
            foreach ($tables as $table) {
                DB::table($table)->update(['version' => $version]);
            }
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sync_tombstones');
        Schema::dropIfExists('sync_revisions');
    }
};
