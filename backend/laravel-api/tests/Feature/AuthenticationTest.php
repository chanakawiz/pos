<?php

namespace Tests\Feature;

use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AuthenticationTest extends TestCase
{
    public function test_cashier_can_login_with_email_and_password(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'cashier1@smartshop.com',
            'password' => 'password',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'status',
                'token',
                'user' => ['uuid', 'name', 'email', 'role', 'store'],
            ]);
    }

    public function test_authenticated_user_can_fetch_me_profile(): void
    {
        $user = User::where('email', 'cashier1@smartshop.com')->first();

        $response = $this->actingAs($user)
            ->getJson('/api/v1/auth/me');

        $response->assertStatus(200)
            ->assertJsonPath('user.email', 'cashier1@smartshop.com');
    }
}
