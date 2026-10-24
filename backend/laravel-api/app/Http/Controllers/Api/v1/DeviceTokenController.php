<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\CustomerDeviceToken;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class DeviceTokenController extends Controller
{
    /**
     * Store or update device push notification token (Firebase FCM / Web Push)
     * Persists token into customer_device_tokens in the central database.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'device_token' => 'required|string|max:500',
            'platform' => 'nullable|string|in:ios,android,web',
            'provider' => 'nullable|string|in:firebase_fcm,web_push',
            'customer_uuid' => 'nullable|string|exists:customers,uuid',
        ]);

        $platform = $validated['platform'] ?? 'ios';
        $provider = $validated['provider'] ?? 'firebase_fcm';
        $token = $validated['device_token'];

        $user = auth('sanctum')->user();
        $customer = null;

        if ($user) {
            $customer = $user->customerProfile ?? Customer::where('user_id', $user->id)
                ->orWhere('email', $user->email)
                ->first();
        }

        if (! $customer && ! empty($validated['customer_uuid'])) {
            $customer = Customer::where('uuid', $validated['customer_uuid'])->first();
        }

        if ($customer) {
            CustomerDeviceToken::updateOrCreate(
                ['token' => $token],
                [
                    'customer_id' => $customer->id,
                    'platform' => $platform,
                    'last_seen_at' => now(),
                ]
            );
        }

        Log::info("[Push Token Registered] Customer ID: " . ($customer->id ?? 'guest') . ", Platform: {$platform}, Token: " . substr($token, 0, 20) . "...");

        return response()->json([
            'status' => 'registered',
            'customer_uuid' => $customer?->uuid,
            'provider' => $provider,
            'platform' => $platform,
            'synced_at' => now()->toIso8601String(),
        ], 200);
    }
}
