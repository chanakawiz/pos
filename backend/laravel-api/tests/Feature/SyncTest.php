<?php

namespace Tests\Feature;

use App\Models\Device;
use App\Models\Product;
use App\Models\Sale;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Str;
use Tests\TestCase;

class SyncTest extends TestCase
{
    use DatabaseTransactions;

    public function test_can_push_offline_transactions_and_prevent_duplicate_on_retry(): void
    {
        $cashier = User::where('email', 'cashier1@smartshop.com')->first();
        $device = Device::first();
        $product = Product::first();

        $txUuid = (string) Str::uuid();

        $payload = [
            'device_uuid' => $device->uuid,
            'transactions' => [
                [
                    'transaction_uuid' => $txUuid,
                    'invoice_number' => 'OFFLINE-INV-'.Str::random(8),
                    'cashier_uuid' => $cashier->uuid,
                    'subtotal' => 20.00,
                    'discount_amount' => 0.00,
                    'tax_amount' => 1.00,
                    'total_amount' => 21.00,
                    'paid_amount' => 21.00,
                    'change_amount' => 0.00,
                    'sold_at' => now()->toIso8601String(),
                    'items' => [
                        [
                            'product_id' => $product->id,
                            'quantity' => 1,
                            'unit_price' => 20.00,
                        ],
                    ],
                    'payments' => [
                        [
                            'payment_method' => 'cash',
                            'amount' => 21.00,
                        ],
                    ],
                ],
            ],
        ];

        // 1. First push
        $response1 = $this->actingAs($cashier)
            ->postJson('/api/v1/sync/push', $payload);

        $response1->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('synced_count', 1);

        $this->assertEquals(1, Sale::where('transaction_uuid', $txUuid)->count());

        // 2. Retry push with same payload
        $response2 = $this->actingAs($cashier)
            ->postJson('/api/v1/sync/push', $payload);

        $response2->assertStatus(200)
            ->assertJsonPath('status', 'success');

        // Verify no duplicate record created
        $this->assertEquals(1, Sale::where('transaction_uuid', $txUuid)->count());
    }

    public function test_can_pull_delta_catalog_updates(): void
    {
        $cashier = User::where('email', 'cashier1@smartshop.com')->first();
        $device = Device::first();

        $response = $this->actingAs($cashier)
            ->getJson("/api/v1/sync/pull?device_uuid={$device->uuid}&since_version=0");

        $response->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonStructure([
                'current_version',
                'products',
                'categories',
                'customers',
            ]);
    }

    public function test_offline_sync_preserves_receipt_tax_snapshot_and_reports_invalid_sales_individually(): void
    {
        $cashier = User::where('email', 'cashier1@smartshop.com')->firstOrFail();
        $device = Device::where('store_id', $cashier->store_id)->firstOrFail();
        $product = Product::firstOrFail();
        $product->update(['tax_rate' => 20]);
        $uuid = (string) Str::uuid();
        $invalidUuid = (string) Str::uuid();
        $transaction = [
            'transaction_uuid' => $uuid,
            'cashier_uuid' => $cashier->uuid,
            'items' => [['product_uuid' => $product->uuid, 'quantity' => 2, 'unit_price' => 10.05, 'tax_rate' => 5]],
            'payments' => [['payment_method' => 'cash', 'amount' => 25]],
        ];

        $this->actingAs($cashier)->postJson('/api/v1/sync/push', [
            'device_uuid' => $device->uuid,
            'transactions' => [$transaction, array_merge($transaction, ['transaction_uuid' => $invalidUuid, 'items' => []])],
        ])->assertOk()->assertJsonPath('synced_count', 1)
            ->assertJsonPath('synced_uuids.0', $uuid)
            ->assertJsonPath('failed_uuids.0.uuid', $invalidUuid);

        $sale = Sale::where('transaction_uuid', $uuid)->firstOrFail();
        $this->assertSame(21.11, (float) $sale->total_amount);
        $this->assertSame(3.89, (float) $sale->change_amount);
        $this->assertFalse(Sale::where('transaction_uuid', $invalidUuid)->exists());

        // Online billing continues to use the authoritative catalog rate.
        $transaction['transaction_uuid'] = (string) Str::uuid();
        $this->actingAs($cashier)->postJson('/api/v1/sales', $transaction)
            ->assertCreated()->assertJsonPath('sale.total_amount', 24.12);
    }
}
