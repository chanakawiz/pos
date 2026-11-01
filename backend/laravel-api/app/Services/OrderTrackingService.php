<?php

namespace App\Services;

use App\Models\Customer;
use App\Models\ReturnRequest;
use App\Models\ReturnRequestItem;
use App\Models\Sale;
use App\Models\SaleItem;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class OrderTrackingService
{
    /**
     * Find an order by invoice number, tracking number, or UUID.
     */
    public function trackOrder(string $identifier): ?Sale
    {
        $clean = trim($identifier);

        if (empty($clean)) {
            return null;
        }

        return Sale::query()
            ->with([
                'store',
                'customer',
                'items.product',
                'items.variant',
                'paymentTransactions',
                'returnRequests.items.saleItem.product',
            ])
            ->where(function ($query) use ($clean) {
                $query->where('invoice_number', $clean)
                    ->orWhere('tracking_number', $clean)
                    ->orWhere('uuid', $clean);
            })
            ->first();
    }

    /**
     * Submit a customer return or exchange request.
     */
    public function submitReturnRequest(Sale $sale, array $data, ?Customer $customer = null): ReturnRequest
    {
        if (empty($data['items']) || !is_array($data['items'])) {
            throw new InvalidArgumentException('Return request must contain at least one item.');
        }

        return DB::transaction(function () use ($sale, $data, $customer) {
            $rawType = $data['type'] ?? 'return';
            $type = match($rawType) {
                'refund', 'return' => 'return',
                'exchange' => 'exchange',
                'warranty_claim' => 'warranty_claim',
                default => 'return',
            };

            $returnRequest = ReturnRequest::create([
                'sale_id' => $sale->id,
                'customer_id' => $customer?->id ?? $sale->customer_id,
                'type' => $type,
                'status' => 'pending',
                'reason' => $data['reason'] ?? 'Customer return request',
                'customer_notes' => $data['customer_notes'] ?? null,
            ]);

            foreach ($data['items'] as $itemData) {
                $saleItem = SaleItem::where('id', $itemData['sale_item_id'])
                    ->where('sale_id', $sale->id)
                    ->first();

                if (!$saleItem) {
                    continue;
                }

                $quantity = min((float) ($itemData['quantity'] ?? 1), (float) $saleItem->quantity);
                if ($quantity <= 0) {
                    continue;
                }

                $rawAction = $itemData['requested_action'] ?? ($type === 'exchange' ? 'exchange_size' : 'refund');
                $requestedAction = match($rawAction) {
                    'exchange', 'exchange_size' => 'exchange_size',
                    'repair_warranty', 'warranty' => 'repair_warranty',
                    default => 'refund',
                };

                ReturnRequestItem::create([
                    'return_request_id' => $returnRequest->id,
                    'sale_item_id' => $saleItem->id,
                    'quantity' => $quantity,
                    'requested_action' => $requestedAction,
                    'item_condition' => in_array($itemData['item_condition'] ?? 'unopened', ['unopened', 'opened_unused', 'defective', 'damaged'])
                        ? ($itemData['item_condition'] ?? 'unopened')
                        : 'unopened',
                    'replacement_notes' => $itemData['replacement_notes'] ?? null,
                ]);
            }

            return $returnRequest->load(['items.saleItem.product', 'sale', 'customer']);
        });
    }

    /**
     * Update the fulfillment and shipment tracking details of an order.
     */
    public function updateFulfillment(
        Sale $sale,
        string $status,
        ?string $trackingNumber = null,
        ?string $courierName = null,
        ?string $estimatedDelivery = null
    ): Sale {
        $allowedStatuses = ['unfulfilled', 'processing', 'packed', 'dispatched', 'delivered', 'returned'];
        if (!in_array($status, $allowedStatuses)) {
            throw new InvalidArgumentException("Invalid fulfillment status: {$status}");
        }

        $sale->fulfillment_status = $status;

        if ($trackingNumber !== null) {
            $sale->tracking_number = trim($trackingNumber);
        }

        if ($courierName !== null) {
            $sale->courier_name = trim($courierName);
        }

        if ($estimatedDelivery !== null) {
            $sale->estimated_delivery_at = $estimatedDelivery;
        }

        if ($status === 'dispatched' && !$sale->dispatched_at) {
            $sale->dispatched_at = now();
        }

        if ($status === 'delivered' && !$sale->delivered_at) {
            $sale->delivered_at = now();
        }

        $sale->save();

        return $sale->fresh(['store', 'customer', 'items.product', 'paymentTransactions', 'returnRequests']);
    }
}
