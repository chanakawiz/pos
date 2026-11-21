<?php

namespace Tests\Feature;

use App\Models\BackInStockSubscription;
use App\Models\Customer;
use App\Models\Inventory;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use App\Services\InventoryService;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class WishlistAndStockAlertTest extends TestCase
{
    use DatabaseTransactions;

    public function test_guest_and_customer_can_toggle_and_list_wishlist_items(): void
    {
        $product = Product::where('is_active', true)->firstOrFail();
        $token = 'wl-test-session-001';

        // 1. Add to wishlist
        $addRes = $this->postJson('/api/v1/wishlist/toggle', [
            'product_id' => $product->id,
            'session_token' => $token,
            'variant_label' => '256GB Titanium',
        ]);
        $addRes->assertStatus(201)
            ->assertJsonPath('saved', true);

        // 2. List wishlist
        $listRes = $this->getJson("/api/v1/wishlist?session_token={$token}");
        $listRes->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.product_id', $product->id);

        // 3. Toggle again removes item
        $removeRes = $this->postJson('/api/v1/wishlist/toggle', [
            'product_id' => $product->id,
            'session_token' => $token,
        ]);
        $removeRes->assertStatus(200)
            ->assertJsonPath('saved', false);
    }

    public function test_restocking_product_from_zero_automatically_notifies_subscribers_via_sms_and_inbox(): void
    {
        config(['sms.default' => 'mock']);

        $store = Store::firstOrFail();
        $product = Product::where('is_active', true)->firstOrFail();
        $manager = User::where('email', 'manager@smartshop.com')->first()
            ?? User::where('email', 'cashier1@smartshop.com')->firstOrFail();

        $customer = Customer::create([
            'name' => 'Amaya Restock Client',
            'phone' => '+94775551122',
            'email' => 'amaya.restock@omniluxe.store',
            'balance' => 0,
            'credit_limit' => 0,
            'loyalty_points' => 100,
        ]);

        // Set branch inventory to 0 (Out of Stock)
        Inventory::updateOrCreate(
            ['store_id' => $store->id, 'product_id' => $product->id, 'variant_id' => null],
            ['quantity_on_hand' => 0.000, 'quantity_reserved' => 0.000]
        );

        // Subscribe customer via public API
        $subRes = $this->postJson("/api/v1/products/{$product->id}/notify-stock", [
            'customer_name' => $customer->name,
            'phone' => $customer->phone,
            'email' => $customer->email,
            'customer_uuid' => $customer->uuid,
            'store_id' => $store->id,
        ]);
        $subRes->assertStatus(201)
            ->assertJsonPath('data.status', 'subscribed');

        $subId = $subRes->json('data.id');

        // Replenish inventory from 0 -> 10 via InventoryService::addStock
        app(InventoryService::class)->addStock(
            store: $store,
            product: $product,
            variant: null,
            quantity: 10,
            type: 'purchase',
            referenceUuid: 'po-restock-test',
            user: $manager,
            notes: 'Fresh shipment arrived'
        );

        // Subscription must automatically transition to notified
        $sub = BackInStockSubscription::findOrFail($subId);
        $this->assertEquals('notified', $sub->status);
        $this->assertNotNull($sub->notified_at);

        // Verify SMS audit log & customer inbox notification were created
        $this->assertDatabaseHas('sms_logs', [
            'customer_id' => $customer->id,
            'event_type' => 'back_in_stock',
        ]);
        $this->assertDatabaseHas('customer_notifications', [
            'customer_id' => $customer->id,
        ]);
    }
}
