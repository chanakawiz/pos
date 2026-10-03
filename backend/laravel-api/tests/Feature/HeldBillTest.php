<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\HeldBill;
use App\Models\User;
use Tests\TestCase;

class HeldBillTest extends TestCase
{
    public function test_can_hold_bill_and_list_held_bills(): void
    {
        $user = User::where('email', 'cashier1@smartshop.com')->first();
        $customer = Customer::first();

        // Hold a bill
        $postResponse = $this->actingAs($user)->postJson('/api/v1/held-bills', [
            'hold_reference'  => 'HOLD-TEST-001',
            'cart_items_json' => [
                [
                    'product_id' => 1,
                    'name'       => 'Test Item',
                    'quantity'   => 2,
                    'unit_price' => 10.00,
                ],
            ],
            'subtotal'        => 20.00,
            'customer_uuid'   => $customer?->uuid,
        ]);

        $postResponse->assertStatus(201)
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('data.hold_reference', 'HOLD-TEST-001');

        $billUuid = $postResponse->json('data.uuid');

        // List held bills
        $listResponse = $this->actingAs($user)->getJson('/api/v1/held-bills');
        $listResponse->assertStatus(200)
            ->assertJsonPath('status', 'success');

        $this->assertNotEmpty($listResponse->json('data'));

        // Delete / recall held bill
        $deleteResponse = $this->actingAs($user)->deleteJson("/api/v1/held-bills/{$billUuid}");
        $deleteResponse->assertStatus(200)
            ->assertJsonPath('status', 'success');

        $this->assertDatabaseMissing('held_bills', ['uuid' => $billUuid]);
    }
}
