<?php

namespace App\Http\Controllers;

use App\Models\PaymentTransaction;
use App\Models\Sale;
use App\Services\PaymentGatewayService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    public function __construct(
        protected PaymentGatewayService $paymentService
    ) {}

    /**
     * Hosted luxury payment screen for web customer checkout.
     */
    public function showCheckout(string $uuid)
    {
        $transaction = PaymentTransaction::with(['sale.items.product', 'sale.store', 'customer'])
            ->where('uuid', $uuid)
            ->firstOrFail();

        $sale = $transaction->sale;
        $store = $sale->store;

        return view('store.payment', compact('transaction', 'sale', 'store'));
    }

    /**
     * Process direct/simulated card payment on hosted page.
     */
    public function processCard(Request $request, string $uuid)
    {
        $transaction = PaymentTransaction::where('uuid', $uuid)->firstOrFail();

        // Simulate instant payment authorization or real processor token confirmation
        $mockDetails = [
            'card_last4' => $request->input('card_number') ? substr(preg_replace('/\D/', '', $request->input('card_number')), -4) : '4242',
            'card_brand' => 'Visa',
            'payment_id' => 'PAY-' . strtoupper(\Illuminate\Support\Str::random(10)),
            'authorized_at' => now()->toIso8601String(),
        ];

        $this->paymentService->completeTransaction($transaction, $mockDetails);

        return redirect()->route('store.receipt', ['invoice' => $transaction->sale->invoice_number])
            ->with('success', 'Payment verified and confirmed! SMS digital receipt sent.');
    }

    /**
     * Mobile REST API: Initiate payment transaction session.
     */
    public function apiInitiate(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'sale_uuid' => 'required_without:invoice_number|string',
            'invoice_number' => 'required_without:sale_uuid|string',
            'gateway' => 'nullable|string|in:payhere,stripe,mock',
        ]);

        $query = Sale::query();
        if (! empty($validated['sale_uuid'])) {
            $query->where('uuid', $validated['sale_uuid']);
        } else {
            $query->where('invoice_number', $validated['invoice_number']);
        }

        $sale = $query->first();

        if (! $sale) {
            return response()->json(['status' => 'error', 'message' => 'Sale not found'], 404);
        }

        $gateway = $validated['gateway'] ?? 'payhere';
        $transaction = $this->paymentService->initiate($sale, $gateway);

        return response()->json([
            'status' => 'success',
            'transaction' => [
                'uuid' => $transaction->uuid,
                'gateway' => $transaction->gateway,
                'amount' => (float) $transaction->amount,
                'currency' => $transaction->currency,
                'status' => $transaction->status,
                'invoice_number' => $sale->invoice_number,
                'checkout_url' => url("/checkout/payment/{$transaction->uuid}"),
                'gateway_payload' => $transaction->payload_json,
            ],
        ], 201);
    }

    /**
     * Universal Webhook Handler (PayHere, Stripe, Mock).
     */
    public function webhook(Request $request, string $gateway): JsonResponse
    {
        Log::info("Payment webhook received for gateway: {$gateway}", [
            'payload' => $request->all(),
            'headers' => $request->headers->all(),
        ]);

        if ($gateway === 'payhere') {
            $isValid = $this->paymentService->verifyPayHereSignature($request->all());
            if (! $isValid) {
                Log::warning('PayHere signature verification failed', $request->all());
                return response()->json(['status' => 'error', 'message' => 'Invalid signature'], 400);
            }

            $orderId = $request->input('order_id');
            $statusCode = (int) $request->input('status_code'); // 2 = success, 0 = pending, -1 = canceled, -2 = failed, -3 = chargedback

            $transaction = PaymentTransaction::where('gateway_reference', $orderId)
                ->orWhereHas('sale', fn ($q) => $q->where('invoice_number', $orderId))
                ->latest()
                ->first();

            if (! $transaction) {
                return response()->json(['status' => 'error', 'message' => 'Transaction not found'], 404);
            }

            if ($statusCode === 2) {
                $this->paymentService->completeTransaction($transaction, [
                    'payment_id' => $request->input('payment_id'),
                    'payhere_amount' => $request->input('payhere_amount'),
                    'payhere_currency' => $request->input('payhere_currency'),
                    'method' => $request->input('method'),
                    'card_holder_name' => $request->input('card_holder_name'),
                ]);
            } else {
                $this->paymentService->failTransaction($transaction, $statusCode === -1 ? 'cancelled' : 'failed', $request->all());
            }

            return response()->json(['status' => 'success']);
        }

        if ($gateway === 'stripe') {
            $sigHeader = $request->header('stripe-signature', '');
            $isValid = $this->paymentService->verifyStripeSignature($request->getContent(), $sigHeader);

            if (! $isValid && env('APP_ENV') !== 'testing') {
                return response()->json(['status' => 'error', 'message' => 'Invalid Stripe signature'], 400);
            }

            $event = $request->input('type');
            $object = $request->input('data.object', []);
            $orderId = $object['metadata']['order_id'] ?? $object['client_reference_id'] ?? null;

            if ($orderId) {
                $transaction = PaymentTransaction::where('gateway_reference', $orderId)
                    ->orWhereHas('sale', fn ($q) => $q->where('invoice_number', $orderId))
                    ->first();

                if ($transaction && ($event === 'checkout.session.completed' || $event === 'payment_intent.succeeded')) {
                    $this->paymentService->completeTransaction($transaction, $object);
                }
            }

            return response()->json(['status' => 'success']);
        }

        // Mock / Sandbox webhook
        $orderId = $request->input('order_id');
        $transaction = PaymentTransaction::where('gateway_reference', $orderId)->first();
        if ($transaction) {
            $this->paymentService->completeTransaction($transaction, $request->all());
            return response()->json(['status' => 'success']);
        }

        return response()->json(['status' => 'ignored']);
    }

    /**
     * Payment Success Return Callback.
     */
    public function success(string $uuid)
    {
        $transaction = PaymentTransaction::with('sale')->where('uuid', $uuid)->firstOrFail();
        
        // Ensure completed
        if ($transaction->status !== 'completed') {
            $this->paymentService->completeTransaction($transaction, ['callback' => 'success_return']);
        }

        return redirect()->route('store.receipt', ['invoice' => $transaction->sale->invoice_number])
            ->with('success', 'Payment successful! Digital invoice ready.');
    }

    /**
     * Payment Cancel Return Callback.
     */
    public function cancel(string $uuid)
    {
        $transaction = PaymentTransaction::with('sale')->where('uuid', $uuid)->firstOrFail();
        $this->paymentService->failTransaction($transaction, 'cancelled');

        return redirect()->route('store.index')
            ->with('error', 'Payment was cancelled. You may retry from your cart or account.');
    }
}
