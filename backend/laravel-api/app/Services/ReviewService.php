<?php

namespace App\Services;

use App\Models\Customer;
use App\Models\Product;
use App\Models\ProductReview;
use App\Models\SaleItem;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class ReviewService
{
    /**
     * Check if a customer has genuinely purchased this product in a completed sale.
     */
    public function checkVerifiedPurchase(int $productId, ?int $customerId = null, ?string $email = null, ?string $phone = null): bool
    {
        $query = SaleItem::query()
            ->where('product_id', $productId)
            ->whereHas('sale', function (Builder $saleQuery) use ($customerId, $email, $phone) {
                $saleQuery->whereIn('payment_status', ['paid', 'partially_refunded'])
                    ->where(function (Builder $sub) use ($customerId, $email, $phone) {
                        $hasMatch = false;

                        if ($customerId) {
                            $sub->where('customer_id', $customerId);
                            $hasMatch = true;
                        }

                        if ($email) {
                            $sub->orWhereHas('customer', fn ($cq) => $cq->where('email', $email));
                            $hasMatch = true;
                        }

                        if ($phone) {
                            $sub->orWhereHas('customer', fn ($cq) => $cq->where('phone', $phone));
                            $hasMatch = true;
                        }

                        if (!$hasMatch) {
                            $sub->whereRaw('1 = 0');
                        }
                    });
            });

        return $query->exists();
    }

    /**
     * Submit a customer review for a product.
     */
    public function submitReview(Product $product, array $data, ?Customer $customer = null): ProductReview
    {
        $rating = (int) ($data['rating'] ?? 5);
        if ($rating < 1 || $rating > 5) {
            throw new InvalidArgumentException('Review rating must be between 1 and 5 stars.');
        }

        $customerName = trim($customer?->name ?: ($data['customer_name'] ?? 'OmniLuxe Guest'));
        $customerEmail = trim($customer?->email ?: ($data['customer_email'] ?? ''));
        $customerPhone = $customer?->phone ?: ($data['customer_phone'] ?? null);

        $isVerified = $this->checkVerifiedPurchase(
            $product->id,
            $customer?->id,
            $customerEmail ?: null,
            $customerPhone ?: null
        );

        return ProductReview::create([
            'product_id' => $product->id,
            'customer_id' => $customer?->id,
            'store_id' => $data['store_id'] ?? null,
            'customer_name' => $customerName,
            'customer_email' => $customerEmail ?: null,
            'rating' => $rating,
            'title' => !empty($data['title']) ? trim($data['title']) : null,
            'comment' => trim($data['comment'] ?? ''),
            'photos' => $data['photos'] ?? null,
            'is_verified_purchase' => $isVerified,
            'status' => $data['status'] ?? 'approved',
            'helpful_votes' => 0,
        ]);
    }

    /**
     * Compute star rating aggregates, verified badge counts, and star distribution.
     */
    public function getSummary(Product $product): array
    {
        $reviews = $product->approvedReviews()->get();
        $total = $reviews->count();

        if ($total === 0) {
            return [
                'average_rating' => 5.0,
                'reviews_count' => 0,
                'verified_count' => 0,
                'verified_percentage' => 0,
                'distribution' => [5 => 0, 4 => 0, 3 => 0, 2 => 0, 1 => 0],
                'distribution_percentages' => [5 => 0, 4 => 0, 3 => 0, 2 => 0, 1 => 0],
            ];
        }

        $avg = round($reviews->avg('rating'), 1);
        $verifiedCount = $reviews->where('is_verified_purchase', true)->count();

        $distribution = [
            5 => $reviews->where('rating', 5)->count(),
            4 => $reviews->where('rating', 4)->count(),
            3 => $reviews->where('rating', 3)->count(),
            2 => $reviews->where('rating', 2)->count(),
            1 => $reviews->where('rating', 1)->count(),
        ];

        $percentages = [];
        foreach ($distribution as $star => $count) {
            $percentages[$star] = round(($count / $total) * 100);
        }

        return [
            'average_rating' => $avg,
            'reviews_count' => $total,
            'verified_count' => $verifiedCount,
            'verified_percentage' => round(($verifiedCount / $total) * 100),
            'distribution' => $distribution,
            'distribution_percentages' => $percentages,
        ];
    }

    /**
     * Cast a helpful vote on a review.
     */
    public function voteHelpful(ProductReview $review): int
    {
        $review->increment('helpful_votes');
        return (int) $review->fresh()->helpful_votes;
    }
}
