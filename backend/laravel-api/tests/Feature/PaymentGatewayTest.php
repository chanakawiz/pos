<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\PaymentTransaction;
use App\Models\Product;
use App\Models\Sale;
use App\Models\Store;
use App\Models\User;
use App\Services\PaymentGatewayService;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Str;
use Tests\TestCase;

class PaymentGatewayTest extends TestCase
{
    use DatabaseTransactions;

    protected Store $store;
    protected User $adminUser;
    protected Customer $customer;
    protected Product $product;
    protected Sale $sale;

    protected function setUp(): void
    {
        parent::setUp();

        $this->store = Store::firstOrCreate(
            ['code' => 'STORE-001'],
            [
                'name' => 'OmniLuxe Flagship',
                'currency_code' => 'LKR',
                'currency_symbol' => 'Rs.',
                'is_active' => true,
            ]
        );

        $this->adminUser = User::where('role', 'super_admin')->first()
            ?? User::factory()->create(['role' => 'super_admin']);

        $this->customer = Customer::firstOrCreate(
            ['phone' => '0771234567'],
            [
                'uuid' => (string) Str::uuid(),
                'name' => 'Kasun Fernando',
                'email' => 'kasun@luxury.test',
                'address' => '420 Galle Road, Colombo',
            ]
        );

        $this->product = Product::first() ?? Product::create([
            'sku' => 'NIKE-PEG-40',
            'name' => 'Nike Air Zoom Pegasus 40',
            'selling_price' => 28500.00,
            'cost_price' => 18000.00,
            'tax_rate' => 0.00,
            'unit' => 'piece',
            'is_active' => true,
        ]);

        $this->sale = Sale::create([
            'uuid' => (string) Str::uuid(),
            'invoice_number' => 'INV-TEST-20261024-001',
            'transaction_uuid' => (string) Str::uuid(),
            'store_id' => $this->store->id,
            'cashier_id' => $this->adminUser->id,
            'customer_id' => $this->customer->id,
            'subtotal' => 28500.00,
            'discount_amount' => 0.00,
            'tax_amount' => 0.00,
            'total_amount' => 28500.00,
            'paid_amount' => 0.00,
            'change_amount' => 0.00,
            'payment_status' => 'unpaid',
            'sale_status' => 'completed',
            'source' => 'online',
            'sold_at' => now(),
        ]);
    }

    public function test_can_initiate_payment_session_via_api(): void
    {
        $response = $this->postJson('/api/v1/payments/initiate', [
            'invoice_number' => $this->sale->invoice_number,
            'gateway' => 'payhere',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'status' => 'success',
                'transaction' => [
                    'gateway' => 'payhere',
                    'amount' => 28500.00,
                    'currency' => 'LKR',
                    'status' => 'pending',
                    'invoice_number' => $this->sale->invoice_number,
                ],
            ]);

        $this->assertDatabaseHas('payment_transactions', [
            'sale_id' => $this->sale->id,
            'gateway' => 'payhere',
            'status' => 'pending',
            'amount' => 28500.00,
        ]);
    }

    public function test_can_render_hosted_checkout_payment_screen(): void
    {
        $service = app(PaymentGatewayService::class);
        $transaction = $service->initiate($this->sale, 'payhere');

        $response = $this->get("/checkout/payment/{$transaction->uuid}");

        $response->assertStatus(200);
        $response->assertSee('Complete Payment');
        $response->assertSee($this->sale->invoice_number);
        $response->assertSee('28,500.00');
    }

    public function test_can_process_card_payment_and_mark_sale_paid(): void
    {
        $service = app(PaymentGatewayService::class);
        $transaction = $service->initiate($this->sale, 'payhere');

        $response = $this->post("/checkout/payment/{$transaction->uuid}/process", [
            'card_number' => '4242 4242 4242 4242',
            'card_expiry' => '12/28',
            'card_cvc' => '888',
            'card_holder' => 'Kasun Fernando',
        ]);

        $response->assertRedirect(route('store.receipt', ['invoice' => $this->sale->invoice_number]));

        $this->sale->refresh();
        $this->assertEquals('paid', $this->sale->payment_status);
        $this->assertEquals(28500.00, (float) $this->sale->paid_amount);

        $transaction->refresh();
        $this->assertEquals('completed', $transaction->status);
        $this->assertNotNull($transaction->paid_at);

        $this->assertDatabaseHas('payments', [
            'sale_id' => $this->sale->id,
            'payment_method' => 'card',
            'amount' => 28500.00,
        ]);
    }

    public function test_can_process_payhere_webhook_with_valid_signature(): void
    {
        $service = app(PaymentGatewayService::class);
        $transaction = $service->initiate($this->sale, 'payhere');

        $merchantId = config('services.payhere.merchant_id', '1210001');
        $merchantSecret = config('services.payhere.merchant_secret', 'omniluxe_secret_sandbox');
        $orderId = $this->sale->invoice_number;
        $amount = '28500.00';
        $currency = 'LKR';
        $statusCode = '2'; // 2 = success

        $md5sig = strtoupper(
            md5(
                $merchantId .
                $orderId .
                $amount .
                $currency .
                $statusCode .
                strtoupper(md5($merchantSecret))
            )
        );

        $webhookPayload = [
            'merchant_id' => $merchantId,
            'order_id' => $orderId,
            'payment_id' => '320025112233',
            'payhere_amount' => $amount,
            'payhere_currency' => $currency,
            'status_code' => $statusCode,
            'md5sig' => $md5sig,
            'method' => 'VISA',
            'card_holder_name' => 'Kasun Fernando',
        ];

        $response = $this->postJson('/api/v1/payments/webhook/payhere', $webhookPayload);

        $response->assertStatus(200)
            ->assertJson(['status' => 'success']);

        $this->sale->refresh();
        $this->assertEquals('paid', $this->sale->payment_status);

        $transaction->refresh();
        $this->assertEquals('completed', $transaction->status);
        $this->assertEquals('320025112233', $transaction->gateway_reference);
    }

    public function test_rejects_payhere_webhook_with_invalid_signature(): void
    {
        $service = app(PaymentGatewayService::class);
        $service->initiate($this->sale, 'payhere');

        $webhookPayload = [
            'merchant_id' => '1210001',
            'order_id' => $this->sale->invoice_number,
            'payment_id' => '320025112233',
            'payhere_amount' => '28500.00',
            'payhere_currency' => 'LKR',
            'status_code' => '2',
            'md5sig' => 'TAMPERED_INVALID_SIGNATURE',
        ];

        $response = $this->postJson('/api/v1/payments/webhook/payhere', $webhookPayload);

        $response->assertStatus(400)
            ->assertJson(['status' => 'error', 'message' => 'Invalid signature']);

        $this->sale->refresh();
        $this->assertEquals('unpaid', $this->sale->payment_status);
    }
}
