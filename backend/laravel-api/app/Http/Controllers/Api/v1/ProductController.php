<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Brand;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    /**
     * List products with inventory and filter/search support.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $storeId = $user?->store_id ?? $request->query('store_id', 1);

        $query = Product::with(['category', 'brand', 'variants', 'inventories' => function ($q) use ($storeId) {
            $q->where('store_id', $storeId);
        }])->where('is_active', true);

        // Search by name, sku, or barcode
        if ($request->filled('search')) {
            $term = $request->search;
            $query->where(function ($q) use ($term) {
                $q->where('name', 'like', "%{$term}%")
                    ->orWhere('sku', 'like', "%{$term}%")
                    ->orWhere('barcode', 'like', "%{$term}%");
            });
        }

        // Category filter
        if ($request->filled('category_uuid')) {
            $category = Category::where('uuid', $request->category_uuid)->first();
            if ($category) {
                $query->where('category_id', $category->id);
            }
        } elseif ($request->filled('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        $perPage = min(100, max(10, (int) $request->query('per_page', 50)));
        $products = $query->paginate($perPage);

        $transformed = $products->getCollection()->map(function ($p) {
            $stock = $p->inventories->first()?->quantity_on_hand ?? 0.00;
            return [
                'id' => $p->id,
                'uuid' => $p->uuid,
                'name' => $p->name,
                'sku' => $p->sku,
                'barcode' => $p->barcode,
                'unit' => $p->unit,
                'cost_price' => (float) $p->cost_price,
                'selling_price' => (float) $p->selling_price,
                'tax_rate' => (float) $p->tax_rate,
                'min_stock_level' => (int) $p->min_stock_level,
                'stock_quantity' => (float) $stock,
                'category' => $p->category ? [
                    'uuid' => $p->category->uuid,
                    'name' => $p->category->name,
                ] : null,
                'brand' => $p->brand ? [
                    'uuid' => $p->brand->uuid,
                    'name' => $p->brand->name,
                ] : null,
                'has_variants' => (bool) $p->has_variants,
                'variants' => $p->variants->map(fn ($v) => [
                    'id' => $v->id,
                    'uuid' => $v->uuid,
                    'name' => $v->name,
                    'sku' => $v->sku,
                    'barcode' => $v->barcode,
                    'cost_price' => (float) $v->cost_price,
                    'selling_price' => (float) $v->selling_price,
                ]),
            ];
        });

        return response()->json([
            'status' => 'success',
            'data' => $transformed,
            'meta' => [
                'current_page' => $products->currentPage(),
                'last_page' => $products->lastPage(),
                'per_page' => $products->perPage(),
                'total' => $products->total(),
            ],
        ]);
    }

    /**
     * Fast barcode lookup for scanner input.
     */
    public function byBarcode(Request $request, string $barcode): JsonResponse
    {
        $user = $request->user();
        $storeId = $user?->store_id ?? 1;

        $product = Product::with(['category', 'brand', 'variants', 'inventories' => function ($q) use ($storeId) {
            $q->where('store_id', $storeId);
        }])
            ->where(function ($q) use ($barcode) {
                $q->where('barcode', $barcode)->orWhere('sku', $barcode);
            })
            ->where('is_active', true)
            ->first();

        if (!$product) {
            return response()->json(['status' => 'error', 'message' => 'Product not found for barcode.'], 404);
        }

        $stock = $product->inventories->first()?->quantity_on_hand ?? 0.00;

        return response()->json([
            'status' => 'success',
            'product' => [
                'id' => $product->id,
                'uuid' => $product->uuid,
                'name' => $product->name,
                'sku' => $product->sku,
                'barcode' => $product->barcode,
                'unit' => $product->unit,
                'cost_price' => (float) $product->cost_price,
                'selling_price' => (float) $product->selling_price,
                'tax_rate' => (float) $product->tax_rate,
                'stock_quantity' => (float) $stock,
                'category_name' => $product->category?->name,
            ],
        ]);
    }

    /**
     * List all categories.
     */
    public function categories(): JsonResponse
    {
        $categories = Category::where('is_active', true)
            ->orderBy('display_order')
            ->get(['id', 'uuid', 'name', 'slug']);

        return response()->json(['status' => 'success', 'data' => $categories]);
    }

    /**
     * List all brands.
     */
    public function brands(): JsonResponse
    {
        $brands = Brand::where('is_active', true)->get(['id', 'uuid', 'name', 'slug']);
        return response()->json(['status' => 'success', 'data' => $brands]);
    }
}
