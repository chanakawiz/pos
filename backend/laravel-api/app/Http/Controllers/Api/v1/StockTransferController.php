<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\StockTransfer;
use App\Models\Store;
use App\Services\StockTransferService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StockTransferController extends Controller
{
    public function __construct(
        protected StockTransferService $transferService
    ) {}

    /**
     * List stock transfers.
     */
    public function index(Request $request): JsonResponse
    {
        $query = StockTransfer::with(['sourceStore', 'destinationStore', 'items.product', 'requestedBy', 'approvedBy', 'receivedBy']);

        if ($request->filled('store_id')) {
            $storeId = (int) $request->store_id;
            $query->where(function ($q) use ($storeId) {
                $q->where('source_store_id', $storeId)
                    ->orWhere('destination_store_id', $storeId);
            });
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $transfers = $query->latest()->paginate(min(50, (int) $request->query('per_page', 20)));

        return response()->json([
            'status' => 'success',
            'data' => $transfers,
        ]);
    }

    /**
     * Get single stock transfer details.
     */
    public function show(string $uuid): JsonResponse
    {
        $transfer = StockTransfer::with(['sourceStore', 'destinationStore', 'items.product', 'items.variant', 'requestedBy', 'approvedBy', 'receivedBy'])
            ->where('uuid', $uuid)
            ->first();

        if (!$transfer) {
            return response()->json(['status' => 'error', 'message' => 'Stock transfer not found.'], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => $transfer,
        ]);
    }

    /**
     * Create a stock transfer request.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'source_store_id' => 'required|integer|exists:stores,id',
            'destination_store_id' => 'required|integer|exists:stores,id|different:source_store_id',
            'notes' => 'nullable|string|max:500',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|integer|exists:products,id',
            'items.*.variant_id' => 'nullable|integer|exists:product_variants,id',
            'items.*.quantity' => 'required|numeric|min:0.001',
        ]);

        $sourceStore = Store::findOrFail($validated['source_store_id']);
        $destinationStore = Store::findOrFail($validated['destination_store_id']);

        try {
            $transfer = $this->transferService->createTransfer(
                $sourceStore,
                $destinationStore,
                $validated['items'],
                $request->user(),
                $validated['notes'] ?? null
            );

            return response()->json([
                'status' => 'success',
                'message' => "Transfer #{$transfer->transfer_number} created successfully.",
                'data' => $transfer,
            ], 201);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 422);
        }
    }

    /**
     * Dispatch a stock transfer.
     */
    public function dispatchTransfer(Request $request, string $uuid): JsonResponse
    {
        $transfer = StockTransfer::where('uuid', $uuid)->first();
        if (!$transfer) {
            return response()->json(['status' => 'error', 'message' => 'Transfer not found.'], 404);
        }

        $quantitiesSent = $request->input('quantities_sent'); // optional map [item_id => qty]

        try {
            $updated = $this->transferService->dispatchTransfer(
                $transfer,
                $request->user(),
                is_array($quantitiesSent) ? $quantitiesSent : null
            );

            return response()->json([
                'status' => 'success',
                'message' => "Transfer #{$updated->transfer_number} dispatched in transit.",
                'data' => $updated,
            ]);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 422);
        }
    }

    /**
     * Receive a stock transfer.
     */
    public function receiveTransfer(Request $request, string $uuid): JsonResponse
    {
        $transfer = StockTransfer::where('uuid', $uuid)->first();
        if (!$transfer) {
            return response()->json(['status' => 'error', 'message' => 'Transfer not found.'], 404);
        }

        $quantitiesReceived = $request->input('quantities_received'); // optional map [item_id => qty]

        try {
            $updated = $this->transferService->receiveTransfer(
                $transfer,
                $request->user(),
                is_array($quantitiesReceived) ? $quantitiesReceived : null
            );

            return response()->json([
                'status' => 'success',
                'message' => "Transfer #{$updated->transfer_number} received into stock.",
                'data' => $updated,
            ]);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 422);
        }
    }

    /**
     * Cancel a stock transfer.
     */
    public function cancelTransfer(Request $request, string $uuid): JsonResponse
    {
        $transfer = StockTransfer::where('uuid', $uuid)->first();
        if (!$transfer) {
            return response()->json(['status' => 'error', 'message' => 'Transfer not found.'], 404);
        }

        $reason = $request->input('reason');

        try {
            $updated = $this->transferService->cancelTransfer($transfer, $request->user(), $reason);

            return response()->json([
                'status' => 'success',
                'message' => "Transfer #{$updated->transfer_number} cancelled.",
                'data' => $updated,
            ]);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 422);
        }
    }
}
