<?php

namespace Tests\Feature;

use App\Models\Device;
use App\Models\Inventory;
use App\Models\Product;
use App\Models\Sale;
use App\Models\StockMovement;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Str;
use Tests\TestCase;

class WeighedSaleTest extends TestCase
{
    use DatabaseTransactions;

    public function test_fractional_sale_and_refunds_preserve_stock_and_ledger_precision(): void
    {
        $cashier = User::where('email', 'cashier1@smartshop.com')->firstOrFail();
        $product = Product::firstOrFail();
        $product->update(['unit' => 'kg', 'selling_price' => 100, 'tax_rate' => 0]);
        $inventory = Inventory::where('store_id', $cashier->store_id)->where('product_id', $product->id)->firstOrFail();
        $before = (float) $inventory->quantity_on_hand;
        $transaction = (string) Str::uuid();
        $response = $this->actingAs($cashier)->postJson('/api/v1/sales', [
            'transaction_uuid' => $transaction,
            'items' => [['product_id' => $product->id, 'quantity' => 0.125, 'unit_price' => 100]],
            'payments' => [['payment_method' => 'cash', 'amount' => 12.5]],
        ])->assertCreated()->assertJsonPath('sale.total_amount', 12.5);
        $sale = Sale::where('transaction_uuid', $transaction)->firstOrFail();
        $this->assertSame('0.125', $sale->items()->firstOrFail()->quantity);
        $this->assertEquals(round($before - 0.125, 3), (float) $inventory->fresh()->quantity_on_hand);
        $this->assertSame('-0.125', StockMovement::where('reference_uuid', $transaction)->firstOrFail()->quantity);
        foreach ([0.024, 0.101] as $quantity) {
            $this->postJson('/api/v1/sales/'.$response->json('sale.uuid').'/refund', [
                'items' => [['sale_item_id' => $response->json('sale.items.0.id'), 'quantity' => $quantity]],
                'restock' => true,
            ])->assertCreated();
        }
        $this->assertEquals($before, (float) $inventory->fresh()->quantity_on_hand);
        $this->assertEquals(0.125, (float) $sale->items()->firstOrFail()->refundItems()->sum('quantity'));
        $this->postJson('/api/v1/sales/'.$sale->uuid.'/refund', [
            'items' => [['sale_item_id' => $response->json('sale.items.0.id'), 'quantity' => 0.001]],
        ])->assertStatus(422);
    }

    public function test_one_gram_offline_sale_retries_without_double_stock_deduction(): void
    {
        $cashier = User::where('email', 'cashier1@smartshop.com')->firstOrFail();
        $device = Device::where('store_id', $cashier->store_id)->firstOrFail();
        $product = Product::firstOrFail();
        $inventory = Inventory::where('store_id', $cashier->store_id)->where('product_id', $product->id)->firstOrFail();
        $before = (float) $inventory->quantity_on_hand;
        $transaction = (string) Str::uuid();
        $payload = ['device_uuid' => $device->uuid, 'transactions' => [[
            'transaction_uuid' => $transaction, 'cashier_uuid' => $cashier->uuid,
            'items' => [['product_uuid' => $product->uuid, 'quantity' => 0.001, 'unit_price' => 100, 'tax_rate' => 0]],
            'payments' => [['payment_method' => 'cash', 'amount' => 0.1]],
        ]]];
        for ($attempt = 0; $attempt < 2; $attempt++) {
            $this->actingAs($cashier)->postJson('/api/v1/sync/push', $payload)->assertOk()->assertJsonPath('synced_count', 1);
        }
        $this->assertSame('0.001', Sale::where('transaction_uuid', $transaction)->firstOrFail()->items()->firstOrFail()->quantity);
        $this->assertEquals(round($before - 0.001, 3), (float) $inventory->fresh()->quantity_on_hand);
        $this->assertSame(1, StockMovement::where('reference_uuid', $transaction)->count());
    }

    public function test_unsupported_quantity_precision_is_rejected_instead_of_rounded(): void
    {
        $cashier = User::where('email', 'cashier1@smartshop.com')->firstOrFail();
        $product = Product::firstOrFail();
        foreach ([0.0001, 0.1234] as $quantity) {
            $this->actingAs($cashier)->postJson('/api/v1/sales', [
                'items' => [['product_id' => $product->id, 'quantity' => $quantity]],
                'payments' => [['payment_method' => 'cash', 'amount' => 1]],
            ])->assertUnprocessable()->assertJsonValidationErrors('items.0.quantity');
        }
    }

    public function test_quantity_precision_rollback_refuses_to_round_existing_stock(): void
    {
        $inventory = Inventory::firstOrFail();
        $inventory->update(['quantity_on_hand' => 0.125]);
        $migration = require database_path('migrations/2026_10_17_000002_preserve_three_decimal_stock_quantities.php');
        $this->expectException(\RuntimeException::class);
        $migration->down();
    }
}
