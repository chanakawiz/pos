<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\User;
use Tests\TestCase;

class ProductTest extends TestCase
{
    public function test_authenticated_user_can_list_products(): void
    {
        $user = User::where('email', 'cashier1@smartshop.com')->first();

        $response = $this->actingAs($user)
            ->getJson('/api/v1/products');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'status',
                'data' => [
                    '*' => ['id', 'uuid', 'name', 'sku', 'barcode', 'selling_price', 'stock_quantity'],
                ],
            ]);
    }

    public function test_lookup_product_by_barcode(): void
    {
        $user = User::where('email', 'cashier1@smartshop.com')->first();
        $product = Product::first();

        $response = $this->actingAs($user)
            ->getJson("/api/v1/products/barcode/{$product->barcode}");

        $response->assertStatus(200)
            ->assertJsonPath('product.sku', $product->sku)
            ->assertJsonPath('product.barcode', $product->barcode);
    }
}
