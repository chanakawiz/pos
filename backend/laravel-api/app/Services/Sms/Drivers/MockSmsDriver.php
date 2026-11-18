<?php

namespace App\Services\Sms\Drivers;

use App\Contracts\SmsDriverInterface;
use App\Services\Sms\SmsResult;
use Illuminate\Support\Str;

class MockSmsDriver implements SmsDriverInterface
{
    /**
     * In-memory array of all messages dispatched via this mock.
     *
     * @var array<int, array{to: string, message: string, options: array, reference: string, sent_at: string}>
     */
    protected static array $sent = [];

    protected static bool $shouldFail = false;
    protected static ?string $failureMessage = null;

    public function __construct(protected array $config = []) {}

    public function send(string $to, string $message, array $options = []): SmsResult
    {
        if (static::$shouldFail) {
            return SmsResult::failure(static::$failureMessage ?? 'Mock gateway rejected dispatch');
        }

        $reference = 'MOCK-' . Str::upper(Str::random(10));
        static::$sent[] = [
            'to' => $to,
            'message' => $message,
            'options' => $options,
            'reference' => $reference,
            'sent_at' => now()->toIso8601String(),
        ];

        return SmsResult::success($reference, 0.0050, ['mock' => true]);
    }

    public static function setShouldFail(bool $fail, ?string $message = null): void
    {
        static::$shouldFail = $fail;
        static::$failureMessage = $message;
    }

    public static function all(): array
    {
        return static::$sent;
    }

    public static function count(): int
    {
        return count(static::$sent);
    }

    public static function reset(): void
    {
        static::$sent = [];
        static::$shouldFail = false;
        static::$failureMessage = null;
    }

    public static function hasSentTo(string $to): bool
    {
        foreach (static::$sent as $entry) {
            if ($entry['to'] === $to) {
                return true;
            }
        }
        return false;
    }

    public static function last(): ?array
    {
        return empty(static::$sent) ? null : static::$sent[array_key_last(static::$sent)];
    }
}
