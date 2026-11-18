<?php

namespace App\Services\Sms;

use App\Contracts\SmsDriverInterface;
use App\Models\Customer;
use App\Models\Sale;
use App\Models\SmsLog;
use App\Services\Sms\Drivers\DialogEsmsDriver;
use App\Services\Sms\Drivers\LogSmsDriver;
use App\Services\Sms\Drivers\MockSmsDriver;
use App\Services\Sms\Drivers\NotifyLkSmsDriver;
use App\Services\Sms\Drivers\TwilioSmsDriver;
use Illuminate\Support\Facades\Log;
use InvalidArgumentException;

class SmsService
{
    /**
     * Cache of resolved driver instances.
     *
     * @var array<string, SmsDriverInterface>
     */
    protected array $drivers = [];

    /**
     * Get an SMS driver instance.
     */
    public function driver(?string $name = null): SmsDriverInterface
    {
        $name = $name ?: config('sms.default', 'log');

        if (!isset($this->drivers[$name])) {
            $this->drivers[$name] = $this->resolveDriver($name);
        }

        return $this->drivers[$name];
    }

    /**
     * Resolve a driver instance by name.
     */
    protected function resolveDriver(string $name): SmsDriverInterface
    {
        $config = config("sms.drivers.{$name}", []);

        return match ($name) {
            'log' => new LogSmsDriver($config),
            'mock' => new MockSmsDriver($config),
            'notify_lk' => new NotifyLkSmsDriver($config),
            'twilio' => new TwilioSmsDriver($config),
            'dialog_esms' => new DialogEsmsDriver($config),
            default => throw new InvalidArgumentException("Unsupported SMS driver [{$name}]."),
        };
    }

    /**
     * Normalize a phone number to standard E.164 format.
     */
    public function normalizePhone(string $phone, string $country = 'LK'): string
    {
        // Strip out non-digit characters except leading plus
        $clean = preg_replace('/[^\d+]/', '', trim($phone));

        if (empty($clean)) {
            return '';
        }

        if ($country === 'LK') {
            // Local format with leading zero: 0771234567 -> +94771234567
            if (preg_match('/^0([7][0-9]{8})$/', $clean, $matches)) {
                return '+94' . $matches[1];
            }

            // Missing leading zero: 771234567 -> +94771234567
            if (preg_match('/^([7][0-9]{8})$/', $clean, $matches)) {
                return '+94' . $matches[1];
            }

            // Local without plus: 94771234567 -> +94771234567
            if (preg_match('/^94([7][0-9]{8})$/', $clean, $matches)) {
                return '+94' . $matches[1];
            }
        }

        // Ensure leading plus
        if (!str_starts_with($clean, '+')) {
            $clean = '+' . $clean;
        }

        return $clean;
    }

    /**
     * Mask a phone number to protect customer privacy on displays and receipts.
     * Example: "+94771234567" -> "+94 77 •••• 567"
     */
    public function maskPhone(string $phone): string
    {
        $clean = preg_replace('/[^\d]/', '', $phone);
        $len = strlen($clean);

        if ($len < 7) {
            return $phone;
        }

        // Sri Lanka local/international format
        if (str_starts_with($clean, '94') && $len === 11) {
            $prefix = substr($clean, 0, 4); // 9477
            $suffix = substr($clean, -3);    // 567
            return "+{$prefix} •••• {$suffix}";
        }

        if (str_starts_with($clean, '0') && $len === 10) {
            $prefix = substr($clean, 0, 3); // 077
            $suffix = substr($clean, -3);    // 567
            return "{$prefix} •••• {$suffix}";
        }

        // Generic fallback masking
        $start = substr($phone, 0, 4);
        $end = substr($phone, -3);
        return "{$start} •••• {$end}";
    }

    /**
     * Dispatch an SMS message and create an audit log.
     */
    public function dispatch(
        string $to,
        string $message,
        string $eventType = 'custom',
        array $options = []
    ): SmsLog {
        $driverName = $options['driver'] ?? config('sms.default', 'log');
        $normalizedPhone = $this->normalizePhone($to, config('sms.default_country', 'LK'));
        $maskedPhone = $this->maskPhone($normalizedPhone ?: $to);

        $smsLog = SmsLog::create([
            'store_id' => $options['store_id'] ?? null,
            'customer_id' => $options['customer_id'] ?? null,
            'sale_id' => $options['sale_id'] ?? null,
            'recipient_phone' => $normalizedPhone ?: $to,
            'masked_phone' => $maskedPhone,
            'message' => $message,
            'driver' => $driverName,
            'status' => 'queued',
            'event_type' => $eventType,
            'metadata' => $options['metadata'] ?? null,
        ]);

        if (empty($normalizedPhone)) {
            $smsLog->update([
                'status' => 'failed',
                'error_message' => 'Invalid or empty recipient phone number',
            ]);
            return $smsLog;
        }

        try {
            $driver = $this->driver($driverName);
            $result = $driver->send($normalizedPhone, $message, $options);

            if ($result->success) {
                $smsLog->update([
                    'status' => 'sent',
                    'gateway_reference' => $result->reference,
                    'cost' => $result->cost,
                    'sent_at' => now(),
                    'error_message' => null,
                ]);
            } else {
                $smsLog->update([
                    'status' => 'failed',
                    'error_message' => $result->error,
                ]);
            }
        } catch (\Throwable $e) {
            Log::error('SMS Dispatch exception', ['error' => $e->getMessage(), 'to' => $normalizedPhone]);
            $smsLog->update([
                'status' => 'failed',
                'error_message' => $e->getMessage(),
            ]);
        }

        return $smsLog;
    }

    /**
     * Send digital e-receipt SMS for a completed POS or Web store sale.
     */
    public function sendSaleReceipt(Sale $sale, ?string $overridePhone = null): ?SmsLog
    {
        $eventType = ($sale->channel === 'online' || $sale->channel === 'web') ? 'web_order' : 'pos_receipt';

        // Check auto dispatch toggle
        $autoDispatch = config("sms.auto_dispatch.{$eventType}", true);
        if (!$autoDispatch && empty($overridePhone)) {
            return null;
        }

        $phone = $overridePhone
            ?: ($sale->customer?->phone
            ?: ($sale->delivery_phone
            ?: ($sale->recipient_phone ?? null)));

        if (empty($phone)) {
            return null;
        }

        $storeName = $sale->store?->name ?: config('app.name', 'OmniLuxe Store');
        $storePhone = $sale->store?->phone ?: '+94 11 234 5678';
        $receiptUrl = url("/receipt/{$sale->invoice_number}");
        $totalFormatted = ($sale->store?->currency_symbol ?: 'Rs.') . ' ' . number_format($sale->total_amount, 2);

        $message = "{$storeName}: Thank you for your purchase! Digital e-receipt & warranty for invoice {$sale->invoice_number}: {$receiptUrl} (Total: {$totalFormatted}). Helpline: {$storePhone}";

        return $this->dispatch($phone, $message, $eventType, [
            'store_id' => $sale->store_id,
            'customer_id' => $sale->customer_id,
            'sale_id' => $sale->id,
            'sender_id' => $sale->store?->code ?: config('sms.default_sender_id', 'OMNILUXE'),
            'metadata' => [
                'invoice_number' => $sale->invoice_number,
                'total_amount' => (float) $sale->total_amount,
                'channel' => $sale->channel,
            ],
        ]);
    }

    /**
     * Send courier dispatch notification SMS with live tracking link.
     */
    public function sendOrderDispatched(Sale $sale, string $courier, string $trackingNumber): ?SmsLog
    {
        if (!config('sms.auto_dispatch.order_dispatched', true)) {
            return null;
        }

        $phone = $sale->delivery_phone
            ?: ($sale->customer?->phone
            ?: ($sale->recipient_phone ?? null));

        if (empty($phone)) {
            return null;
        }

        $storeName = $sale->store?->name ?: 'OmniLuxe Store';
        $trackUrl = url("/track/{$sale->invoice_number}");

        $message = "{$storeName}: Your order {$sale->invoice_number} has been dispatched via {$courier}! Track live: {$trackUrl} (Tracking No: {$trackingNumber}).";

        return $this->dispatch($phone, $message, 'order_dispatched', [
            'store_id' => $sale->store_id,
            'customer_id' => $sale->customer_id,
            'sale_id' => $sale->id,
            'metadata' => [
                'courier' => $courier,
                'tracking_number' => $trackingNumber,
            ],
        ]);
    }

    /**
     * Send delivery confirmation SMS.
     */
    public function sendOrderDelivered(Sale $sale): ?SmsLog
    {
        $phone = $sale->delivery_phone ?: ($sale->customer?->phone ?? null);
        if (empty($phone)) {
            return null;
        }

        $storeName = $sale->store?->name ?: 'OmniLuxe Store';
        $receiptUrl = url("/receipt/{$sale->invoice_number}");

        $message = "{$storeName}: Your order {$sale->invoice_number} has been delivered successfully! View digital warranty: {$receiptUrl}. Thank you for choosing us!";

        return $this->dispatch($phone, $message, 'order_delivered', [
            'store_id' => $sale->store_id,
            'customer_id' => $sale->customer_id,
            'sale_id' => $sale->id,
        ]);
    }

    /**
     * Send VIP membership tier upgrade notification SMS.
     */
    public function sendVipTierUpgrade(Customer $customer, string $oldTier, string $newTier): ?SmsLog
    {
        if (!config('sms.auto_dispatch.vip_upgrade', true) || empty($customer->phone)) {
            return null;
        }

        $storeName = config('app.name', 'OmniLuxe Store');
        $tierTitles = [
            'silver' => 'Silver Privilege',
            'gold' => 'Gold Elite',
            'black' => 'Black Diamond',
        ];

        $title = $tierTitles[$newTier] ?? ucfirst($newTier);
        $discount = $newTier === 'black' ? '10%' : ($newTier === 'gold' ? '5%' : '0%');

        $message = "{$storeName}: Congratulations {$customer->name}! You have been elevated to {$title} VIP status. Enjoy an automatic {$discount} privilege discount on all future purchases.";

        return $this->dispatch($customer->phone, $message, 'vip_upgrade', [
            'customer_id' => $customer->id,
            'metadata' => [
                'old_tier' => $oldTier,
                'new_tier' => $newTier,
            ],
        ]);
    }
}
