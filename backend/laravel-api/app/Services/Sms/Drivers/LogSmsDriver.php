<?php

namespace App\Services\Sms\Drivers;

use App\Contracts\SmsDriverInterface;
use App\Services\Sms\SmsResult;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class LogSmsDriver implements SmsDriverInterface
{
    public function __construct(protected array $config = []) {}

    public function send(string $to, string $message, array $options = []): SmsResult
    {
        $reference = 'LOG-' . Str::upper(Str::random(12));
        $channel = $this->config['channel'] ?? null;

        Log::channel($channel)->info("[SMS DISPATCH] To: {$to} | Ref: {$reference}", [
            'to' => $to,
            'message' => $message,
            'options' => $options,
            'reference' => $reference,
        ]);

        return SmsResult::success($reference, 0.0, ['channel' => $channel]);
    }
}
