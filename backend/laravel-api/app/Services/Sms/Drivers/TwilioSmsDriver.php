<?php

namespace App\Services\Sms\Drivers;

use App\Contracts\SmsDriverInterface;
use App\Services\Sms\SmsResult;
use Illuminate\Support\Facades\Http;

class TwilioSmsDriver implements SmsDriverInterface
{
    public function __construct(protected array $config = []) {}

    public function send(string $to, string $message, array $options = []): SmsResult
    {
        $sid = $this->config['sid'] ?? '';
        $token = $this->config['token'] ?? '';
        $from = $options['from'] ?? ($this->config['from'] ?? '');

        // Twilio requires E.164 phone with +
        $formattedTo = str_starts_with($to, '+') ? $to : '+' . $to;

        if (empty($sid) || empty($token) || empty($from)) {
            return SmsResult::failure('Twilio credentials not configured (sid, token, from required)');
        }

        $url = "https://api.twilio.com/2010-04-01/Accounts/{$sid}/Messages.json";

        try {
            $response = Http::withBasicAuth($sid, $token)
                ->asForm()
                ->timeout(10)
                ->post($url, [
                    'To' => $formattedTo,
                    'From' => $from,
                    'Body' => $message,
                ]);

            $json = $response->json() ?? [];

            if ($response->successful() && !empty($json['sid'])) {
                $cost = isset($json['price']) ? abs((float) $json['price']) : 0.0500;
                return SmsResult::success($json['sid'], $cost, $json);
            }

            $errorMessage = $json['message'] ?? 'Twilio API rejected message with status: ' . $response->status();
            return SmsResult::failure($errorMessage, $json);
        } catch (\Throwable $e) {
            return SmsResult::failure('Twilio network exception: ' . $e->getMessage());
        }
    }
}
