<?php

namespace App\Http\Controllers;

use App\Models\Customer;
use App\Models\Sale;
use App\Services\OrderTrackingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class OrderTrackingController extends Controller
{
    protected OrderTrackingService $trackingService;

    public function __construct(OrderTrackingService $trackingService)
    {
        $this->trackingService = $trackingService;
    }

    /**
     * Show Order Tracking & Status page.
     */
    public function show(Request $request, ?string $invoice = null): View
    {
        $ref = $invoice ?? $request->query('ref') ?? $request->query('query');
        $sale = null;
        $error = null;

        if ($ref) {
            $sale = $this->trackingService->trackOrder($ref);
            if (!$sale) {
                $error = "We could not find an order matching '{$ref}'. Please check your invoice number or courier tracking code.";
            }
        }

        // Timeline milestones calculation
        $timeline = $this->buildTimeline($sale);

        return view('store.track', [
            'sale' => $sale,
            'query' => $ref,
            'error' => $error,
            'timeline' => $timeline,
        ]);
    }

    /**
     * Customer Return / Exchange submission handler.
     */
    public function submitReturn(Request $request, string $invoice): RedirectResponse
    {
        $sale = $this->trackingService->trackOrder($invoice);

        if (!$sale) {
            return back()->with('error', 'Order not found.');
        }

        $validated = $request->validate([
            'type' => 'required|in:refund,return,exchange,warranty_claim',
            'reason' => 'required|string|max:500',
            'customer_notes' => 'nullable|string|max:1000',
            'items' => 'required|array|min:1',
            'items.*.selected' => 'nullable',
            'items.*.sale_item_id' => 'required|integer|exists:sale_items,id',
            'items.*.quantity' => 'required|numeric|min:0.01',
            'items.*.requested_action' => 'nullable|in:refund,return,exchange,exchange_size,repair_warranty',
            'items.*.item_condition' => 'nullable|in:unopened,opened_unused,defective,damaged',
            'items.*.replacement_notes' => 'nullable|string|max:255',
        ]);

        // Filter items that have been checked for return
        $selectedItems = array_filter($validated['items'], function ($item) {
            return !empty($item['selected']);
        });

        if (empty($selectedItems)) {
            // If submitted without explicit checkboxes (e.g. API or single item), fall back if only 1 item
            if (count($validated['items']) === 1 && !array_key_exists('selected', $validated['items'][0] ?? [])) {
                $selectedItems = $validated['items'];
            } else {
                return back()->with('error', 'Please check the box next to at least one item you wish to return.')->withInput();
            }
        }

        $validated['items'] = array_values($selectedItems);

        $currentUser = auth()->user();
        $customer = null;
        if ($currentUser) {
            $customer = Customer::where('user_id', $currentUser->id)
                ->orWhere('email', $currentUser->email)
                ->first();
        }

        try {
            $returnRequest = $this->trackingService->submitReturnRequest($sale, $validated, $customer);

            return redirect()->route('store.track', ['invoice' => $sale->invoice_number])
                ->with('success', "Return request #{$returnRequest->request_number} submitted successfully. Our concierge team will review your case within 24 hours.");
        } catch (\Exception $e) {
            return back()->with('error', 'Could not process return request: ' . $e->getMessage())->withInput();
        }
    }

    /**
     * API: Track order endpoint for mobile apps and headless integrations.
     */
    public function apiTrack(Request $request, string $identifier): JsonResponse
    {
        $sale = $this->trackingService->trackOrder($identifier);

        if (!$sale) {
            return response()->json([
                'success' => false,
                'message' => "No order found matching '{$identifier}'.",
            ], 404);
        }

        $timeline = $this->buildTimeline($sale);

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $sale->id,
                'uuid' => $sale->uuid,
                'invoice_number' => $sale->invoice_number,
                'created_at' => $sale->created_at->toIso8601String(),
                'sale_status' => $sale->sale_status,
                'payment_status' => $sale->payment_status,
                'fulfillment_status' => $sale->fulfillment_status,
                'courier_name' => $sale->courier_name,
                'tracking_number' => $sale->tracking_number,
                'estimated_delivery_at' => $sale->estimated_delivery_at?->toIso8601String(),
                'dispatched_at' => $sale->dispatched_at?->toIso8601String(),
                'delivered_at' => $sale->delivered_at?->toIso8601String(),
                'total_amount' => (float) $sale->total_amount,
                'timeline' => $timeline,
                'store' => [
                    'name' => $sale->store?->name,
                    'phone' => $sale->store?->phone,
                    'address' => $sale->store?->address,
                ],
                'items' => $sale->items->map(fn ($item) => [
                    'id' => $item->id,
                    'uuid' => $item->uuid,
                    'product_id' => $item->product_id,
                    'name' => $item->product?->name ?? 'Product Item',
                    'quantity' => (float) $item->quantity,
                    'unit_price' => (float) $item->unit_price,
                    'total' => (float) $item->total,
                ]),
                'return_requests' => $sale->returnRequests->map(fn ($ret) => [
                    'id' => $ret->id,
                    'request_number' => $ret->request_number,
                    'type' => $ret->type,
                    'status' => $ret->status,
                    'reason' => $ret->reason,
                    'created_at' => $ret->created_at->toIso8601String(),
                    'items_count' => $ret->items->count(),
                ]),
            ],
        ]);
    }

    /**
     * API: Submit return request for mobile apps.
     */
    public function apiSubmitReturn(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'invoice_number' => 'required|string',
            'type' => 'required|in:refund,return,exchange,warranty_claim',
            'reason' => 'required|string|max:500',
            'customer_notes' => 'nullable|string|max:1000',
            'items' => 'required|array|min:1',
            'items.*.sale_item_id' => 'required|integer|exists:sale_items,id',
            'items.*.quantity' => 'required|numeric|min:0.01',
            'items.*.requested_action' => 'nullable|in:refund,return,exchange,exchange_size,repair_warranty',
            'items.*.item_condition' => 'nullable|in:unopened,opened_unused,defective,damaged',
            'items.*.replacement_notes' => 'nullable|string|max:255',
        ]);

        $sale = $this->trackingService->trackOrder($validated['invoice_number']);
        if (!$sale) {
            return response()->json([
                'success' => false,
                'message' => 'Order not found.',
            ], 404);
        }

        try {
            $user = $request->user();
            $customer = null;
            if ($user) {
                $customer = Customer::where('user_id', $user->id)
                    ->orWhere('email', $user->email)
                    ->first();
            }

            $returnRequest = $this->trackingService->submitReturnRequest($sale, $validated, $customer);

            return response()->json([
                'success' => true,
                'message' => "Return request #{$returnRequest->request_number} logged successfully.",
                'data' => [
                    'request_number' => $returnRequest->request_number,
                    'type' => $returnRequest->type,
                    'status' => $returnRequest->status,
                    'created_at' => $returnRequest->created_at->toIso8601String(),
                ],
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    /**
     * Helper to compute timeline milestones.
     */
    protected function buildTimeline(?Sale $sale): array
    {
        if (!$sale) {
            return [];
        }

        $fulfillment = $sale->fulfillment_status ?? 'unfulfilled';
        $isPaid = in_array($sale->payment_status, ['paid', 'partial']);

        $steps = [
            [
                'step' => 1,
                'key' => 'placed',
                'title' => 'Order Placed',
                'description' => 'Order received and logged in system',
                'time' => $sale->created_at?->format('M d, Y h:i A'),
                'completed' => true,
                'active' => ($fulfillment === 'unfulfilled' && !$isPaid),
            ],
            [
                'step' => 2,
                'key' => 'confirmed',
                'title' => 'Payment Confirmed',
                'description' => $isPaid ? 'Payment verified & cleared' : 'Awaiting payment confirmation',
                'time' => $isPaid ? ($sale->paymentTransactions->last()?->created_at?->format('M d, Y h:i A') ?? $sale->created_at?->format('M d, Y h:i A')) : null,
                'completed' => $isPaid,
                'active' => ($isPaid && in_array($fulfillment, ['unfulfilled', 'processing'])),
            ],
            [
                'step' => 3,
                'key' => 'packed',
                'title' => 'Packed & Inspected',
                'description' => 'Quality verified and securely prepared in luxury packaging',
                'time' => in_array($fulfillment, ['packed', 'dispatched', 'delivered']) ? ($sale->updated_at?->format('M d, Y h:i A')) : null,
                'completed' => in_array($fulfillment, ['packed', 'dispatched', 'delivered']),
                'active' => ($fulfillment === 'packed'),
            ],
            [
                'step' => 4,
                'key' => 'dispatched',
                'title' => 'Dispatched with Courier',
                'description' => $sale->courier_name
                    ? "In transit via {$sale->courier_name} (Ref: " . ($sale->tracking_number ?? 'In Transit') . ')'
                    : 'Handed over to priority dispatch courier',
                'time' => $sale->dispatched_at?->format('M d, Y h:i A'),
                'completed' => in_array($fulfillment, ['dispatched', 'delivered']),
                'active' => ($fulfillment === 'dispatched'),
            ],
            [
                'step' => 5,
                'key' => 'delivered',
                'title' => 'Delivered',
                'description' => 'Delivered to recipient address',
                'time' => $sale->delivered_at?->format('M d, Y h:i A'),
                'completed' => ($fulfillment === 'delivered'),
                'active' => ($fulfillment === 'delivered'),
            ],
        ];

        return $steps;
    }
}
