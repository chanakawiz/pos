<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Refund;
use App\Models\Sale;
use App\Services\BillingService;
use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RefundController extends Controller
{
    public function __construct(
        protected BillingService $billingService
    ) {}

    /**
     * List historical refunds.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Refund::with(['items.saleItem.product', 'sale', 'cashier', 'store']);

        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('refund_number', 'like', "%{$search}%")
                  ->orWhereHas('sale', function ($sq) use ($search) {
                      $sq->where('invoice_number', 'like', "%{$search}%");
                  });
            });
        }

        $perPage = min((int) $request->input('per_page', 20), 100);
        $refunds = $query->latest()->paginate($perPage);

        return response()->json($refunds);
    }

    /**
     * Show a single refund details.
     */
    public function show(string $uuid): JsonResponse
    {
        $refund = Refund::where('uuid', $uuid)
            ->with(['items.saleItem.product', 'sale.customer', 'cashier', 'store'])
            ->firstOrFail();

        return response()->json(['refund' => $refund]);
    }

    /**
     * Process a refund for a sale.
     */
    public function store(Request $request, string $saleUuid): JsonResponse
    {
        $validated = $request->validate([
            'items' => 'required|array|min:1',
            'items.*.sale_item_id' => 'nullable|integer',
            'items.*.sale_item_uuid' => 'nullable|string',
            'items.*.quantity' => 'required|numeric|min:0.01',
            'reason' => 'nullable|string|max:500',
            'restock' => 'nullable|boolean',
        ]);

        $sale = Sale::where('uuid', $saleUuid)
            ->orWhere('invoice_number', $saleUuid)
            ->firstOrFail();

        $cashier = $request->user();

        try {
            $refund = $this->billingService->processRefund(
                sale: $sale,
                items: $validated['items'],
                reason: $validated['reason'] ?? 'Customer Return',
                cashier: $cashier,
                restock: $validated['restock'] ?? true
            );

            return response()->json([
                'status' => 'success',
                'message' => 'Refund processed successfully',
                'refund' => $refund,
                'receipt' => [
                    'refund_number' => $refund->refund_number,
                    'invoice_number' => $sale->invoice_number,
                    'store_name' => $sale->store->name,
                    'cashier_name' => $cashier->name,
                    'total_refunded' => $refund->amount,
                    'reason' => $refund->reason,
                    'refunded_at' => $refund->created_at->toIso8601String(),
                ],
            ], 201);
        } catch (Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage(),
            ], 422);
        }
    }
}
