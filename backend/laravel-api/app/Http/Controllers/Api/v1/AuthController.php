<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * User / Cashier login.
     */
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required_without:pin_code|nullable|email',
            'password' => 'required_without:pin_code|nullable|string',
            'pin_code' => 'required_without:email|nullable|string',
            'device_uuid' => 'nullable|string',
        ]);

        $user = null;

        if ($request->filled('pin_code')) {
            // Find cashier by PIN in store/device context
            $device = $request->filled('device_uuid') ? Device::where('uuid', $request->device_uuid)->first() : null;
            $storeId = $device?->store_id;

            $users = User::where('is_active', true)
                ->when($storeId, fn ($q) => $q->where('store_id', $storeId))
                ->get();

            foreach ($users as $candidate) {
                if ($candidate->pin_code_hash && Hash::check($request->pin_code, $candidate->pin_code_hash)) {
                    $user = $candidate;
                    break;
                }
            }

            if (!$user) {
                throw ValidationException::withMessages(['pin_code' => ['Invalid cashier PIN code.']]);
            }
        } else {
            $user = User::where('email', $request->email)->first();

            if (!$user || !Hash::check($request->password, $user->password)) {
                throw ValidationException::withMessages(['email' => ['The provided credentials are incorrect.']]);
            }
        }

        if (!$user->is_active) {
            return response()->json(['message' => 'User account is deactivated.'], 403);
        }

        $tokenName = $request->device_uuid ? "device-{$request->device_uuid}" : 'pos-token';
        $token = $user->createToken($tokenName)->plainTextToken;

        $customerData = null;
        if ($user->role === 'customer') {
            $customer = \App\Models\Customer::where('email', $user->email)->first();
            if ($customer) {
                $customerData = [
                    'uuid' => $customer->uuid,
                    'phone' => $customer->phone,
                    'loyalty_points' => $customer->loyalty_points,
                    'tier' => $customer->loyalty_points >= 250 ? 'Gold VIP' : 'Silver Member',
                    'credit_limit' => $customer->credit_limit,
                ];
            }
        }

        return response()->json([
            'status' => 'success',
            'token' => $token,
            'user' => [
                'uuid' => $user->uuid,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'customer' => $customerData,
                'store' => $user->store ? [
                    'uuid' => $user->store->uuid,
                    'code' => $user->store->code,
                    'name' => $user->store->name,
                    'currency_code' => $user->store->currency_code,
                    'currency_symbol' => $user->store->currency_symbol,
                    'tax_number' => $user->store->tax_number,
                    'receipt_header' => $user->store->receipt_header,
                    'receipt_footer' => $user->store->receipt_footer,
                ] : null,
            ],
        ]);
    }

    /**
     * Customer Self Registration for Mobile & Web.
     */
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:120',
            'email' => 'required|email|max:120|unique:users,email',
            'phone' => 'required|string|max:30',
            'password' => 'required|string|min:6',
            'address' => 'nullable|string|max:255',
        ]);

        $user = User::create([
            'uuid' => (string) \Illuminate\Support\Str::uuid(),
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'role' => 'customer',
            'is_active' => true,
        ]);

        $cleanPhone = preg_replace('/[^0-9+]/', '', $validated['phone']);
        $customer = \App\Models\Customer::firstOrCreate(
            ['phone' => $cleanPhone],
            [
                'uuid' => (string) \Illuminate\Support\Str::uuid(),
                'name' => $validated['name'],
                'email' => $validated['email'],
                'address' => $validated['address'] ?? null,
                'loyalty_points' => 100, // 100 Welcome Points
                'credit_limit' => 50000.00,
                'balance' => 0.00,
                'version' => 1,
            ]
        );

        $token = $user->createToken('customer-mobile-token')->plainTextToken;

        return response()->json([
            'status' => 'success',
            'message' => 'Account created successfully! 100 welcome loyalty points awarded.',
            'token' => $token,
            'user' => [
                'uuid' => $user->uuid,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'customer' => [
                    'uuid' => $customer->uuid,
                    'name' => $customer->name,
                    'phone' => $customer->phone,
                    'email' => $customer->email,
                    'loyalty_points' => $customer->loyalty_points,
                    'tier' => 'Gold VIP',
                ],
            ],
        ], 201);
    }

    /**
     * Get current user info.
     */
    public function me(Request $request): JsonResponse
    {
        $user = $request->user()->load('store');

        return response()->json([
            'status' => 'success',
            'user' => [
                'uuid' => $user->uuid,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'store' => $user->store ? [
                    'uuid' => $user->store->uuid,
                    'code' => $user->store->code,
                    'name' => $user->store->name,
                    'currency_code' => $user->store->currency_code,
                    'currency_symbol' => $user->store->currency_symbol,
                ] : null,
            ],
        ]);
    }

    /**
     * Logout and revoke active token.
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Successfully logged out.',
        ]);
    }
}
