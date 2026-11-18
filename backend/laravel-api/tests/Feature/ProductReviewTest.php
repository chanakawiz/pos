<?php

namespace Tests\Feature;

use App\Models\Brand;
use App\Models\Category;
use App\Models\Customer;
use App\Models\Inventory;
use App\Models\Product;
use App\Models\ProductReview;
use App\Models\Sale;
use App\Models\SaleItem;
use App\Models\Store;
use App\Models\User;
use App\Services\ReviewService;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class ProductReviewTest extends TestCase
{
    use DatabaseTransactions;

    protected Store $store;
    protected User $cashier;
    protected Customer $customer;
    protected Product $product;
    protected ReviewService $reviewService;

    protected function setUp(): void
    {
        parent::setUp();

        $this->store = Store::firstOrCreate(
            ['code' => 'STORE-REV-TEST'],
            [
                'name' => 'OmniLuxe Review Test Hub',
                'phone' => '+94 11 234 5678',
                'currency_symbol' => 'Rs.',
                'address' => '420 Galle Road, Colombo 03',
                'is_active' => true,
            ]
        );

        $this->cashier = User::firstOrCreate(
            ['email' => 'cashier_rev_test@omniluxe.store'],
            [
                'name' => 'Review Cashier',
                'password' => bcrypt('password'),
                'store_id' => $this->store->id,
                'role' => 'cashier',
            ]
        );

        $this->customer = Customer::firstOrCreate(
            ['phone' => '0779988112'],
            [
                'name' => 'Elena Rostova',
                'email' => 'elena@omniluxe.test',
                'loyalty_points' => 300,
            ]
        );

        $category = Category::firstOrCreate(['slug' => 'rev-cat-test'], ['name' => 'Luxury Timepieces']);
        $brand = Brand::firstOrCreate(['slug' => 'rev-brand-test'], ['name' => 'Chronos']);

        $this->product = Product::firstOrCreate(
            ['sku' => 'SKU-REV-001'],
            [
                'name' => 'Chronos Royal Skeleton Watch',
                'barcode' => '9988776655443',
                'cost_price' => 85000.00,
                'selling_price' => 145000.00,
                'category_id' => $category->id,
                'brand_id' => $brand->id,
                'is_active' => true,
            ]
        );

        $this->reviewService = app(ReviewService::class);
    }

    public function test_can_submit_review_with_verified_buyer_detection(): void
    {
        // 1. Create completed sale for customer with this product
        $sale = Sale::create([
            'uuid' => (string) \Illuminate\Support\Str::uuid(),
            'transaction_uuid' => (string) \Illuminate\Support\Str::uuid(),
            'invoice_number' => 'INV-REV-VERIFIED-01',
            'store_id' => $this->store->id,
            'cashier_id' => $this->cashier->id,
            'customer_id' => $this->customer->id,
            'subtotal' => 145000.00,
            'total_amount' => 145000.00,
            'payment_status' => 'paid',
            'sold_at' => now(),
            'channel' => 'in_store',
        ]);

        SaleItem::create([
            'sale_id' => $sale->id,
            'product_id' => $this->product->id,
            'quantity' => 1,
            'unit_price' => 145000.00,
            'subtotal' => 145000.00,
        ]);

        // 2. Submit review as customer
        $review = $this->reviewService->submitReview($this->product, [
            'rating' => 5,
            'title' => 'Exquisite horology masterpiece',
            'comment' => 'The open-heart skeleton mechanism is stunning in person. Delivery and packaging were top tier.',
        ], $this->customer);

        $this->assertInstanceOf(ProductReview::class, $review);
        $this->assertTrue($review->is_verified_purchase);
        $this->assertEquals(5, $review->rating);
        $this->assertEquals('approved', $review->status);
        $this->assertEquals('Elena Rostova', $review->customer_name);

        $this->assertDatabaseHas('product_reviews', [
            'id' => $review->id,
            'is_verified_purchase' => true,
            'rating' => 5,
        ]);
    }

    public function test_unverified_buyer_for_non_purchaser(): void
    {
        $nonBuyer = Customer::firstOrCreate(
            ['phone' => '0770009988'],
            ['name' => 'Casual Visitor', 'email' => 'visitor@omniluxe.test']
        );

        $review = $this->reviewService->submitReview($this->product, [
            'rating' => 4,
            'title' => 'Looks great on display',
            'comment' => 'Tried it in the flagship store. Very impressive finish.',
        ], $nonBuyer);

        $this->assertFalse($review->is_verified_purchase);
        $this->assertEquals(4, $review->rating);
    }

    public function test_review_summary_computes_accurate_aggregates(): void
    {
        // Seed 3 reviews: two 5-star and one 4-star
        $this->reviewService->submitReview($this->product, [
            'rating' => 5,
            'customer_name' => 'Client A',
            'comment' => 'First 5-star review',
        ]);

        $this->reviewService->submitReview($this->product, [
            'rating' => 5,
            'customer_name' => 'Client B',
            'comment' => 'Second 5-star review',
        ]);

        $this->reviewService->submitReview($this->product, [
            'rating' => 4,
            'customer_name' => 'Client C',
            'comment' => 'Third 4-star review',
        ]);

        $summary = $this->reviewService->getSummary($this->product);

        $this->assertEquals(3, $summary['reviews_count']);
        // Average of (5 + 5 + 4) / 3 = 14 / 3 = 4.666... rounded to 4.7
        $this->assertEquals(4.7, $summary['average_rating']);
        $this->assertEquals(2, $summary['distribution'][5]);
        $this->assertEquals(1, $summary['distribution'][4]);
        $this->assertEquals(0, $summary['distribution'][3]);
    }

    public function test_can_vote_helpful_on_review(): void
    {
        $review = $this->reviewService->submitReview($this->product, [
            'rating' => 5,
            'customer_name' => 'Helpful Reviewer',
            'comment' => 'Comprehensive detailed sizing and finish review.',
        ]);

        $this->assertEquals(0, $review->helpful_votes);

        $votes = $this->reviewService->voteHelpful($review);
        $this->assertEquals(1, $votes);

        $votesAgain = $this->reviewService->voteHelpful($review);
        $this->assertEquals(2, $votesAgain);

        $this->assertDatabaseHas('product_reviews', [
            'id' => $review->id,
            'helpful_votes' => 2,
        ]);
    }

    public function test_api_can_fetch_product_reviews_and_summary(): void
    {
        $this->reviewService->submitReview($this->product, [
            'rating' => 5,
            'title' => 'API Review Title',
            'comment' => 'Testing public API endpoint response.',
            'customer_name' => 'API Tester',
        ]);

        $response = $this->getJson("/api/v1/products/{$this->product->id}/reviews");

        $response->assertStatus(200)
            ->assertJsonPath('status', 'success')
            ->assertJsonStructure([
                'status',
                'product' => ['id', 'uuid', 'name'],
                'summary' => ['average_rating', 'reviews_count', 'distribution'],
                'data' => [
                    '*' => ['id', 'uuid', 'rating', 'title', 'comment', 'customer_name', 'is_verified_purchase'],
                ],
                'meta' => ['current_page', 'total'],
            ]);
    }

    public function test_api_can_submit_product_review(): void
    {
        $response = $this->postJson("/api/v1/products/{$this->product->id}/reviews", [
            'rating' => 5,
            'title' => 'Submitted via API',
            'comment' => 'Seamless experience and top performance.',
            'customer_name' => 'Mobile Shopper',
            'customer_email' => 'mobile@omniluxe.test',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('data.rating', 5)
            ->assertJsonPath('data.title', 'Submitted via API');

        $this->assertDatabaseHas('product_reviews', [
            'product_id' => $this->product->id,
            'customer_name' => 'Mobile Shopper',
            'rating' => 5,
        ]);
    }

    public function test_web_store_review_submission(): void
    {
        $response = $this->post("/product/{$this->product->id}/review", [
            'rating' => 5,
            'title' => 'Web Storefront Review',
            'comment' => 'Submitting directly from product blade page.',
            'customer_name' => 'Web Customer',
            'customer_email' => 'web@omniluxe.test',
        ]);

        $response->assertRedirect();
        $response->assertSessionHas('success');

        $this->assertDatabaseHas('product_reviews', [
            'product_id' => $this->product->id,
            'title' => 'Web Storefront Review',
        ]);
    }
}
