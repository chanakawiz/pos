<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Inventory;
use App\Models\Payment;
use App\Models\Product;
use App\Models\Refund;
use App\Models\Sale;
use App\Models\Store;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    /**
     * GET /api/v1/reports/sales-summary
     * Daily and monthly revenue breakdown by payment method.
     */
    public function salesSummary(Request $request): JsonResponse
    {
        $user    = $request->user();
        $storeId = $user?->store_id ?? 1;

        $period = $request->get('period', 'today'); // today | week | month | year
        $from   = match ($period) {
            'today'  => Carbon::today(),
            'week'   => Carbon::now()->startOfWeek(),
            'month'  => Carbon::now()->startOfMonth(),
            'year'   => Carbon::now()->startOfYear(),
            default  => Carbon::today(),
        };
        $to = Carbon::now();

        $salesIds = Sale::where('store_id', $storeId)
            ->whereBetween('sold_at', [$from, $to])
            ->pluck('id');

        $totalSales        = $salesIds->count();
        $grossRevenue      = (float) Sale::whereIn('id', $salesIds)->sum('total_amount');
        $totalDiscounts    = (float) Sale::whereIn('id', $salesIds)->sum('discount_amount');
        $totalTax          = (float) Sale::whereIn('id', $salesIds)->sum('tax_amount');
        $cashRevenue       = (float) Payment::whereIn('sale_id', $salesIds)->where('payment_method', 'cash')->sum('amount');
        $cardRevenue       = (float) Payment::whereIn('sale_id', $salesIds)->where('payment_method', 'card')->sum('amount');
        $transferRevenue   = (float) Payment::whereIn('sale_id', $salesIds)->where('payment_method', 'bank_transfer')->sum('amount');
        $totalRefunds      = (float) Refund::where('store_id', $storeId)->whereBetween('created_at', [$from, $to])->sum('amount');

        // Daily breakdown (last 30 days for month/year)
        $dailySales = Sale::where('store_id', $storeId)
            ->whereBetween('sold_at', [$from, $to])
            ->select(DB::raw('DATE(sold_at) as date'), DB::raw('COUNT(*) as count'), DB::raw('SUM(total_amount) as revenue'))
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        return response()->json([
            'status' => 'success',
            'period' => $period,
            'from'   => $from->toDateString(),
            'to'     => $to->toDateString(),
            'summary' => [
                'total_transactions' => $totalSales,
                'gross_revenue'      => $grossRevenue,
                'total_discounts'    => $totalDiscounts,
                'total_tax'          => $totalTax,
                'net_revenue'        => $grossRevenue - $totalRefunds,
                'total_refunds'      => $totalRefunds,
                'cash_revenue'       => $cashRevenue,
                'card_revenue'       => $cardRevenue,
                'transfer_revenue'   => $transferRevenue,
                'avg_sale_value'     => $totalSales > 0 ? round($grossRevenue / $totalSales, 2) : 0,
            ],
            'daily_breakdown' => $dailySales,
        ]);
    }

    /**
     * GET /api/v1/reports/top-products
     * Best-selling products by quantity and revenue.
     */
    public function topProducts(Request $request): JsonResponse
    {
        $user    = $request->user();
        $storeId = $user?->store_id ?? 1;
        $limit   = (int) $request->get('limit', 10);
        $period  = $request->get('period', 'month');

        $from = match ($period) {
            'today'  => Carbon::today(),
            'week'   => Carbon::now()->startOfWeek(),
            'month'  => Carbon::now()->startOfMonth(),
            'year'   => Carbon::now()->startOfYear(),
            default  => Carbon::now()->startOfMonth(),
        };

        $saleIds = Sale::where('store_id', $storeId)
            ->where('sold_at', '>=', $from)
            ->pluck('id');

        $topProducts = DB::table('sale_items')
            ->join('products', 'sale_items.product_id', '=', 'products.id')
            ->whereIn('sale_items.sale_id', $saleIds)
            ->select(
                'products.id',
                'products.uuid',
                'products.name',
                'products.sku',
                DB::raw('SUM(sale_items.quantity) as total_quantity_sold'),
                DB::raw('SUM(sale_items.total) as total_revenue'),
                DB::raw('COUNT(DISTINCT sale_items.sale_id) as appeared_in_sales')
            )
            ->groupBy('products.id', 'products.uuid', 'products.name', 'products.sku')
            ->orderByDesc('total_quantity_sold')
            ->limit($limit)
            ->get();

        return response()->json([
            'status'       => 'success',
            'period'       => $period,
            'top_products' => $topProducts,
        ]);
    }

    /**
     * GET /api/v1/reports/low-stock
     * Products whose inventory quantity is at or below their min_stock_level.
     */
    public function lowStock(Request $request): JsonResponse
    {
        $user    = $request->user();
        $storeId = $user?->store_id ?? 1;

        $lowStockItems = Inventory::with(['product:id,uuid,name,sku,barcode,min_stock_level', 'product.category:id,name'])
            ->where('store_id', $storeId)
            ->whereColumn('quantity_on_hand', '<=', DB::raw('(SELECT min_stock_level FROM products WHERE products.id = inventory.product_id)'))
            ->orderBy('quantity_on_hand')
            ->get()
            ->map(fn ($inv) => [
                'product_uuid'    => $inv->product?->uuid,
                'product_name'    => $inv->product?->name,
                'sku'             => $inv->product?->sku,
                'barcode'         => $inv->product?->barcode,
                'category'        => $inv->product?->category?->name,
                'quantity_on_hand' => (float) $inv->quantity_on_hand,
                'min_stock_level' => (float) $inv->product?->min_stock_level,
                'deficit'         => max(0, (float) $inv->product?->min_stock_level - (float) $inv->quantity_on_hand),
                'status'          => (float) $inv->quantity_on_hand <= 0 ? 'out_of_stock' : 'low_stock',
            ]);

        return response()->json([
            'status'       => 'success',
            'total_alerts' => $lowStockItems->count(),
            'items'        => $lowStockItems,
        ]);
    }
}
