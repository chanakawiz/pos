<?php

namespace App\Events;

use App\Models\CustomerNotification;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Contracts\Events\ShouldDispatchAfterCommit;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Delivered over Reverb to exactly one customer:
 *   channel: private-customer.{customerUuid}
 *   event:   notification.created
 *
 * Only fires after the surrounding DB transaction commits, so clients never
 * receive a notification for a rolled-back order.
 */
class CustomerNotificationCreated implements ShouldBroadcast, ShouldDispatchAfterCommit
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public string $queue = 'broadcasts';

    public function __construct(public CustomerNotification $notification) {}

    public function broadcastOn(): array
    {
        return [new PrivateChannel('customer.'.$this->notification->customer->uuid)];
    }

    public function broadcastAs(): string
    {
        return 'notification.created';
    }

    public function broadcastWith(): array
    {
        return $this->notification->toClientArray();
    }
}
