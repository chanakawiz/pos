<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\BackInStockSubscription;
use App\Models\Customer;
use App\Models\Product;
use App\Models\WishlistItem;
use App\Services\BackInStockService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WishlistController extends Controller
{
    public function __construct(
        protected BackInStockService $backInStockService
    ) {}

    /**
     * List saved wishlist items for authenticated customer or guest session_token.
     */
    public function index(Request $request): JsonResponse
    {
        $customerId = $this->resolveCustomerId($request);
        $sessionToken = $request->query('session_token') ?? $request->header('X-Wishlist-Token');

        if (! $customerId && ! $sessionToken) {
            return response()->json(['status' => 'success', 'data' => []]);
        }

        $items = WishlistItem::with(['product.brand', 'product.category'])
            ->when($customerId, fn ($q) => $q->where('customer_id', $customerId))
            ->when(! $customerId && $sessionToken, fn ($q) => $q->where('session_token', $sessionToken))
            ->latest()
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $items->map(fn (WishlistItem $item) => [
                'uuid' => $item->uuid,
                'product_id' => $item->product_id,
                'variant_label' => $item->variant_label,
                'saved_at' => $item->created_at?->toIso8601String(),
                'product' => $item->product ? [
                    'id' => $item->product->id,
                    'uuid' => $item->product->uuid,
                    'name' => $item->product->name,
                    'sku' => $item->product->sku,
                    'selling_price' => (float) $item->product->selling_price,
                    'brand' => $item->product->brand?->name,
                    'category' => $item->product->category?->name,
                ] : null,
            ]),
        ]);
    }

    /**
     * Toggle a product in/out of the shopper's wishlist.
     */
    public function toggle(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'product_id' => 'required|exists:products,id',
            'session_token' => 'nullable|string|max:120',
            'customer_uuid' => 'nullable|string',
            'variant_label' => 'nullable|string|max:100',
        ]);

        $customerId = $this->resolveCustomerId($request, $validated['customer_uuid'] ?? null);
        $sessionToken = $validated['session_token'] ?? $request->header('X-Wishlist-Token');

        if (! $customerId && ! $sessionToken) {
            return response()->json([
                'status' => 'error',
                'message' => 'Provide an authenticated customer or session_token.',
            ], 422);
        }

        $query = WishlistItem::where('product_id', $validated['product_id']);
        if ($customerId) {
            $query->where('customer_id', $customerId);
        } else {
            $query->where('session_token', $sessionToken);
        }

        $existing = $query->first();
        if ($existing) {
            $existing->delete();

            return response()->json([
                'status' => 'success',
                'saved' => false,
                'message' => 'Removed from wishlist.',
            ]);
        }

        $item = WishlistItem::create([
            'customer_id' => $customerId,
            'session_token' => $customerId ? null : $sessionToken,
            'product_id' => $validated['product_id'],
            'variant_label' => $validated['variant_label'] ?? null,
        ]);

        return response()->json([
            'status' => 'success',
            'saved' => true,
            'message' => 'Saved to your OmniLuxe Wishlist.',
            'data' => $item,
        ], 201);
    }

    /**
     * Subscribe to automated back-in-stock SMS / Push alerts for any product.
     */
    public function subscribeStockAlert(Request $request, string $identifier): JsonResponse
    {
        $validated = $request->validate([
            'customer_name' => 'nullable|string|max:191',
            'phone' => 'nullable|string|max:50',
            'email' => 'nullable|email|max:191',
            'store_id' => 'nullable|exists:stores,id',
            'customer_uuid' => 'nullable|string',
        ]);

        if (empty($validated['phone']) && empty($validated['email'])) {
            return response()->json([
                'status' => 'error',
                'message' => 'Please provide a mobile number or email address for restock alerts.',
            ], 422);
        }

        $product = Product::where('id', $identifier)
            ->orWhere('uuid', $identifier)
            ->orWhere('sku', $identifier)
            ->firstOrFail();

        $customerId = $this->resolveCustomerId($request, $validated['customer_uuid'] ?? null);

        $subscription = $this->backInStockService->subscribe($product, [
            'customer_id' => $customerId,
            'store_id' => $validated['store_id'] ?? null,
            'customer_name' => $validated['customer_name'] ?? 'OmniLuxe Client',
            'phone' => $validated['phone'] ?? null,
            'email' => $validated['email'] ?? null,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => "We'll alert you immediately when {$product->name} is back in stock.",
            'data' => $subscription,
        ], 201);
    }

    /**
     * ERP / Staff: List back-in-stock alert subscriptions.
     */
    public function alertsIndex(): JsonResponse
    {
        $alerts = BackInStockSubscription::with(['product:id,name,sku', 'store:id,name'])
            ->latest()
            ->paginate(25);

        return response()->json([
            'status' => 'success',
            'data' => $alerts,
        ]);
    }

    protected function resolveCustomerId(Request $request, ?string $customerUuid = null): ?int
    {
        if ($customerUuid) {
            return Customer::where('uuid', $customerUuid)->value('id');
        }

        return $request->user()?->customerProfile?->id;
    }
}
