<?php

namespace App\Services;

use App\Models\Customer;
use App\Models\Device;
use App\Models\Payment;
use App\Models\Product;
use App\Models\ProductVariant;
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
}
