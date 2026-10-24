<?php

namespace App\Jobs;

use App\Models\CustomerNotification;
use App\Services\FcmNotificationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

/**
 * Delivers a persisted customer notification to every registered device via
 * FCM. Runs on the queue (never inside checkout) and after DB commit.
 * Dead tokens reported by FCM are pruned automatically.
 */
class SendCustomerPushNotification implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;

    public array $backoff = [10, 60, 300];

    public function __construct(public CustomerNotification $notification)
    {
        $this->onQueue('notifications');
        $this->afterCommit();
    }

    public function handle(FcmNotificationService $fcm): void
    {
        $notification = $this->notification->loadMissing('customer.deviceTokens');

        $data = [
            'notification_uuid' => $notification->uuid,
            'type' => $notification->type,
        ] + collect($notification->data ?? [])
            ->filter(fn ($v) => is_scalar($v))
            ->all();

        foreach ($notification->customer->deviceTokens as $device) {
            $result = $fcm->sendToToken($device->token, $notification->title, $notification->body, $data);

            if ($result === FcmNotificationService::RESULT_INVALID_TOKEN) {
                $device->delete();
            }
        }
    }
}
