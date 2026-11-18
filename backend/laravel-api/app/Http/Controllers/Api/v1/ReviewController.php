<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Product;
use App\Models\ProductReview;
use App\Services\ReviewService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReviewController extends Controller
{
    public function __construct(protected ReviewService $reviewService) {}

    /**
     * Get approved reviews and rating summary for a product.
     */
    public function index(Request $request, string $identifier): JsonResponse
    {
        $product = is_numeric($identifier)
            ? Product::findOrFail($identifier)
            : Product::where('uuid', $identifier)->firstOrFail();

        $query = $product->approvedReviews()
            ->latest('id');

        if ($request->filled('rating')) {
            $query->where('rating', (int) $request->rating);
        }

        if ($request->boolean('verified_only')) {
            $query->where('is_verified_purchase', true);
        }

        $perPage = min((int) ($request->get('per_page', 10)), 50);
        $reviews = $query->paginate($perPage);

        $summary = $this->reviewService->getSummary($product);

        return response()->json([
            'status' => 'success',
            'product' => [
                'id' => $product->id,
                'uuid' => $product->uuid,
                'name' => $product->name,
            ],
            'summary' => $summary,
            'data' => $reviews->items(),
            'meta' => [
                'current_page' => $reviews->currentPage(),
                'last_page' => $reviews->lastPage(),
                'total' => $reviews->total(),
                'per_page' => $reviews->perPage(),
            ],
        ]);
    }

    /**
     * Submit a customer review for a product.
     */
    public function store(Request $request, string $identifier): JsonResponse
    {
        $product = is_numeric($identifier)
            ? Product::findOrFail($identifier)
            : Product::where('uuid', $identifier)->firstOrFail();

        $validated = $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'title' => 'nullable|string|max:150',
            'comment' => 'required|string|min:5|max:2000',
            'customer_name' => 'nullable|string|max:100',
            'customer_email' => 'nullable|email|max:150',
            'customer_phone' => 'nullable|string|max:32',
            'photos' => 'nullable|array|max:5',
            'photos.*' => 'string|url',
        ]);

        $user = $request->user();
        $customer = null;
        if ($user) {
            $customer = Customer::where('email', $user->email)->first();
        }

        $review = $this->reviewService->submitReview($product, $validated, $customer);
        $summary = $this->reviewService->getSummary($product);

        return response()->json([
            'status' => 'success',
            'message' => $review->is_verified_purchase
                ? 'Thank you! Your verified purchase review has been published.'
                : 'Thank you! Your review has been published.',
            'data' => $review,
            'summary' => $summary,
        ], 201);
    }

    /**
     * Upvote a review as helpful.
     */
    public function voteHelpful(string $uuid): JsonResponse
    {
        $review = ProductReview::where('uuid', $uuid)->firstOrFail();
        $newVotes = $this->reviewService->voteHelpful($review);

        return response()->json([
            'status' => 'success',
            'message' => 'Feedback recorded. Thank you!',
            'helpful_votes' => $newVotes,
        ]);
    }
}
