<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Models\Sale;
use App\Models\Store;
use App\Services\BillingService;
use App\Services\InventoryService;
use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class SaleController extends Controller
{
    public function __construct(
        protected BillingService $billingService,
        protected InventoryService $inventoryService
    ) {}

    /**
     * Create a sale directly online.
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'transaction_uuid' => 'nullable|uuid',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required_without:items.*.product_uuid|integer',
            'items.*.product_uuid' => 'required_without:items.*.product_id|uuid',
            'items.*.quantity' => 'required|numeric|min:0.01',
            'items.*.unit_price' => 'nullable|numeric|min:0',
            'items.*.discount_amount' => 'nullable|numeric|min:0',
            'payments' => 'required|array|min:1',
            'payments.*.payment_method' => 'required|in:cash,card,bank_transfer,credit',
            'payments.*.amount' => 'required|numeric|min:0.01',
            'discount_amount' => 'nullable|numeric|min:0',
            'customer_id' => 'nullable|integer',
            'customer_uuid' => 'nullable|uuid',
            'notes' => 'nullable|string',
        ]);

        $cashier = $request->user();
        $store = $cashier->store ?? Store::firstOrFail();

        // Optional device resolution
        $device = null;
        if ($request->hasHeader('X-Device-UUID')) {
            $device = Device::where('uuid', $request->header('X-Device-UUID'))->first();
        }

        try {
            $data = $request->all();
            $data['source'] = 'online';

            $sale = $this->billingService->processSale($data, $store, $cashier, $device);

            return response()->json([
                'status' => 'success',
                'message' => 'Sale processed successfully.',
                'sale' => [
                    'id' => $sale->id,
                    'uuid' => $sale->uuid,
                    'transaction_uuid' => $sale->transaction_uuid,
                    'invoice_number' => $sale->invoice_number,
                    'subtotal' => (float) $sale->subtotal,
                    'discount_amount' => (float) $sale->discount_amount,
                    'tax_amount' => (float) $sale->tax_amount,
                    'total_amount' => (float) $sale->total_amount,
                    'paid_amount' => (float) $sale->paid_amount,
                    'change_amount' => (float) $sale->change_amount,
                    'payment_status' => $sale->payment_status,
                    'sold_at' => $sale->sold_at->toIso8601String(),
                    'items_count' => $sale->items->count(),
                    'items' => $sale->items->map(fn ($item) => [
                        'id' => $item->id,
                        'uuid' => $item->uuid,
                        'product_name' => $item->product->name,
                        'sinhala_name' => $item->product->sinhala_name,
                        'sku' => $item->product->sku,
                        'serial_number' => $item->serial_number,
                        'warranty_notes' => $item->warranty_notes,
                        'quantity' => (float) $item->quantity,
                        'unit_price' => (float) $item->unit_price,
                        'subtotal' => (float) $item->subtotal,
                        'tax_amount' => (float) $item->tax_amount,
                        'total' => (float) $item->total,
                    ]),
                    'payments' => $sale->payments->map(fn ($p) => [
                        'method' => $p->payment_method,
                        'amount' => (float) $p->amount,
                    ]),
                ],
                'receipt' => [
                    'store_name' => $store->name,
                    'store_phone' => $store->phone,
                    'store_address' => $store->address,
                    'tax_number' => $store->tax_number,
                    'currency_symbol' => $store->currency_symbol,
                    'invoice_number' => $sale->invoice_number,
                    'cashier_name' => $cashier->name,
                    'sold_at' => $sale->sold_at->format('Y-m-d H:i:s'),
                    'receipt_header' => $store->receipt_header,
                    'receipt_footer' => $store->receipt_footer,
                ],
            ], 201);
        } catch (Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to process sale: ' . $e->getMessage(),
            ], 422);
        }
    }

    /**
     * Sales history list.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $storeId = $user?->store_id ?? 1;

        $sales = Sale::with(['cashier:id,name', 'customer:id,name,phone', 'payments'])
            ->where('store_id', $storeId)
            ->latest('sold_at')
            ->paginate(25);

        return response()->json([
            'status' => 'success',
            'data' => $sales,
        ]);
    }

    /**
     * Show single sale details.
     */
    public function show(string $uuid): JsonResponse
    {
        $sale = Sale::with(['items.product', 'payments', 'cashier', 'store', 'customer'])
            ->where('uuid', $uuid)
            ->orWhere('invoice_number', $uuid)
            ->firstOrFail();

        return response()->json([
            'status' => 'success',
            'data' => $sale,
        ]);
    }
}
