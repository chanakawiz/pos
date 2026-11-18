<?php

namespace App\Services\Sms\Drivers;

use App\Contracts\SmsDriverInterface;
use App\Services\Sms\SmsResult;
use Illuminate\Support\Facades\Http;

class NotifyLkSmsDriver implements SmsDriverInterface
{
    public function __construct(protected array $config = []) {}

    public function send(string $to, string $message, array $options = []): SmsResult
    {
        $apiUrl = $this->config['api_url'] ?? 'https://app.notify.lk/api/v1/send';
        $userId = $this->config['user_id'] ?? '';
        $apiKey = $this->config['api_key'] ?? '';
        $senderId = $options['sender_id'] ?? ($this->config['sender_id'] ?? 'NotifyDEMO');

        // Notify.lk expects phone number without leading + (e.g. 94771234567)
        $cleanPhone = ltrim($to, '+');

        try {
            $response = Http::timeout(10)->post($apiUrl, [
                'user_id' => $userId,
                'api_key' => $apiKey,
                'sender_id' => $senderId,
                'to' => $cleanPhone,
                'message' => $message,
            ]);

            $json = $response->json() ?? [];

            if ($response->successful() && (($json['status'] ?? '') === 'success')) {
                $ref = (string) ($json['data']['reference'] ?? ($json['reference'] ?? ('NOTIFY-' . time())));
                return SmsResult::success($ref, 0.40, $json); // 0.40 LKR avg cost
            }

            $errorMessage = $json['message'] ?? ($json['error'] ?? 'Notify.lk API dispatch failed with status: ' . $response->status());
            return SmsResult::failure($errorMessage, $json);
        } catch (\Throwable $e) {
            return SmsResult::failure('Notify.lk network exception: ' . $e->getMessage());
        }
    }
}
