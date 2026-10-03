<?php

namespace App\Services;

use App\Models\Customer;
use App\Models\Device;
use App\Models\Payment;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\Refund;
use App\Models\RefundItem;
use App\Models\Sale;
use App\Models\SaleItem;
use App\Models\Store;
use App\Models\User;
use Carbon\Carbon;
use Exception;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class BillingService
{
    public function __construct(
        protected InventoryService $inventoryService
    ) {}

    /**
     * Process and commit a sale transaction.
     */
    public function processSale(array $data, Store $store, User $cashier, ?Device $device = null): Sale
    {
        return DB::transaction(function () use ($data, $store, $cashier, $device) {
            $transactionUuid = $data['transaction_uuid'] ?? (string) Str::uuid();

            // 1. Check idempotency
            $existingSale = Sale::where('transaction_uuid', $transactionUuid)->first();
            if ($existingSale) {
                return $existingSale;
            }

            $invoiceNumber = $data['invoice_number'] ?? $this->generateInvoiceNumber($store);
            $soldAt = isset($data['sold_at']) ? Carbon::parse($data['sold_at']) : Carbon::now();

            $subtotal = 0.00;
            $totalTax = 0.00;
            $totalDiscount = (float) ($data['discount_amount'] ?? 0.00);

            $saleItemsToInsert = [];

            foreach ($data['items'] as $item) {
                $product = isset($item['product_id'])
                    ? Product::findOrFail($item['product_id'])
                    : Product::where('uuid', $item['product_uuid'])->firstOrFail();

                $variant = null;
                if (!empty($item['variant_id'])) {
                    $variant = ProductVariant::find($item['variant_id']);
                } elseif (!empty($item['variant_uuid'])) {
                    $variant = ProductVariant::where('uuid', $item['variant_uuid'])->first();
                }

                $quantity = (float) $item['quantity'];
                $unitPrice = isset($item['unit_price']) ? (float) $item['unit_price'] : (float) ($variant ? $variant->selling_price : $product->selling_price);
                $unitCost = (float) ($variant ? $variant->cost_price : $product->cost_price);
                $itemDiscount = (float) ($item['discount_amount'] ?? 0.00);

                $lineSubtotal = ($quantity * $unitPrice) - $itemDiscount;
                $taxRate = (float) $product->tax_rate;
                $lineTax = $taxRate > 0 ? round(($lineSubtotal * $taxRate) / 100, 2) : 0.00;
                $lineTotal = $lineSubtotal + $lineTax;

                $subtotal += $lineSubtotal;
                $totalTax += $lineTax;

                $saleItemsToInsert[] = [
                    'product' => $product,
                    'variant' => $variant,
                    'quantity' => $quantity,
                    'serial_number' => $item['serial_number'] ?? null,
                    'warranty_notes' => $item['warranty_notes'] ?? ($product->warranty_period ? "Warranty: {$product->warranty_period}" : null),
                    'unit_cost' => $unitCost,
                    'unit_price' => $unitPrice,
                    'discount_amount' => $itemDiscount,
                    'tax_amount' => $lineTax,
                    'subtotal' => $lineSubtotal,
                    'total' => $lineTotal,
                ];
            }

            $finalTotal = max(0, $subtotal + $totalTax - $totalDiscount);

            // Payments calculation
            $totalPaid = 0.00;
            $paymentsData = $data['payments'] ?? [];
            foreach ($paymentsData as $p) {
                $totalPaid += (float) $p['amount'];
            }

            $changeAmount = max(0, $totalPaid - $finalTotal);
            $paymentStatus = $totalPaid >= $finalTotal ? 'paid' : ($totalPaid > 0 ? 'partial' : 'unpaid');

            // Find customer
            $customerId = null;
            if (!empty($data['customer_id'])) {
                $customerId = $data['customer_id'];
            } elseif (!empty($data['customer_uuid'])) {
                $customer = Customer::where('uuid', $data['customer_uuid'])->first();
                $customerId = $customer?->id;
            }

            // Create Sale
            $sale = Sale::create([
                'transaction_uuid' => $transactionUuid,
                'invoice_number' => $invoiceNumber,
                'store_id' => $store->id,
                'device_id' => $device?->id,
                'cashier_id' => $cashier->id,
                'customer_id' => $customerId,
                'subtotal' => $subtotal,
                'discount_amount' => $totalDiscount,
                'tax_amount' => $totalTax,
                'total_amount' => $finalTotal,
                'paid_amount' => $totalPaid,
                'change_amount' => $changeAmount,
                'payment_status' => $paymentStatus,
                'sale_status' => 'completed',
                'source' => $data['source'] ?? 'online',
                'sync_status' => 'synced',
                'notes' => $data['notes'] ?? null,
                'sold_at' => $soldAt,
            ]);

            // Create items and deduct stock
            foreach ($saleItemsToInsert as $line) {
                SaleItem::create([
                    'sale_id' => $sale->id,
                    'product_id' => $line['product']->id,
                    'variant_id' => $line['variant']?->id,
                    'quantity' => $line['quantity'],
                    'serial_number' => $line['serial_number'],
                    'warranty_notes' => $line['warranty_notes'],
                    'unit_cost' => $line['unit_cost'],
                    'unit_price' => $line['unit_price'],
                    'discount_amount' => $line['discount_amount'],
                    'tax_amount' => $line['tax_amount'],
                    'subtotal' => $line['subtotal'],
                    'total' => $line['total'],
                ]);

                // Stock deduction
                $this->inventoryService->deductStock(
                    store: $store,
                    product: $line['product'],
                    variant: $line['variant'],
                    quantity: $line['quantity'],
                    referenceUuid: $transactionUuid,
                    user: $cashier,
                    notes: "Sale: {$invoiceNumber}"
                );
            }

            // Create Payments
            foreach ($paymentsData as $p) {
                Payment::create([
                    'sale_id' => $sale->id,
                    'payment_method' => $p['payment_method'],
                    'amount' => (float) $p['amount'],
                    'reference_number' => $p['reference_number'] ?? null,
                    'paid_at' => isset($p['paid_at']) ? Carbon::parse($p['paid_at']) : $soldAt,
                ]);
            }

            // Customer loyalty point update if customer linked
            if ($customerId) {
                $customer = Customer::find($customerId);
                if ($customer) {
                    $earnedPoints = (int) floor($finalTotal / 10);
                    $customer->increment('loyalty_points', $earnedPoints);
                }
            }

            return $sale->load(['items.product', 'payments', 'cashier', 'store', 'customer']);
        });
    }

    /**
     * Generate an invoice number with store code and sequence.
     */
    public function generateInvoiceNumber(Store $store): string
    {
        $datePrefix = Carbon::now()->format('Ymd');
        $countToday = Sale::where('store_id', $store->id)
            ->whereDate('created_at', Carbon::today())
            ->count();

        $sequence = str_pad((string) ($countToday + 1), 5, '0', STR_PAD_LEFT);
        return "INV-{$store->code}-{$datePrefix}-{$sequence}";
    }

    /**
     * Process a return/refund transaction and restock inventory.
     */
    public function processRefund(
        Sale $sale,
        array $items,
        string $reason,
        User $cashier,
        bool $restock = true
    ): Refund {
        return DB::transaction(function () use ($sale, $items, $reason, $cashier, $restock) {
            $refundNumber = $this->generateRefundNumber($sale->store);
            $totalRefundAmount = 0.00;
            $refundItemsData = [];

            foreach ($items as $item) {
                $saleItem = null;
                if (!empty($item['sale_item_id'])) {
                    $saleItem = SaleItem::where('id', $item['sale_item_id'])->where('sale_id', $sale->id)->first();
                } elseif (!empty($item['sale_item_uuid'])) {
                    $saleItem = SaleItem::where('uuid', $item['sale_item_uuid'])->where('sale_id', $sale->id)->first();
                }

                if (!$saleItem) {
                    throw new Exception("Sale item not found for refund.");
                }

                $requestedQty = (float) $item['quantity'];
                if ($requestedQty <= 0) {
                    continue;
                }

                $alreadyRefundedQty = (float) $saleItem->refundItems()->sum('quantity');
                $maxAvailable = (float) $saleItem->quantity - $alreadyRefundedQty;

                if ($requestedQty > $maxAvailable + 0.0001) {
                    throw new Exception("Cannot refund {$requestedQty} units for item '{$saleItem->product->name}'. Only {$maxAvailable} available to refund.");
                }

                $unitPriceEffective = (float) ($saleItem->total / $saleItem->quantity);
                $lineAmount = round($requestedQty * $unitPriceEffective, 2);
                $totalRefundAmount += $lineAmount;

                $refundItemsData[] = [
                    'sale_item' => $saleItem,
                    'quantity' => $requestedQty,
                    'amount' => $lineAmount,
                    'restock' => $restock,
                ];
            }

            if (empty($refundItemsData)) {
                throw new Exception("No valid items to refund.");
            }

            // Create Refund Record
            $refund = Refund::create([
                'refund_number' => $refundNumber,
                'sale_id' => $sale->id,
                'store_id' => $sale->store_id,
                'cashier_id' => $cashier->id,
                'amount' => $totalRefundAmount,
                'reason' => $reason,
            ]);

            // Create Refund Items and Restock Inventory
            foreach ($refundItemsData as $data) {
                RefundItem::create([
                    'refund_id' => $refund->id,
                    'sale_item_id' => $data['sale_item']->id,
                    'quantity' => $data['quantity'],
                    'amount' => $data['amount'],
                    'restock' => $data['restock'],
                ]);

                if ($data['restock']) {
                    $this->inventoryService->addStock(
                        store: $sale->store,
                        product: $data['sale_item']->product,
                        variant: $data['sale_item']->variant,
                        quantity: $data['quantity'],
                        type: 'refund',
                        referenceUuid: $refund->uuid,
                        user: $cashier,
                        notes: "Restock from Refund #{$refundNumber}"
                    );
                }
            }

            // Update Sale Status
            $allRefunded = (float) $sale->refunds()->sum('amount');
            if ($allRefunded >= ((float) $sale->total_amount - 0.01)) {
                $sale->update(['payment_status' => 'refunded']);
            }

            return $refund->load(['items.saleItem.product', 'sale.customer', 'cashier', 'store']);
        });
    }

    /**
     * Generate a refund number.
     */
    public function generateRefundNumber(Store $store): string
    {
        $datePrefix = Carbon::now()->format('Ymd');
        $countToday = Refund::where('store_id', $store->id)
            ->whereDate('created_at', Carbon::today())
            ->count();

        $sequence = str_pad((string) ($countToday + 1), 5, '0', STR_PAD_LEFT);
        return "REF-{$store->code}-{$datePrefix}-{$sequence}";
    }
}
