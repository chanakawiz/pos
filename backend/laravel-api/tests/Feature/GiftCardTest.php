<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\GiftCard;
use App\Models\Sale;
use App\Models\Store;
use App\Models\User;
use App\Services\GiftCardService;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class GiftCardTest extends TestCase
{
    use DatabaseTransactions;

    protected Store $store;
    protected User $cashier;
    protected Customer $customer;
    protected GiftCardService $service;

    protected function setUp(): void
    {
        parent::setUp();

        $this->store = Store::firstOrCreate(
            ['code' => 'STORE-GC-TEST'],
            ['name' => 'Colombo Flagship Hub', 'address' => '420 Galle Road, Colombo 03', 'is_active' => true]
        );

        $this->cashier = User::firstOrCreate(
            ['email' => 'cashier_gc_test@smartshop.com'],
            ['name' => 'GC Cashier', 'password' => bcrypt('password'), 'store_id' => $this->store->id, 'role' => 'cashier']
        );

        $this->customer = Customer::firstOrCreate(
            ['phone' => '0779998877'],
            ['name' => 'Devon Lane', 'email' => 'devon_gc@lifestyle.test', 'loyalty_points' => 250]
        );

        $this->service = app(GiftCardService::class);
    }

    public function test_can_issue_gift_card(): void
    {
        $card = $this->service->issueCard(
            amount: 5000.00,
            customerId: $this->customer->id,
            storeId: $this->store->id,
            userId: $this->cashier->id,
            notes: 'VIP Birthday Voucher'
        );

        $this->assertNotNull($card);
        $this->assertStringStartsWith('GC-', $card->code);
        $this->assertEquals(5000.00, (float) $card->initial_amount);
        $this->assertEquals(5000.00, (float) $card->balance);
        $this->assertEquals('active', $card->status);
        $this->assertCount(1, $card->transactions);
        $this->assertEquals('issue', $card->transactions->first()->type);
    }

    public function test_can_check_gift_card_balance(): void
    {
        $card = $this->service->issueCard(
            amount: 10000.00,
            customerId: $this->customer->id,
            storeId: $this->store->id,
            userId: $this->cashier->id
        );

        $result = $this->service->checkBalance($card->code);
        $this->assertTrue($result['found']);
        $this->assertTrue($result['valid']);
        $this->assertEquals(10000.00, $result['balance']);

        // Check nonexistent card
        $notFound = $this->service->checkBalance('GC-INVALID-CODE-9999');
        $this->assertFalse($notFound['found']);
        $this->assertFalse($notFound['valid']);
    }

    public function test_can_redeem_gift_card_partial_and_full(): void
    {
        $card = $this->service->issueCard(
            amount: 7500.00,
            customerId: $this->customer->id,
            storeId: $this->store->id,
            userId: $this->cashier->id
        );

        // Partial redemption: 3000.00
        $partial = $this->service->redeemCard(
            code: $card->code,
            amount: 3000.00,
            store: $this->store,
            user: $this->cashier,
            notes: 'First purchase'
        );

        $this->assertEquals(3000.00, $partial['redeemed_amount']);
        $this->assertEquals(4500.00, $partial['remaining_balance']);
        $this->assertEquals('active', $partial['card']->status);

        // Full redemption of remaining: 4500.00
        $full = $this->service->redeemCard(
            code: $card->code,
            amount: 4500.00,
            store: $this->store,
            user: $this->cashier,
            notes: 'Second purchase'
        );

        $this->assertEquals(4500.00, $full['redeemed_amount']);
        $this->assertEquals(0.00, $full['remaining_balance']);
        $this->assertEquals('redeemed', $full['card']->status);

        // Attempting to redeem again fails
        $this->expectException(\InvalidArgumentException::class);
        $this->service->redeemCard($card->code, 500.00);
    }

    public function test_can_refund_to_gift_card(): void
    {
        $card = $this->service->issueCard(
            amount: 2000.00,
            storeId: $this->store->id,
            userId: $this->cashier->id
        );

        // Redeem full amount
        $this->service->redeemCard($card->code, 2000.00);
        $this->assertEquals('redeemed', $card->fresh()->status);

        // Refund 1000 back
        $tx = $this->service->refundToCard($card->fresh(), 1000.00, null, $this->store, $this->cashier);

        $this->assertEquals('refund', $tx->type);
        $this->assertEquals(1000.00, (float) $tx->amount);
        $this->assertEquals(1000.00, (float) $card->fresh()->balance);
        $this->assertEquals('active', $card->fresh()->status);
    }

    public function test_api_can_verify_gift_card_publicly(): void
    {
        $card = $this->service->issueCard(
            amount: 15000.00,
            customerId: $this->customer->id,
            storeId: $this->store->id
        );

        $response = $this->postJson('/api/v1/gift-cards/verify', [
            'code' => strtolower($card->code), // tests case-insensitivity
        ]);

        $response->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('data.code', $card->code)
            ->assertJsonPath('data.valid', true);

        $this->assertEquals(15000.00, (float) $response->json('data.balance'));
    }

    public function test_api_cashier_can_redeem_gift_card(): void
    {
        $card = $this->service->issueCard(
            amount: 8000.00,
            storeId: $this->store->id
        );

        $response = $this->actingAs($this->cashier, 'sanctum')
            ->postJson('/api/v1/gift-cards/redeem', [
                'code' => $card->code,
                'amount' => 2500.00,
                'notes' => 'Counter POS Lane 01',
            ]);

        $response->assertOk()
            ->assertJsonPath('status', 'success');

        $this->assertEquals(2500.00, (float) $response->json('data.redeemed_amount'));
        $this->assertEquals(5500.00, (float) $response->json('data.remaining_balance'));
        $this->assertEquals(5500.00, (float) $card->fresh()->balance);
    }
}
