<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\Purchase;
use App\Models\PurchaseItem;
use App\Models\Store;
use App\Models\Supplier;
use App\Services\InventoryService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class PurchaseController extends Controller
{
    public function __construct(protected InventoryService $inventoryService) {}

    /**
     * List all purchase orders for the store.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $storeId = $user?->store_id ?? 1;

        $purchases = Purchase::with(['supplier:id,name', 'user:id,name'])
            ->where('store_id', $storeId)
            ->withCount('items')
            ->latest()
            ->paginate(25);

        return response()->json(['status' => 'success', 'data' => $purchases]);
    }

    /**
     * Create a new purchase order.
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'supplier_uuid' => 'required|uuid',
            'items' => 'required|array|min:1',
            'items.*.product_uuid' => 'required|uuid',
            'items.*.quantity' => 'required|numeric|min:0.001|decimal:0,3',
            'items.*.unit_cost' => 'required|numeric|min:0',
            'purchased_at' => 'nullable|date',
            'notes' => 'nullable|string',
        ]);

        $user = $request->user();
        $storeId = $user?->store_id ?? 1;

        $supplier = Supplier::where('uuid', $request->supplier_uuid)->firstOrFail();
        $store = Store::findOrFail($storeId);

        $purchase = DB::transaction(function () use ($request, $supplier, $store, $user) {
            $totalAmount = collect($request->items)->sum(
                fn ($item) => $item['quantity'] * $item['unit_cost']
            );

            $purchase = Purchase::create([
                'purchase_number' => 'PO-'.$store->code.'-'.now()->format('Ymd').'-'.strtoupper(Str::random(5)),
                'supplier_id' => $supplier->id,
                'store_id' => $store->id,
                'user_id' => $user->id,
                'status' => 'ordered',
                'total_amount' => $totalAmount,
                'purchased_at' => $request->purchased_at ? Carbon::parse($request->purchased_at) : Carbon::now(),
                'notes' => $request->notes,
            ]);

            foreach ($request->items as $itemData) {
                $product = Product::where('uuid', $itemData['product_uuid'])->firstOrFail();
                PurchaseItem::create([
                    'purchase_id' => $purchase->id,
                    'product_id' => $product->id,
                    'variant_id' => null,
                    'quantity' => $itemData['quantity'],
                    'unit_cost' => $itemData['unit_cost'],
                    'subtotal' => $itemData['quantity'] * $itemData['unit_cost'],
                ]);
            }

            return $purchase;
        });

        return response()->json([
            'status' => 'success',
            'message' => 'Purchase order created.',
            'data' => $purchase->load(['supplier', 'items.product']),
        ], 201);
    }

    /**
     * Show a single purchase order.
     */
    public function show(string $uuid): JsonResponse
    {
        $purchase = Purchase::with(['supplier', 'items.product', 'user'])
            ->where('uuid', $uuid)
            ->firstOrFail();

        return response()->json(['status' => 'success', 'data' => $purchase]);
    }

    /**
     * Receive a purchase — mark it received and automatically add inventory.
     */
    public function receive(Request $request, string $uuid): JsonResponse
    {
        $purchase = Purchase::with(['items.product', 'store'])
            ->where('uuid', $uuid)
            ->firstOrFail();

        if ($purchase->status === 'received') {
            return response()->json([
                'status' => 'error',
                'message' => 'This purchase order has already been received.',
            ], 422);
        }

        $user = $request->user();

        DB::transaction(function () use ($purchase, $user) {
            foreach ($purchase->items as $item) {
                $this->inventoryService->addStock(
                    store: $purchase->store,
                    product: $item->product,
                    variant: null,
                    quantity: (float) $item->quantity,
                    type: 'purchase',
                    referenceUuid: $purchase->uuid,
                    user: $user,
                    notes: "Stock received — PO: {$purchase->purchase_number}"
                );
            }

            $purchase->update(['status' => 'received']);
        });

        return response()->json([
            'status' => 'success',
            'message' => 'Purchase received and inventory updated.',
            'data' => $purchase->fresh(['items.product', 'supplier']),
        ]);
    }

    /**
     * List all suppliers.
     */
    public function suppliers(Request $request): JsonResponse
    {
        $suppliers = Supplier::withCount('purchases')
            ->when($request->search, fn ($q, $s) => $q->where('name', 'like', "%{$s}%"))
            ->latest()
            ->paginate(50);

        return response()->json(['status' => 'success', 'data' => $suppliers]);
    }

    /**
     * Create a new supplier.
     */
    public function storeSupplier(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'contact_person' => 'nullable|string|max:255',
            'phone' => 'nullable|string|max:50',
            'email' => 'nullable|email|max:255',
            'address' => 'nullable|string',
            'tax_id' => 'nullable|string|max:100',
        ]);

        $supplier = Supplier::create($request->only(['name', 'contact_person', 'phone', 'email', 'address', 'tax_id']));

        return response()->json([
            'status' => 'success',
            'message' => 'Supplier created.',
            'data' => $supplier,
        ], 201);
    }
}
