<?php

namespace App\Services\Sms;

class SmsResult
{
    public function __construct(
        public readonly bool $success,
        public readonly ?string $reference = null,
        public readonly ?string $error = null,
        public readonly float $cost = 0.0,
        public readonly array $rawResponse = []
    ) {}

    public static function success(?string $reference = null, float $cost = 0.0, array $rawResponse = []): self
    {
        return new self(
            success: true,
            reference: $reference,
            error: null,
            cost: $cost,
            rawResponse: $rawResponse
        );
    }

    public static function failure(string $error, array $rawResponse = []): self
    {
        return new self(
            success: false,
            reference: null,
            error: $error,
            cost: 0.0,
            rawResponse: $rawResponse
        );
    }
}
