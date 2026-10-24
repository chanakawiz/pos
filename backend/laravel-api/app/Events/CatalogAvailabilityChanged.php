<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Contracts\Events\ShouldDispatchAfterCommit;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * PUBLIC shopper feed. Deliberately coarse: availability bands only
 * (in_stock | low_stock | out_of_stock). Exact quantities, stores, costs and
 * sales velocity never leave the internal channel.
 *   channel: catalog
 *   event:   availability.changed
 */
class CatalogAvailabilityChanged implements ShouldBroadcast, ShouldDispatchAfterCommit
{
    use Dispatchable, InteractsWithSockets;

    public string $queue = 'broadcasts';

    /**
     * @param  array<int, array{product_uuid: string, availability: string}>  $items
     */
    public function __construct(public array $items) {}

    public function broadcastOn(): array
    {
        return [new Channel('catalog')];
    }

    public function broadcastAs(): string
    {
        return 'availability.changed';
    }

    public function broadcastWith(): array
    {
        return ['items' => $this->items];
    }
}
