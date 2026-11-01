<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\GiftCard;
use App\Models\Sale;
use App\Services\GiftCardService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use InvalidArgumentException;

class GiftCardController extends Controller
{
    public function __construct(
        protected GiftCardService $giftCardService
    ) {}

    /**
     * List active gift cards.
     */
    public function index(Request $request): JsonResponse
    {
        $cards = GiftCard::with(['customer:id,name,phone', 'store:id,name', 'issuer:id,name'])
            ->when($request->query('status'), fn ($q, $status) => $q->where('status', $status))
            ->when($request->query('search'), function ($q, $search) {
                $q->where('code', 'like', "%{$search}%")
                  ->orWhereHas('customer', fn ($cq) => $cq->where('name', 'like', "%{$search}%")->orWhere('phone', 'like', "%{$search}%"));
            })
            ->latest('id')
            ->paginate($request->query('per_page', 20));

        return response()->json([
            'status' => 'success',
            'data' => $cards,
        ]);
    }

    /**
     * Verify gift card balance & validity (Public & In-Store Cashier).
     */
    public function verify(Request $request): JsonResponse
    {
        $request->validate([
            'code' => ['required', 'string', 'max:64'],
        ]);

        $result = $this->giftCardService->checkBalance($request->string('code'));

        if (!$result['found']) {
            return response()->json([
                'status' => 'error',
                'message' => $result['message'],
            ], 404);
        }

        if (!$result['valid']) {
            return response()->json([
                'status' => 'error',
                'message' => $result['message'],
                'data' => $result,
            ], 422);
        }

        return response()->json([
            'status' => 'success',
            'data' => $result,
        ]);
    }

    /**
     * Issue a new gift card (Admin, Manager, Cashier).
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'amount' => ['required', 'numeric', 'min:100'],
            'customer_id' => ['nullable', 'exists:customers,id'],
            'store_id' => ['nullable', 'exists:stores,id'],
            'expires_at' => ['nullable', 'date', 'after:today'],
            'notes' => ['nullable', 'string', 'max:500'],
        ]);

        $user = $request->user();
        $storeId = $validated['store_id'] ?? $user?->store_id;

        $card = $this->giftCardService->issueCard(
            amount: (float) $validated['amount'],
            customerId: $validated['customer_id'] ?? null,
            storeId: $storeId ? (int) $storeId : null,
            userId: $user?->id,
            expiresAt: $validated['expires_at'] ?? null,
            notes: $validated['notes'] ?? null,
        );

        return response()->json([
            'status' => 'success',
            'message' => "Gift card {$card->code} issued successfully with credit of Rs. {$card->initial_amount}.",
            'data' => $card,
        ], 201);
    }

    /**
     * Redeem a gift card against a sale or bill.
     */
    public function redeem(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'code' => ['required', 'string'],
            'amount' => ['required', 'numeric', 'min:1'],
            'sale_uuid' => ['nullable', 'string'],
            'notes' => ['nullable', 'string'],
        ]);

        $sale = null;
        if (!empty($validated['sale_uuid'])) {
            $sale = Sale::where('uuid', $validated['sale_uuid'])
                ->orWhere('invoice_number', $validated['sale_uuid'])
                ->first();
        }

        try {
            $user = $request->user();
            $result = $this->giftCardService->redeemCard(
                code: $validated['code'],
                amount: (float) $validated['amount'],
                sale: $sale,
                store: $user?->store,
                user: $user,
                notes: $validated['notes'] ?? null,
            );

            return response()->json([
                'status' => 'success',
                'message' => "Successfully redeemed Rs. {$result['redeemed_amount']} from gift card.",
                'data' => [
                    'redeemed_amount' => $result['redeemed_amount'],
                    'remaining_balance' => $result['remaining_balance'],
                    'transaction_uuid' => $result['transaction']->uuid,
                    'code' => $result['card']->code,
                ],
            ]);
        } catch (InvalidArgumentException $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage(),
            ], 422);
        }
    }
}
