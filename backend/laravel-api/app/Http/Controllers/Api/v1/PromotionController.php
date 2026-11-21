<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Promotion;
use App\Services\PromotionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PromotionController extends Controller
{
    public function __construct(
        protected PromotionService $promotionService
    ) {}

    /**
     * Publicly list active omnichannel promotions (optionally filtered by channel).
     */
    public function active(Request $request): JsonResponse
    {
        $channel = $request->query('channel');
        $campaigns = $this->promotionService->getActiveCampaigns($channel);

        return response()->json([
            'status' => 'success',
            'data' => $campaigns->map(fn (Promotion $p) => [
                'uuid' => $p->uuid,
                'code' => $p->code,
                'name' => $p->name,
                'description' => $p->description,
                'type' => $p->type,
                'value' => (float) $p->value,
                'discount_label' => $p->discount_label,
                'min_order_amount' => (float) $p->min_order_amount,
                'max_discount_amount' => $p->max_discount_amount !== null ? (float) $p->max_discount_amount : null,
                'vip_tier_required' => $p->vip_tier_required,
                'is_auto_apply' => $p->is_auto_apply,
                'ends_at' => $p->ends_at?->toIso8601String(),
            ]),
        ]);
    }

    /**
     * Validate a coupon code and compute exact discount for any channel (web, mobile, pos).
     */
    public function validateCode(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'code' => 'required|string|max:64',
            'subtotal' => 'required|numeric|min:0',
            'channel' => 'nullable|string|in:web,mobile,pos',
            'customer_uuid' => 'nullable|string',
            'vip_tier' => 'nullable|string|in:silver,gold,black',
            'items' => 'nullable|array',
        ]);

        $customer = null;
        if (! empty($validated['customer_uuid'])) {
            $customer = Customer::where('uuid', $validated['customer_uuid'])->first();
        }

        $result = $this->promotionService->validateAndCalculate(
            code: $validated['code'],
            subtotal: (float) $validated['subtotal'],
            options: [
                'channel' => $validated['channel'] ?? 'web',
                'customer' => $customer,
                'vip_tier' => $validated['vip_tier'] ?? $customer?->vip_tier,
                'items' => $validated['items'] ?? [],
            ]
        );

        if (! $result['valid']) {
            return response()->json([
                'status' => 'error',
                'message' => $result['message'],
            ], 422);
        }

        return response()->json([
            'status' => 'success',
            'message' => $result['message'],
            'data' => [
                'code' => $result['code'],
                'name' => $result['name'],
                'type' => $result['type'],
                'discount_label' => $result['discount_label'],
                'discount_amount' => $result['discount_amount'],
                'subtotal' => $result['subtotal'],
                'final_total' => $result['final_total'],
            ],
        ]);
    }

    /**
     * Staff/ERP: List all promotion campaigns with redemption counts.
     */
    public function index(Request $request): JsonResponse
    {
        $promotions = Promotion::with('category:id,name')
            ->latest()
            ->paginate(25);

        return response()->json([
            'status' => 'success',
            'data' => $promotions,
        ]);
    }

    /**
     * Staff/ERP: Create a new promotion campaign.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'code' => 'required|string|max:64|unique:promotions,code',
            'name' => 'required|string|max:191',
            'description' => 'nullable|string|max:500',
            'type' => 'required|in:percentage,fixed_amount,buy_x_get_y',
            'value' => 'nullable|numeric|min:0',
            'buy_quantity' => 'nullable|integer|min:1',
            'get_quantity' => 'nullable|integer|min:1',
            'min_order_amount' => 'nullable|numeric|min:0',
            'max_discount_amount' => 'nullable|numeric|min:0',
            'max_uses' => 'nullable|integer|min:1',
            'max_uses_per_customer' => 'nullable|integer|min:1',
            'allowed_channels' => 'nullable|array',
            'applicable_category_id' => 'nullable|exists:categories,id',
            'vip_tier_required' => 'nullable|in:silver,gold,black',
            'is_auto_apply' => 'nullable|boolean',
            'is_active' => 'nullable|boolean',
            'starts_at' => 'nullable|date',
            'ends_at' => 'nullable|date|after_or_equal:starts_at',
        ]);

        $promotion = Promotion::create($validated);

        return response()->json([
            'status' => 'success',
            'message' => 'Promotion campaign created.',
            'promotion' => $promotion,
        ], 201);
    }

    /**
     * Staff/ERP: Toggle promotion active/paused status.
     */
    public function toggle(string $uuid): JsonResponse
    {
        $promotion = Promotion::where('uuid', $uuid)->firstOrFail();
        $promotion->update(['is_active' => ! $promotion->is_active]);

        return response()->json([
            'status' => 'success',
            'message' => $promotion->is_active ? 'Promotion activated.' : 'Promotion paused.',
            'promotion' => $promotion->fresh(),
        ]);
    }
}
