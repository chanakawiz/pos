<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Stocktake;
use App\Models\Store;
use App\Services\StocktakeService;
use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StocktakeController extends Controller
{
    public function __construct(
        protected StocktakeService $stocktakeService
    ) {}

    /**
     * List store stocktake / cycle count sessions.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $storeId = $user?->store_id ?? 1;

        $stocktakes = Stocktake::with(['user:id,name', 'store:id,name,code'])
            ->where('store_id', $storeId)
            ->latest()
            ->paginate(25);

        return response()->json([
            'status' => 'success',
            'data' => $stocktakes,
        ]);
    }

    /**
     * Start a new stocktake session (optionally submitting counts and finalizing in 1 request).
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'notes' => 'nullable|string|max:500',
            'items' => 'nullable|array',
            'items.*.product_id' => 'nullable|integer',
            'items.*.product_uuid' => 'nullable|string',
            'items.*.barcode' => 'nullable|string',
            'items.*.sku' => 'nullable|string',
            'items.*.counted_quantity' => 'required_with:items|numeric|min:0|decimal:0,3',
            'items.*.notes' => 'nullable|string|max:255',
            'finalize' => 'nullable|boolean',
            'apply_adjustments' => 'nullable|boolean',
        ]);

        $user = $request->user();
        $store = $user->store ?? Store::firstOrFail();

        try {
            $stocktake = $this->stocktakeService->startStocktake($store, $user, $validated['notes'] ?? null);

            if (! empty($validated['items'])) {
                $stocktake = $this->stocktakeService->recordCounts($stocktake, $validated['items']);
            }

            if (! empty($validated['finalize'])) {
                $stocktake = $this->stocktakeService->finalizeStocktake(
                    $stocktake,
                    $user,
                    $validated['apply_adjustments'] ?? true
                );
            }

            return response()->json([
                'status' => 'success',
                'message' => ! empty($validated['finalize'])
                    ? 'Stocktake completed and inventory adjusted.'
                    : 'Stocktake session started.',
                'data' => $stocktake->load(['items.product', 'store', 'user']),
            ], 201);
        } catch (Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    /**
     * View stocktake details and scanned variance items.
     */
    public function show(string $uuid): JsonResponse
    {
        $stocktake = Stocktake::with(['items.product', 'store', 'user'])
            ->where('uuid', $uuid)
            ->orWhere('stocktake_number', $uuid)
            ->firstOrFail();

        return response()->json([
            'status' => 'success',
            'data' => $stocktake,
        ]);
    }

    /**
     * Record or update barcode-scanned item counts.
     */
    public function recordCounts(Request $request, string $uuid): JsonResponse
    {
        $validated = $request->validate([
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'nullable|integer',
            'items.*.product_uuid' => 'nullable|string',
            'items.*.barcode' => 'nullable|string',
            'items.*.sku' => 'nullable|string',
            'items.*.counted_quantity' => 'required|numeric|min:0|decimal:0,3',
            'items.*.notes' => 'nullable|string|max:255',
        ]);

        $stocktake = Stocktake::where('uuid', $uuid)
            ->orWhere('stocktake_number', $uuid)
            ->firstOrFail();

        try {
            $updated = $this->stocktakeService->recordCounts($stocktake, $validated['items']);

            return response()->json([
                'status' => 'success',
                'message' => 'Stocktake counts recorded.',
                'data' => $updated,
            ]);
        } catch (Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    /**
     * Finalize stocktake and apply inventory variance adjustments.
     */
    public function finalize(Request $request, string $uuid): JsonResponse
    {
        $validated = $request->validate([
            'apply_adjustments' => 'nullable|boolean',
        ]);

        $stocktake = Stocktake::where('uuid', $uuid)
            ->orWhere('stocktake_number', $uuid)
            ->firstOrFail();

        try {
            $finalized = $this->stocktakeService->finalizeStocktake(
                $stocktake,
                $request->user(),
                $validated['apply_adjustments'] ?? true
            );

            return response()->json([
                'status' => 'success',
                'message' => 'Stocktake finalized and branch inventory synchronized.',
                'data' => $finalized,
            ]);
        } catch (Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage(),
            ], 422);
        }
    }
}
