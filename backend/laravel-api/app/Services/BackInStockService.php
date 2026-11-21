<?php

namespace App\Services;

use App\Models\BackInStockSubscription;
use App\Models\Customer;
use App\Models\CustomerNotification;
use App\Models\Product;
use App\Models\Store;
use Carbon\Carbon;

class BackInStockService
{
    public function __construct(
        protected SmsService $smsService,
        protected CustomerNotifier $customerNotifier
    ) {}

    /**
     * Subscribe a customer or guest to receive an automated SMS/in-app alert when a product is restocked.
     */
    public function subscribe(Product $product, array $data): BackInStockSubscription
    {
        $phone = ! empty($data['phone']) ? trim((string) $data['phone']) : null;
        $email = ! empty($data['email']) ? strtolower(trim((string) $data['email'])) : null;
        $customerId = $data['customer_id'] ?? null;
        $storeId = $data['store_id'] ?? null;

        $existingQuery = BackInStockSubscription::where('product_id', $product->id)
            ->where('status', 'subscribed');

        if ($customerId) {
            $existingQuery->where('customer_id', $customerId);
        } elseif ($phone) {
            $existingQuery->where('phone', $phone);
        } elseif ($email) {
            $existingQuery->where('email', $email);
        }

        $existing = $existingQuery->first();
        if ($existing) {
            return $existing;
        }

        return BackInStockSubscription::create([
            'product_id' => $product->id,
            'store_id' => $storeId,
            'customer_id' => $customerId,
            'customer_name' => $data['customer_name'] ?? 'OmniLuxe Client',
            'phone' => $phone,
            'email' => $email,
            'status' => 'subscribed',
        ]);
    }

    /**
     * Automatically notify active subscribers via SMS + Reverb/FCM inbox when stock transitions from <= 0 to > 0.
     */
    public function notifySubscribersOnRestock(Product $product, ?Store $store = null): int
    {
        $subscribers = BackInStockSubscription::with('customer')
            ->where('product_id', $product->id)
            ->where('status', 'subscribed')
            ->where(function ($q) use ($store) {
                $q->whereNull('store_id');
                if ($store) {
                    $q->orWhere('store_id', $store->id);
                }
            })
            ->get();

        if ($subscribers->isEmpty()) {
            return 0;
        }

        $storeLabel = $store?->name ?? 'OmniLuxe Flagship';
        $notifiedCount = 0;

        foreach ($subscribers as $sub) {
            $smsMessage = "OmniLuxe Store: Good news! {$product->name} is back in stock at {$storeLabel}. Reserve yours now at omniluxe.store/product/{$product->id}";

            if (! empty($sub->phone)) {
                $this->smsService->dispatch(
                    to: $sub->phone,
                    message: $smsMessage,
                    eventType: 'back_in_stock',
                    options: [
                        'store_id' => $store?->id,
                        'customer_id' => $sub->customer_id,
                        'metadata' => [
                            'product_id' => $product->id,
                            'product_sku' => $product->sku,
                        ],
                    ]
                );
            }

            if ($sub->customer instanceof Customer) {
                $this->customerNotifier->notify(
                    customer: $sub->customer,
                    type: CustomerNotification::TYPE_PROMO,
                    title: "{$product->name} is Back in Stock",
                    body: "Fresh inventory just arrived at {$storeLabel}. Tap to view before it sells out.",
                    data: [
                        'product_id' => $product->id,
                        'product_uuid' => $product->uuid,
                        'store_name' => $storeLabel,
                    ]
                );
            }

            $sub->update([
                'status' => 'notified',
                'notified_at' => Carbon::now(),
            ]);

            $notifiedCount++;
        }

        return $notifiedCount;
    }
}
