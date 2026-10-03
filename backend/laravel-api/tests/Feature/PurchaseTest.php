<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\Supplier;
use App\Models\User;
use Tests\TestCase;

class PurchaseTest extends TestCase
{
    public function test_can_create_supplier_and_purchase_order(): void
    {
        $user = User::where('email', 'admin@smartshop.com')->first()
            ?? User::where('email', 'cashier1@smartshop.com')->first();

        // 1. Create Supplier
        $supplierResponse = $this->actingAs($user)->postJson('/api/v1/suppliers', [
            'name'           => 'Apex Global Distributors',
            'contact_person' => 'Mark Jenkins',
            'phone'          => '0779988776',
            'email'          => 'orders@apexglobal.com',
            'tax_id'         => 'TAX-APEX-99',
        ]);

        $supplierResponse->assertStatus(201)
            ->assertJsonPath('status', 'success');

        $supplierUuid = $supplierResponse->json('data.uuid');

        // 2. List suppliers
        $listSuppliers = $this->actingAs($user)->getJson('/api/v1/suppliers');
        $listSuppliers->assertStatus(200);

        // 3. Create Purchase Order
        $product = Product::first();

        $purchaseResponse = $this->actingAs($user)->postJson('/api/v1/purchases', [
            'supplier_uuid' => $supplierUuid,
            'items'         => [
                [
                    'product_uuid' => $product->uuid,
                    'quantity'     => 10,
                    'unit_cost'    => 15.00,
                ],
            ],
            'notes'         => 'Urgent restock',
        ]);

        $purchaseResponse->assertStatus(201)
            ->assertJsonPath('status', 'success');

        $purchaseUuid = $purchaseResponse->json('data.uuid');

        // 4. Receive Purchase Order (stock replenishment)
        $receiveResponse = $this->actingAs($user)->postJson("/api/v1/purchases/{$purchaseUuid}/receive");
        $receiveResponse->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('data.status', 'received');
    }
}
