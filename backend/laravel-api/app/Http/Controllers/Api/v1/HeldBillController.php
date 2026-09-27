<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Device;
use App\Models\HeldBill;
use App\Models\Store;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class HeldBillController extends Controller
{
    /**
     * List held bills for the authenticated cashier's store.
     * Other lanes can see all bills in the same store.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $storeId = $user?->store_id ?? 1;

        $bills = HeldBill::with(['cashier:id,name', 'customer:id,name,phone'])
            ->where('store_id', $storeId)
            ->latest('held_at')
            ->get()
            ->map(fn ($bill) => [
                'uuid'            => $bill->uuid,
                'hold_reference'  => $bill->hold_reference,
                'cashier_name'    => $bill->cashier?->name ?? 'Unknown',
                'customer_name'   => $bill->customer?->name ?? null,
                'customer_phone'  => $bill->customer?->phone ?? null,
                'items_count'     => count($bill->cart_items_json ?? []),
                'subtotal'        => (float) $bill->subtotal,
                'held_at'         => $bill->held_at?->toIso8601String(),
                'cart_items_json' => $bill->cart_items_json,
            ]);

        return response()->json([
            'status' => 'success',
            'data'   => $bills,
        ]);
    }

    /**
     * Persist a held bill to the cloud so other lanes can recall it.
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'hold_reference'  => 'nullable|string|max:100',
            'cart_items_json' => 'required|array|min:1',
            'subtotal'        => 'required|numeric|min:0',
            'customer_uuid'   => 'nullable|uuid',
        ]);

        $user     = $request->user();
        $storeId  = $user?->store_id ?? 1;
        $store    = Store::findOrFail($storeId);

        // Resolve device
        $device = null;
        if ($request->hasHeader('X-Device-UUID')) {
            $device = Device::where('uuid', $request->header('X-Device-UUID'))->first();
        }

        // Resolve customer
        $customer = null;
        if ($request->customer_uuid) {
            $customer = Customer::where('uuid', $request->customer_uuid)->first();
        }

        $bill = HeldBill::create([
            'store_id'        => $store->id,
            'device_id'       => $device?->id,
            'cashier_id'      => $user->id,
            'customer_id'     => $customer?->id,
            'hold_reference'  => $request->hold_reference ?? 'HOLD-' . strtoupper(Str::random(6)),
            'cart_items_json' => $request->cart_items_json,
            'subtotal'        => $request->subtotal,
            'held_at'         => Carbon::now(),
        ]);

        return response()->json([
            'status'  => 'success',
            'message' => 'Bill held successfully.',
            'data'    => [
                'uuid'           => $bill->uuid,
                'hold_reference' => $bill->hold_reference,
                'held_at'        => $bill->held_at->toIso8601String(),
            ],
        ], 201);
    }

    /**
     * Delete / discard a held bill after it is recalled or cancelled.
     */
    public function destroy(string $uuid): JsonResponse
    {
        $bill = HeldBill::where('uuid', $uuid)->firstOrFail();
        $bill->delete();

        return response()->json([
            'status'  => 'success',
            'message' => 'Held bill removed.',
        ]);
    }
}
