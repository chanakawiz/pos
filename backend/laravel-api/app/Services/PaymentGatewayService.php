<?php

namespace App\Services;

use App\Models\Payment;
use App\Models\PaymentTransaction;
use App\Models\Sale;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class PaymentGatewayService
{
    public function __construct(
        protected CustomerNotifier $customerNotifier
    ) {}

    /**
     * Initiate a gateway payment transaction session for a sale.
     */
    public function initiate(Sale $sale, string $gateway = 'payhere', array $options = []): PaymentTransaction
    {
        $amount = (float) $sale->total_amount;
        $currency = $sale->store?->currency_code ?? config('services.payhere.currency', 'LKR');
        $transactionUuid = (string) Str::uuid();

        $merchantId = config('services.payhere.merchant_id', env('PAYHERE_MERCHANT_ID', '1210001'));
        $merchantSecret = config('services.payhere.merchant_secret', env('PAYHERE_MERCHANT_SECRET', 'omniluxe_secret_sandbox'));

        $gatewayPayload = [];

        if ($gateway === 'payhere') {
            // PayHere standard MD5 Hash: strtoupper(md5($merchant_id . $order_id . number_format($amount, 2, '.', '') . $currency . strtoupper(md5($merchant_secret))))
            $hash = strtoupper(
                md5(
                    $merchantId .
                    $sale->invoice_number .
                    number_format($amount, 2, '.', '') .
                    $currency .
                    strtoupper(md5($merchantSecret))
                )
            );

            $gatewayPayload = [
                'merchant_id' => $merchantId,
                'return_url' => url("/checkout/payment/{$transactionUuid}/success"),
                'cancel_url' => url("/checkout/payment/{$transactionUuid}/cancel"),
                'notify_url' => url('/api/v1/payments/webhook/payhere'),
                'order_id' => $sale->invoice_number,
                'items' => "OmniLuxe Store Order #{$sale->invoice_number}",
                'currency' => $currency,
                'amount' => number_format($amount, 2, '.', ''),
                'first_name' => $sale->customer?->name ?? 'Guest Customer',
                'last_name' => '',
                'email' => $sale->customer?->email ?? 'guest@omniluxe.store',
                'phone' => $sale->customer?->phone ?? '0770000000',
                'address' => $sale->customer?->address ?? 'Flagship Boutique Delivery',
                'city' => 'Colombo',
                'country' => 'Sri Lanka',
                'hash' => $hash,
                'action_url' => env('PAYHERE_MODE', 'sandbox') === 'live' 
                    ? 'https://www.payhere.lk/pay/checkout' 
                    : 'https://sandbox.payhere.lk/pay/checkout',
            ];
        } elseif ($gateway === 'stripe') {
            $gatewayPayload = [
                'order_id' => $sale->invoice_number,
                'amount_cents' => (int) round($amount * 100),
                'currency' => strtolower($currency),
                'public_key' => config('services.stripe.key', env('STRIPE_KEY', 'pk_test_sample')),
                'client_secret' => 'pi_simulated_' . Str::random(24) . '_secret_' . Str::random(16),
            ];
        } else {
            // Mock sandbox driver
            $gatewayPayload = [
                'order_id' => $sale->invoice_number,
                'amount' => $amount,
                'currency' => $currency,
                'mode' => 'instant_sandbox',
            ];
        }

        return PaymentTransaction::create([
            'uuid' => $transactionUuid,
            'sale_id' => $sale->id,
            'customer_id' => $sale->customer_id,
            'gateway' => $gateway,
            'gateway_reference' => $gatewayPayload['order_id'] ?? $sale->invoice_number,
            'amount' => $amount,
            'currency' => $currency,
            'status' => 'pending',
            'payload_json' => $gatewayPayload,
        ]);
    }

    /**
     * Verify PayHere incoming webhook signature.
     */
    public function verifyPayHereSignature(array $payload): bool
    {
        $merchantId = config('services.payhere.merchant_id', env('PAYHERE_MERCHANT_ID', '1210001'));
        $merchantSecret = config('services.payhere.merchant_secret', env('PAYHERE_MERCHANT_SECRET', 'omniluxe_secret_sandbox'));

        $orderId = $payload['order_id'] ?? '';
        $payhereAmount = $payload['payhere_amount'] ?? '';
        $payhereCurrency = $payload['payhere_currency'] ?? '';
        $statusCode = $payload['status_code'] ?? '';
        $md5sig = $payload['md5sig'] ?? '';

        $localMd5sig = strtoupper(
            md5(
                $merchantId .
                $orderId .
                $payhereAmount .
                $payhereCurrency .
                $statusCode .
                strtoupper(md5($merchantSecret))
            )
        );

        return hash_equals($localMd5sig, $md5sig);
    }

    /**
     * Verify Stripe webhook signature header.
     */
    public function verifyStripeSignature(string $rawPayload, string $sigHeader): bool
    {
        $secret = config('services.stripe.webhook_secret', env('STRIPE_WEBHOOK_SECRET', 'whsec_sample'));
        if (empty($secret) || empty($sigHeader)) {
            return false;
        }

        // Parse timestamp and v1 signatures
        $sigItems = [];
        foreach (explode(',', $sigHeader) as $item) {
            $parts = explode('=', trim($item), 2);
            if (count($parts) === 2) {
                $sigItems[$parts[0]][] = $parts[1];
            }
        }

        $timestamp = $sigItems['t'][0] ?? null;
        $signatures = $sigItems['v1'] ?? [];

        if (! $timestamp || empty($signatures)) {
            return false;
        }

        $signedPayload = "{$timestamp}.{$rawPayload}";
        $expected = hash_hmac('sha256', $signedPayload, $secret);

        foreach ($signatures as $signature) {
            if (hash_equals($expected, $signature)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Complete a payment transaction atomically.
     */
    public function completeTransaction(PaymentTransaction $transaction, array $responseDetails = []): bool
    {
        if ($transaction->status === 'completed') {
            return true;
        }

        return DB::transaction(function () use ($transaction, $responseDetails) {
            $transaction->update([
                'status' => 'completed',
                'gateway_reference' => $responseDetails['payment_id'] ?? $responseDetails['transaction_id'] ?? $transaction->gateway_reference,
                'response_json' => $responseDetails,
                'paid_at' => now(),
            ]);

            $sale = $transaction->sale;
            if ($sale) {
                $sale->update([
                    'payment_status' => 'paid',
                    'paid_amount' => $transaction->amount,
                ]);

                // Create recorded payment entry in ledger
                Payment::create([
                    'uuid' => (string) Str::uuid(),
                    'sale_id' => $sale->id,
                    'payment_method' => 'card',
                    'amount' => $transaction->amount,
                    'reference_number' => $transaction->gateway_reference ?? ('GW-' . substr($transaction->uuid, 0, 8)),
                    'paid_at' => now(),
                ]);

                // Dispatches Reverb event + FCM push notification + DB inbox
                $this->customerNotifier->orderConfirmed($sale);

                Log::info("Payment transaction {$transaction->uuid} completed successfully for invoice {$sale->invoice_number}.");
            }

            return true;
        });
    }

    /**
     * Mark transaction as failed or cancelled.
     */
    public function failTransaction(PaymentTransaction $transaction, string $status = 'failed', array $responseDetails = []): bool
    {
        return $transaction->update([
            'status' => in_array($status, ['failed', 'cancelled']) ? $status : 'failed',
            'response_json' => $responseDetails,
        ]);
    }
}
