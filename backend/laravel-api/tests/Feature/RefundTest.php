<?php

namespace Tests\Feature;

use App\Models\Inventory;
use App\Models\Product;
use App\Models\Sale;
use App\Models\StockMovement;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Str;
use Tests\TestCase;

class RefundTest extends TestCase
{
    use DatabaseTransactions;

    public function test_can_process_refund_and_restock_inventory(): void
    {
        $cashier = User::where('email', 'cashier1@smartshop.com')->first();
        $product = Product::first();
        $store = $cashier->store;

        // 1. Create a sale with 2 items
        $sellQty = 2.00;
        $unitPrice = (float) $product->selling_price;
        $taxRate = (float) $product->tax_rate;
        $subtotal = $sellQty * $unitPrice;
        $tax = round(($subtotal * $taxRate) / 100, 2);
        $total = $subtotal + $tax;

        $saleResponse = $this->actingAs($cashier)->postJson('/api/v1/sales', [
            'transaction_uuid' => (string) Str::uuid(),
            'items' => [
                [
                    'product_id' => $product->id,
                    'quantity' => $sellQty,
                    'unit_price' => $unitPrice,
                ],
            ],
            'payments' => [
                [
                    'payment_method' => 'cash',
                    'amount' => $total,
                ],
            ],
        ]);

        $saleResponse->assertStatus(201);
        $saleUuid = $saleResponse->json('sale.uuid');
        $saleItemId = $saleResponse->json('sale.items.0.id');

        $stockBeforeRefund = (float) Inventory::where('store_id', $store->id)
            ->where('product_id', $product->id)
            ->value('quantity_on_hand');

        // 2. Refund 1 quantity of the item
        $refundResponse = $this->actingAs($cashier)->postJson("/api/v1/sales/{$saleUuid}/refund", [
            'items' => [
                [
                    'sale_item_id' => $saleItemId,
                    'quantity' => 1.00,
                ],
            ],
            'reason' => 'Customer changed mind',
            'restock' => true,
        ]);

        $refundResponse->assertStatus(201)
            ->assertJsonPath('status', 'success')
            ->assertJsonStructure([
                'status',
                'refund' => ['id', 'uuid', 'refund_number', 'amount', 'reason', 'items'],
                'receipt' => ['refund_number', 'invoice_number', 'total_refunded'],
            ]);

        // 3. Verify Inventory was incremented by 1
        $stockAfterRefund = (float) Inventory::where('store_id', $store->id)
            ->where('product_id', $product->id)
            ->value('quantity_on_hand');

        $this->assertEquals($stockBeforeRefund + 1.00, $stockAfterRefund);

        // 4. Verify StockMovement was recorded
        $movement = StockMovement::where('type', 'refund')
            ->where('product_id', $product->id)
            ->latest('id')
            ->first();

        $this->assertNotNull($movement);
        $this->assertEquals(1.00, (float) $movement->quantity);

        // 5. Verify attempting to refund more than remaining returns 422
        $excessiveRefundResponse = $this->actingAs($cashier)->postJson("/api/v1/sales/{$saleUuid}/refund", [
            'items' => [
                [
                    'sale_item_id' => $saleItemId,
                    'quantity' => 5.00, // Only 1 remains
                ],
            ],
            'reason' => 'Over refund test',
        ]);

        $excessiveRefundResponse->assertStatus(422)
            ->assertJsonPath('status', 'error');
    }

    public function test_can_list_refunds(): void
    {
        $cashier = User::where('email', 'cashier1@smartshop.com')->first();

        $response = $this->actingAs($cashier)->getJson('/api/v1/refunds');

        $response->assertStatus(200)
            ->assertJsonStructure(['data']);
    }
}
