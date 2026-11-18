<?php

namespace App\Services\Sms\Drivers;

use App\Contracts\SmsDriverInterface;
use App\Services\Sms\SmsResult;
use Illuminate\Support\Facades\Http;

class DialogEsmsDriver implements SmsDriverInterface
{
    public function __construct(protected array $config = []) {}

    public function send(string $to, string $message, array $options = []): SmsResult
    {
        $endpoint = $this->config['endpoint'] ?? 'https://e-sms.dialog.lk/api/v1/message/via/json';
        $username = $this->config['username'] ?? '';
        $password = $this->config['password'] ?? '';
        $sourceAddress = $options['sender_id'] ?? ($this->config['source_address'] ?? 'OMNILUXE');

        // Dialog eSMS format: 0771234567 or 94771234567
        $cleanPhone = ltrim($to, '+');

        try {
            $response = Http::timeout(10)->post($endpoint, [
                'user_name' => $username,
                'password' => $password,
                'source_address' => $sourceAddress,
                'message' => $message,
                'destinations' => [$cleanPhone],
            ]);

            $json = $response->json() ?? [];

            if ($response->successful() && (($json['status'] ?? '') === 'SUCCESS' || ($json['code'] ?? '') === '0')) {
                $ref = (string) ($json['transaction_id'] ?? ('DIALOG-' . time()));
                return SmsResult::success($ref, 0.35, $json);
            }

            $errorMessage = $json['description'] ?? ($json['error'] ?? 'Dialog eSMS rejected dispatch with code: ' . ($json['code'] ?? $response->status()));
            return SmsResult::failure($errorMessage, $json);
        } catch (\Throwable $e) {
            return SmsResult::failure('Dialog eSMS network exception: ' . $e->getMessage());
        }
    }
}
