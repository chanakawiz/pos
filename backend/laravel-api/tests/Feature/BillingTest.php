<?php

namespace Tests\Feature;

use App\Models\Inventory;
use App\Models\Product;
use App\Models\StockMovement;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Str;
use Tests\TestCase;

class BillingTest extends TestCase
{
    use DatabaseTransactions;
    public function test_can_process_online_sale_and_deduct_inventory(): void
    {
        $cashier = User::where('email', 'cashier1@smartshop.com')->first();
        $product = Product::first();
        $store = $cashier->store;

        $initialInventory = Inventory::where('store_id', $store->id)
            ->where('product_id', $product->id)
            ->first();

        $initialStock = (float) $initialInventory->quantity_on_hand;
        $sellQuantity = 2.00;
        $unitPrice = (float) $product->selling_price;
        $taxRate = (float) $product->tax_rate;
        $expectedSubtotal = $sellQuantity * $unitPrice;
        $expectedTax = round(($expectedSubtotal * $taxRate) / 100, 2);
        $expectedTotal = $expectedSubtotal + $expectedTax;

        $txUuid = (string) Str::uuid();

        $payload = [
            'transaction_uuid' => $txUuid,
            'items' => [
                [
                    'product_id' => $product->id,
                    'quantity' => $sellQuantity,
                    'unit_price' => $unitPrice,
                ],
            ],
            'payments' => [
                [
                    'payment_method' => 'cash',
                    'amount' => $expectedTotal + 10.00, // Cash with change
                ],
            ],
        ];

        $response = $this->actingAs($cashier)
            ->postJson('/api/v1/sales', $payload);

        $response->assertStatus(201)
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('sale.transaction_uuid', $txUuid);

        $this->assertEquals($expectedSubtotal, (float) $response->json('sale.subtotal'));
        $this->assertEquals($expectedTotal, (float) $response->json('sale.total_amount'));
        $this->assertEquals(10.0, (float) $response->json('sale.change_amount'));

        // Verify inventory deduction
        $updatedInventory = Inventory::where('store_id', $store->id)
            ->where('product_id', $product->id)
            ->first();

        $this->assertEquals($initialStock - $sellQuantity, (float) $updatedInventory->quantity_on_hand);

        // Verify stock movement audit row
        $movement = StockMovement::where('reference_uuid', $txUuid)->first();
        $this->assertNotNull($movement);
        $this->assertEquals('sale', $movement->type);
        $this->assertEquals(-$sellQuantity, (float) $movement->quantity);
    }
}
