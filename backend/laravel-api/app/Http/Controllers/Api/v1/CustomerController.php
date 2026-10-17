<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CustomerController extends Controller
{
    /**
     * List and search customers.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Customer::query();

        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $perPage = min((int) $request->input('per_page', 20), 100);
        $customers = $query->orderBy('name', 'asc')->paginate($perPage);

        return response()->json($customers);
    }

    /**
     * Create a new customer from POS or management.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:191',
            'phone' => 'nullable|string|max:50',
            'email' => 'nullable|email|max:191',
            'address' => 'nullable|string|max:500',
            'credit_limit' => 'nullable|numeric|min:0',
        ]);

        $customer = Customer::create([
            'name' => $validated['name'],
            'phone' => $validated['phone'] ?? null,
            'email' => $validated['email'] ?? null,
            'address' => $validated['address'] ?? null,
            'credit_limit' => $validated['credit_limit'] ?? 0.00,
            'balance' => 0.00,
            'loyalty_points' => 0,
            'version' => 1,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Customer created successfully',
            'customer' => $customer,
        ], 201);
    }

    /**
     * Show customer details with transaction history.
     */
    public function show(string $uuid): JsonResponse
    {
        $customer = Customer::where('uuid', $uuid)
            ->with(['sales' => function ($q) {
                $q->latest('sold_at')->take(10)->select('id', 'uuid', 'invoice_number', 'total_amount', 'sold_at', 'payment_status', 'customer_id');
            }])
            ->firstOrFail();

        return response()->json([
            'customer' => $customer,
        ]);
    }

    /**
     * Redeem customer loyalty points for discount credit.
     */
    public function redeemLoyalty(Request $request, string $uuid): JsonResponse
    {
        $request->validate([
            'points' => 'required|integer|min:1',
        ]);

        $customer = Customer::where('uuid', $uuid)->firstOrFail();
        $pointsToRedeem = (int) $request->input('points');

        if ($customer->loyalty_points < $pointsToRedeem) {
            return response()->json([
                'status' => 'error',
                'message' => "Insufficient loyalty points. Current balance: {$customer->loyalty_points}",
            ], 422);
        }

        // Conversion rate: 10 points = $1.00 discount
        $discountValue = round($pointsToRedeem * 0.10, 2);

        $customer->decrement('loyalty_points', $pointsToRedeem);

        return response()->json([
            'status' => 'success',
            'message' => "Redeemed {$pointsToRedeem} points for \${$discountValue} discount",
            'redeemed_points' => $pointsToRedeem,
            'discount_value' => $discountValue,
            'remaining_points' => $customer->fresh()->loyalty_points,
        ]);
    }
}
