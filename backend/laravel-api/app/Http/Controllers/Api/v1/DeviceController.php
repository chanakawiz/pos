<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Models\Store;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceController extends Controller
{
    /**
     * Register or pair a new POS terminal device.
     */
    public function register(Request $request): JsonResponse
    {
        $request->validate([
            'pairing_code' => 'required|string',
            'device_name' => 'required|string',
            'device_type' => 'required|in:windows,ios,android',
            'mac_address' => 'nullable|string',
            'app_version' => 'nullable|string',
        ]);

        $device = Device::where('pairing_code', $request->pairing_code)->first();

        if (!$device) {
            // Find default store
            $store = Store::first();
            if (!$store) {
                return response()->json(['message' => 'No active store found for pairing.'], 404);
            }

            $device = Device::create([
                'store_id' => $store->id,
                'device_name' => $request->device_name,
                'device_type' => $request->device_type,
                'mac_address' => $request->mac_address,
                'pairing_code' => $request->pairing_code,
                'app_version' => $request->app_version,
                'is_active' => true,
            ]);
        } else {
            $device->update([
                'device_name' => $request->device_name,
                'device_type' => $request->device_type,
                'mac_address' => $request->mac_address ?? $device->mac_address,
                'app_version' => $request->app_version ?? $device->app_version,
                'is_active' => true,
            ]);
        }

        $device->load('store');

        return response()->json([
            'status' => 'success',
            'device' => [
                'uuid' => $device->uuid,
                'device_name' => $device->device_name,
                'device_type' => $device->device_type,
                'store' => [
                    'uuid' => $device->store->uuid,
                    'code' => $device->store->code,
                    'name' => $device->store->name,
                    'currency_code' => $device->store->currency_code,
                    'currency_symbol' => $device->store->currency_symbol,
                ],
            ],
        ]);
    }
}
