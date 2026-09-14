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
                    'invoice_number' => 'OFFLINE-INV-' . Str::random(8),
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
}
