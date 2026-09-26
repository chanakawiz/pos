<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\User;
use Tests\TestCase;

class CustomerTest extends TestCase
{
    public function test_authenticated_user_can_list_and_search_customers(): void
    {
        $user = User::where('email', 'cashier1@smartshop.com')->first();

        Customer::firstOrCreate(
            ['phone' => '0771234567'],
            [
                'name' => 'John Doe',
                'email' => 'john@example.com',
                'loyalty_points' => 150,
                'version' => 1,
            ]
        );

        $response = $this->actingAs($user)
            ->getJson('/api/v1/customers?search=John');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    '*' => ['id', 'uuid', 'name', 'phone', 'email', 'loyalty_points', 'balance'],
                ],
            ]);
    }

    public function test_can_create_customer(): void
    {
        $user = User::where('email', 'cashier1@smartshop.com')->first();

        $response = $this->actingAs($user)->postJson('/api/v1/customers', [
            'name' => 'Alice Walker',
            'phone' => '0719876543',
            'email' => 'alice@example.com',
            'address' => '742 Evergreen Terrace',
            'credit_limit' => 200.00,
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('customer.name', 'Alice Walker')
            ->assertJsonPath('customer.loyalty_points', 0);

        $this->assertDatabaseHas('customers', [
            'name' => 'Alice Walker',
            'phone' => '0719876543',
        ]);
    }

    public function test_can_redeem_loyalty_points(): void
    {
        $user = User::where('email', 'cashier1@smartshop.com')->first();

        $customer = Customer::create([
            'name' => 'Bob Loyalty',
            'phone' => '0751112233',
            'loyalty_points' => 200,
            'version' => 1,
        ]);

        $response = $this->actingAs($user)->postJson("/api/v1/customers/{$customer->uuid}/redeem-loyalty", [
            'points' => 50,
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('redeemed_points', 50)
            ->assertJsonPath('discount_value', 5)
            ->assertJsonPath('remaining_points', 150);

        $this->assertEquals(150, $customer->fresh()->loyalty_points);
    }
}
