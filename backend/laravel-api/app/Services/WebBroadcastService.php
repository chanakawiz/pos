<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class WebBroadcastService
{
    protected ?string $appId;
    protected ?string $key;
    protected ?string $secret;
    protected ?string $cluster;

    public function __construct()
    {
        $this->appId = config('broadcasting.connections.pusher.app_id', env('PUSHER_APP_ID'));
        $this->key = config('broadcasting.connections.pusher.key', env('PUSHER_APP_KEY'));
        $this->secret = config('broadcasting.connections.pusher.secret', env('PUSHER_APP_SECRET'));
        $this->cluster = config('broadcasting.connections.pusher.options.cluster', env('PUSHER_APP_CLUSTER', 'ap2'));
    }

    /**
     * Broadcast real-time event to Web store clients via Pusher
     */
    public function broadcast(string $channel, string $event, array $data): array
    {
        if (empty($this->key) || empty($this->secret) || empty($this->appId)) {
            Log::info("[Web Realtime Mock / Pusher] Event '{$event}' on channel '{$channel}' broadcasted", $data);
            return [
                'success' => true,
                'mode' => 'mock_logged',
                'channel' => $channel,
                'event' => $event,
            ];
        }

        try {
            $body = json_encode([
                'name' => $event,
                'channel' => $channel,
                'data' => json_encode($data),
            ]);

            $path = "/apps/{$this->appId}/events";
            $authTimestamp = time();
            $authVersion = '1.0';
            $bodyMd5 = md5($body);

            $signatureString = "POST\n{$path}\nauth_key={$this->key}&auth_timestamp={$authTimestamp}&auth_version={$authVersion}&body_md5={$bodyMd5}";
            $authSignature = hash_hmac('sha256', $signatureString, $this->secret);

            $url = "https://api-{$this->cluster}.pusher.com{$path}?auth_key={$this->key}&auth_timestamp={$authTimestamp}&auth_version={$authVersion}&body_md5={$bodyMd5}&auth_signature={$authSignature}";

            $response = Http::withBody($body, 'application/json')->timeout(3)->post($url);

            return [
                'success' => $response->successful(),
                'mode' => 'live_pusher',
                'response' => $response->json(),
            ];
        } catch (\Exception $e) {
            Log::error("[Web Realtime Pusher] Exception while broadcasting: " . $e->getMessage());
            return [
                'success' => false,
                'error' => $e->getMessage(),
            ];
        }
    }

    /**
     * Broadcast new order notification to web clients and live counters
     */
    public function broadcastOrderPlaced(array $orderData): array
    {
        return $this->broadcast('store-feed', 'order.placed', $orderData);
    }

    /**
     * Broadcast live stock decrement to web store catalog
     */
    public function broadcastStockUpdated(int $productId, float $newStock): array
    {
        return $this->broadcast('catalog-feed', 'stock.updated', [
            'product_id' => $productId,
            'new_stock' => $newStock,
            'timestamp' => now()->toIso8601String(),
        ]);
    }
}
