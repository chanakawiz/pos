<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

/**
 * Firebase Cloud Messaging — HTTP v1 API.
 *
 * Auth: Google service-account JSON (never committed; path via
 * FIREBASE_CREDENTIALS). A short-lived OAuth2 access token is minted with a
 * self-signed RS256 JWT and cached for ~55 minutes.
 *
 * When credentials are not configured (local dev / CI) pushes are logged and
 * reported as "mock" so the rest of the pipeline still runs end to end.
 */
class FcmNotificationService
{
    public const RESULT_SENT = 'sent';
    public const RESULT_MOCK = 'mock';
    public const RESULT_INVALID_TOKEN = 'invalid_token';
    public const RESULT_FAILED = 'failed';

    private const TOKEN_URI = 'https://oauth2.googleapis.com/token';
    private const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

    public function isConfigured(): bool
    {
        return $this->credentials() !== null;
    }

    /**
     * Send one notification to one device token.
     *
     * @param  array<string, scalar|null>  $data  FCM requires string values; they are cast here.
     * @return string One of the RESULT_* constants.
     */
    public function sendToToken(string $deviceToken, string $title, string $body, array $data = []): string
    {
        $credentials = $this->credentials();

        if ($credentials === null) {
            Log::info('[FCM mock] push not sent (FIREBASE_CREDENTIALS not configured)', [
                'title' => $title,
                'token' => substr($deviceToken, 0, 12).'…',
            ]);

            return self::RESULT_MOCK;
        }

        $message = [
            'message' => [
                'token' => $deviceToken,
                'notification' => ['title' => $title, 'body' => $body],
                'data' => array_map(fn ($v) => (string) $v, array_filter($data, fn ($v) => $v !== null)),
                'android' => ['priority' => 'high', 'notification' => ['channel_id' => 'omniluxe_default']],
                'apns' => ['payload' => ['aps' => ['sound' => 'default']]],
            ],
        ];

        try {
            $response = Http::withToken($this->accessToken($credentials))
                ->timeout(8)
                ->post("https://fcm.googleapis.com/v1/projects/{$credentials['project_id']}/messages:send", $message);
        } catch (\Throwable $e) {
            Log::error('[FCM] transport error: '.$e->getMessage());

            return self::RESULT_FAILED;
        }

        if ($response->successful()) {
            return self::RESULT_SENT;
        }

        $errorCode = data_get($response->json(), 'error.details.0.errorCode')
            ?? data_get($response->json(), 'error.status');

        // Token was uninstalled / rotated — caller should delete it.
        if ($response->status() === 404 || in_array($errorCode, ['UNREGISTERED', 'INVALID_ARGUMENT'], true)) {
            return self::RESULT_INVALID_TOKEN;
        }

        Log::warning('[FCM] send failed', ['status' => $response->status(), 'error' => $errorCode]);

        return self::RESULT_FAILED;
    }

    /**
     * @return array{project_id: string, client_email: string, private_key: string}|null
     */
    private function credentials(): ?array
    {
        $path = config('services.firebase.credentials');

        if (! $path || ! is_readable($path)) {
            return null;
        }

        $json = json_decode((string) file_get_contents($path), true);

        if (! isset($json['project_id'], $json['client_email'], $json['private_key'])) {
            return null;
        }

        return $json;
    }

    private function accessToken(array $credentials): string
    {
        return Cache::remember('fcm:access_token:'.$credentials['client_email'], now()->addMinutes(55), function () use ($credentials) {
            $now = time();
            $segments = [
                $this->base64Url(json_encode(['alg' => 'RS256', 'typ' => 'JWT'])),
                $this->base64Url(json_encode([
                    'iss' => $credentials['client_email'],
                    'scope' => self::SCOPE,
                    'aud' => self::TOKEN_URI,
                    'iat' => $now,
                    'exp' => $now + 3600,
                ])),
            ];

            $signature = '';
            if (! openssl_sign(implode('.', $segments), $signature, $credentials['private_key'], OPENSSL_ALGO_SHA256)) {
                throw new RuntimeException('Unable to sign FCM service-account JWT.');
            }
            $segments[] = $this->base64Url($signature);

            $response = Http::asForm()->timeout(8)->post(self::TOKEN_URI, [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => implode('.', $segments),
            ]);

            if (! $response->successful() || ! $response->json('access_token')) {
                throw new RuntimeException('FCM OAuth token exchange failed: HTTP '.$response->status());
            }

            return $response->json('access_token');
        });
    }

    private function base64Url(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }
}
