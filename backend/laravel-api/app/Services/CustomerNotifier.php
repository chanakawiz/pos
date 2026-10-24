<?php

namespace App\Services;

use App\Events\CustomerNotificationCreated;
use App\Jobs\SendCustomerPushNotification;
use App\Models\Customer;
use App\Models\CustomerNotification;
use App\Models\Sale;

/**
 * Single entry point for customer-facing notifications.
 *
 *   1. Persist to customer_notifications   (source of truth / inbox)
 *   2. Reverb  → private-customer.{uuid}   (open web store tab / open app)
 *   3. FCM     → every registered device   (app in background / closed)
 *
 * Both deliveries are deferred until the surrounding transaction commits.
 */
class CustomerNotifier
{
    public function notify(Customer $customer, string $type, string $title, string $body, array $data = []): CustomerNotification
    {
        $notification = $customer->notifications()->create([
            'type' => $type,
            'title' => $title,
            'body' => $body,
            'data' => $data,
        ]);

        $notification->setRelation('customer', $customer);

        CustomerNotificationCreated::dispatch($notification);
        SendCustomerPushNotification::dispatch($notification);

        return $notification;
    }

    public function orderConfirmed(Sale $sale): ?CustomerNotification
    {
        $customer = $sale->customer;
        if (! $customer) {
            return null;
        }

        return $this->notify(
            $customer,
            CustomerNotification::TYPE_ORDER,
            "Order {$sale->invoice_number} confirmed",
            'Thank you. Your order is confirmed and your digital receipt is ready.',
            [
                'invoice_number' => $sale->invoice_number,
                'total' => (float) $sale->total_amount,
                'receipt_path' => '/receipt/'.$sale->invoice_number,
            ]
        );
    }

    public function loyaltyCredited(Customer $customer, int $points, ?string $invoiceNumber = null): ?CustomerNotification
    {
        if ($points <= 0) {
            return null;
        }

        return $this->notify(
            $customer,
            CustomerNotification::TYPE_LOYALTY,
            "+{$points} Privilege points",
            "Your balance is now {$customer->loyalty_points} points.",
            [
                'points' => $points,
                'balance' => (int) $customer->loyalty_points,
                'invoice_number' => $invoiceNumber,
            ]
        );
    }
}
