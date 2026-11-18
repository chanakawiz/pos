<?php

namespace App\Contracts;

use App\Services\Sms\SmsResult;

interface SmsDriverInterface
{
    /**
     * Send an SMS message to a single recipient.
     *
     * @param string $to Recipient phone number (normalized)
     * @param string $message Text content
     * @param array $options Additional options (sender_id, etc.)
     * @return SmsResult
     */
    public function send(string $to, string $message, array $options = []): SmsResult;
}
