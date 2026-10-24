<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * PUBLIC marketing feed for all connected shoppers (guests included).
 *   channel: promotions
 *   event:   promotion.published
 */
class PromotionPublished implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets;

    public string $queue = 'broadcasts';

    public function __construct(
        public string $title,
        public string $body,
        public ?string $url = null,
    ) {}

    public function broadcastOn(): array
    {
        return [new Channel('promotions')];
    }

    public function broadcastAs(): string
    {
        return 'promotion.published';
    }

    public function broadcastWith(): array
    {
        return ['title' => $this->title, 'body' => $this->body, 'url' => $this->url];
    }
}
