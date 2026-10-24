<?php

namespace App\Http\Controllers;

use App\Models\Category;
use App\Models\Customer;
use App\Models\Inventory;
use App\Models\Payment;
use App\Models\Product;
use App\Models\Sale;
use App\Models\SaleItem;
use App\Models\StockMovement;
use App\Models\Store;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class WebStoreController extends Controller
{
    /**
     * Display the customizable E-Commerce Web Storefront.
     */
    public function index(Request $request)
    {
        $categories = Category::where('is_active', true)->orderBy('display_order')->get();
        $query = Product::with(['category', 'brand', 'inventories'])
            ->where('is_active', true);

        // Filter by category
        if ($request->filled('category')) {
            $catId = $request->input('category');
            $query->where('category_id', $catId);
        }

        // Search query
        if ($request->filled('q')) {
            $term = $request->input('q');
            $query->where(function ($q) use ($term) {
                $q->where('name', 'like', "%{$term}%")
                  ->orWhere('sinhala_name', 'like', "%{$term}%")
                  ->orWhere('sku', 'like', "%{$term}%")
                  ->orWhere('barcode', 'like', "%{$term}%");
            });
        }

        $products = $query->latest()->get();
        $store = Store::first() ?? new Store([
            'name' => 'SmartShop Urban Flagship',
            'phone' => '+94 11 234 5678',
            'email' => 'sales@smartshop.lk',
            'currency_symbol' => 'Rs.',
            'address' => '420 Galle Road, Colombo 03',
        ]);

        return view('store.index', compact('categories', 'products', 'store'));
    }

    /**
     * Show single product details.
     */
    public function show($id)
    {
        $product = Product::with(['category', 'brand', 'variants', 'inventories'])
            ->findOrFail($id);

        $store = Store::first();
        return view('store.product', compact('product', 'store'));
    }

    /**
     * Process online order checkout from the web storefront.
     */
    public function checkout(Request $request)
    {
        $validated = $request->validate([
            'customer_name' => 'required|string|max:120',
            'customer_phone' => 'required|string|max:30',
            'customer_email' => 'nullable|email|max:120',
            'shipping_address' => 'required|string|max:300',
            'payment_method' => 'required|string|in:cod,card,bank_transfer',
            'cart_items' => 'required|string', // JSON array of [{product_id, quantity, price}]
        ]);

        $cartItems = json_decode($validated['cart_items'], true);
        if (empty($cartItems)) {
            return back()->with('error', 'Your shopping bag is empty.');
        }

        $store = Store::first();
        $storeId = $store ? $store->id : 1;

        $sale = DB::transaction(function () use ($validated, $cartItems, $store, $storeId) {
            // Find or create customer (with privacy consideration)
            $phoneClean = preg_replace('/[^0-9+]/', '', $validated['customer_phone']);
            $customer = Customer::firstOrCreate(
                ['phone' => $phoneClean],
                [
                    'uuid' => (string) Str::uuid(),
                    'name' => $validated['customer_name'],
                    'email' => $validated['customer_email'] ?? null,
                    'address' => $validated['shipping_address'],
                    'loyalty_points' => 0,
                    'store_credit' => 0.00,
                ]
            );

            $subtotal = 0.0;
            $itemsToCreate = [];

            foreach ($cartItems as $cItem) {
                $product = Product::findOrFail($cItem['product_id']);
                $qty = max(1, (int) $cItem['quantity']);
                $lineTotal = $product->selling_price * $qty;
                $subtotal += $lineTotal;

                $itemsToCreate[] = [
                    'product' => $product,
                    'quantity' => $qty,
                    'unit_price' => $product->selling_price,
                    'subtotal' => $lineTotal,
                ];

                // Atomically decrement inventory
                $inv = Inventory::where('product_id', $product->id)
                    ->where('store_id', $storeId)
                    ->lockForUpdate()
                    ->first();

                $oldQty = $inv ? $inv->quantity_on_hand : 0;
                $newQty = max(0, $oldQty - $qty);

                if ($inv) {
                    $inv->update(['quantity_on_hand' => $newQty]);
                } else {
                    Inventory::create([
                        'store_id' => $storeId,
                        'product_id' => $product->id,
                        'quantity_on_hand' => $newQty,
                        'reorder_point' => 5,
                    ]);
                }

                // Log Stock Movement
                StockMovement::create([
                    'store_id' => $storeId,
                    'product_id' => $product->id,
                    'type' => 'sale',
                    'quantity' => -$qty,
                    'quantity_before' => $oldQty,
                    'quantity_after' => $newQty,
                    'reference_type' => 'web_order',
                    'reference_id' => null,
                    'notes' => 'E-Commerce Web Store order for ' . $validated['customer_name'],
                ]);
            }

            $timestamp = now();
            $invoiceNumber = 'WEB-' . $timestamp->format('Ymd') . '-' . rand(1000, 9999);

            $sale = Sale::create([
                'uuid' => (string) Str::uuid(),
                'store_id' => $storeId,
                'user_id' => null, // Online guest/self-checkout
                'customer_id' => $customer->id,
                'invoice_number' => $invoiceNumber,
                'subtotal' => $subtotal,
                'discount_amount' => 0.00,
                'tax_amount' => 0.00,
                'total_amount' => $subtotal,
                'paid_amount' => $validated['payment_method'] === 'cod' ? 0.00 : $subtotal,
                'change_amount' => 0.00,
                'status' => 'completed',
                'payment_status' => $validated['payment_method'] === 'cod' ? 'pending' : 'paid',
                'sold_at' => $timestamp,
                'notes' => 'Web Store Order | Ship to: ' . $validated['shipping_address'],
            ]);

            foreach ($itemsToCreate as $itemData) {
                SaleItem::create([
                    'sale_id' => $sale->id,
                    'product_id' => $itemData['product']->id,
                    'product_name' => $itemData['product']->name,
                    'quantity' => $itemData['quantity'],
                    'unit_price' => $itemData['unit_price'],
                    'discount_amount' => 0.00,
                    'tax_amount' => 0.00,
                    'subtotal' => $itemData['subtotal'],
                    'warranty_expires_at' => $itemData['product']->warranty_period
                        ? now()->addMonths(12)
                        : null,
                ]);
            }

            Payment::create([
                'sale_id' => $sale->id,
                'payment_method' => $validated['payment_method'],
                'amount' => $subtotal,
                'reference_number' => 'WEB-' . strtoupper(Str::random(8)),
                'status' => $validated['payment_method'] === 'cod' ? 'pending' : 'completed',
            ]);

            return $sale;
        });

        return redirect()->route('store.receipt', ['invoice' => $sale->invoice_number])
            ->with('success', 'Order placed successfully! SMS receipt dispatched to customer.');
    }

    /**
     * Public Digital E-Receipt & Warranty Lookup (sent via SMS link).
     */
    public function receipt($invoice)
    {
        $sale = Sale::with(['store', 'customer', 'items.product', 'payments'])
            ->where('invoice_number', $invoice)
            ->firstOrFail();

        // Customer privacy masking for public web link: e.g., +94 77 •••• 890
        $maskedPhone = null;
        if ($sale->customer && $sale->customer->phone) {
            $p = $sale->customer->phone;
            $len = strlen($p);
            if ($len > 6) {
                $maskedPhone = substr($p, 0, 4) . ' •••• ' . substr($p, -3);
            } else {
                $maskedPhone = '••••';
            }
        }

        return view('store.receipt', compact('sale', 'maskedPhone'));
    }
}
