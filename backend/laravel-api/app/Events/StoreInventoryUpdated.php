<?php

namespace App\Events;

use App\Models\Store;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Contracts\Events\ShouldDispatchAfterCommit;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * INTERNAL operations feed (exact stock quantities).
 *   channel: private-store.{storeUuid}.operations
 *   event:   inventory.updated
 *
 * Authorized only for active staff of that store (or head office) — consumed
 * by the desktop POS counters and the ERP. Never exposed to shoppers.
 */
class StoreInventoryUpdated implements ShouldBroadcast, ShouldDispatchAfterCommit
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public string $queue = 'broadcasts';

    /**
     * @param  array<int, array{product_uuid: string, quantity_on_hand: float}>  $items
     */
    public function __construct(
        public Store $store,
        public array $items,
        public string $source,
    ) {}

    public function broadcastOn(): array
    {
        return [new PrivateChannel('store.'.$this->store->uuid.'.operations')];
    }

    public function broadcastAs(): string
    {
        return 'inventory.updated';
    }

    public function broadcastWith(): array
    {
        return [
            'source' => $this->source, // pos | web | mobile | erp
            'items' => $this->items,
            'at' => now()->toIso8601String(),
        ];
    }
}
