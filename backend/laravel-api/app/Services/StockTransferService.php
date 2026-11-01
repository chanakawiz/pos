<?php

namespace App\Services;

use App\Models\Inventory;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\StockTransfer;
use App\Models\StockTransferItem;
use App\Models\Store;
use App\Models\User;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class StockTransferService
{
    public function __construct(
        protected InventoryService $inventoryService
    ) {}

    /**
     * Create a new inter-store stock transfer request.
     */
    public function createTransfer(
        Store $sourceStore,
        Store $destinationStore,
        array $items,
        ?User $user = null,
        ?string $notes = null,
        string $status = 'pending_approval'
    ): StockTransfer {
        if ($sourceStore->id === $destinationStore->id) {
            throw new InvalidArgumentException('Source and destination stores must be different.');
        }

        if (empty($items)) {
            throw new InvalidArgumentException('Transfer manifest must contain at least one item.');
        }

        return DB::transaction(function () use ($sourceStore, $destinationStore, $items, $user, $notes, $status) {
            $transfer = StockTransfer::create([
                'source_store_id' => $sourceStore->id,
                'destination_store_id' => $destinationStore->id,
                'status' => in_array($status, ['draft', 'pending_approval']) ? $status : 'pending_approval',
                'notes' => $notes,
                'requested_by' => $user?->id,
            ]);

            foreach ($items as $itemData) {
                $qty = (float) ($itemData['quantity'] ?? $itemData['quantity_requested'] ?? 1);
                if ($qty <= 0) {
                    continue;
                }

                StockTransferItem::create([
                    'stock_transfer_id' => $transfer->id,
                    'product_id' => $itemData['product_id'],
                    'variant_id' => $itemData['variant_id'] ?? null,
                    'quantity_requested' => $qty,
                    'quantity_sent' => 0.000,
                    'quantity_received' => 0.000,
                ]);
            }

            return $transfer->load(['sourceStore', 'destinationStore', 'items.product', 'items.variant']);
        });
    }

    /**
     * Dispatch stock from source store to transit.
     */
    public function dispatchTransfer(
        StockTransfer $transfer,
        ?User $user = null,
        ?array $quantitiesSent = null
    ): StockTransfer {
        if (!in_array($transfer->status, ['draft', 'pending_approval'])) {
            throw new InvalidArgumentException("Transfer #{$transfer->transfer_number} is already {$transfer->status} and cannot be dispatched.");
        }

        return DB::transaction(function () use ($transfer, $user, $quantitiesSent) {
            $transfer->loadMissing(['items.product', 'items.variant', 'sourceStore']);

            foreach ($transfer->items as $item) {
                $sentQty = isset($quantitiesSent[$item->id])
                    ? (float) $quantitiesSent[$item->id]
                    : (float) $item->quantity_requested;

                if ($sentQty <= 0) {
                    continue;
                }

                // Deduct stock from source store
                $this->inventoryService->deductStock(
                    $transfer->sourceStore,
                    $item->product,
                    $item->variant,
                    $sentQty,
                    $transfer->uuid,
                    $user,
                    "Stock Transfer Out: {$transfer->transfer_number} to {$transfer->destinationStore?->name}"
                );

                $item->update(['quantity_sent' => $sentQty]);
            }

            $transfer->update([
                'status' => 'in_transit',
                'approved_by' => $user?->id,
                'dispatched_at' => now(),
            ]);

            return $transfer->fresh(['sourceStore', 'destinationStore', 'items.product', 'items.variant', 'approvedBy']);
        });
    }

    /**
     * Receive stock at destination store.
     */
    public function receiveTransfer(
        StockTransfer $transfer,
        ?User $user = null,
        ?array $quantitiesReceived = null
    ): StockTransfer {
        if ($transfer->status !== 'in_transit') {
            throw new InvalidArgumentException("Transfer #{$transfer->transfer_number} must be in_transit to be received.");
        }

        return DB::transaction(function () use ($transfer, $user, $quantitiesReceived) {
            $transfer->loadMissing(['items.product', 'items.variant', 'destinationStore']);

            foreach ($transfer->items as $item) {
                $recvQty = isset($quantitiesReceived[$item->id])
                    ? (float) $quantitiesReceived[$item->id]
                    : (float) $item->quantity_sent;

                if ($recvQty <= 0) {
                    continue;
                }

                // Add stock to destination store
                $this->inventoryService->addStock(
                    $transfer->destinationStore,
                    $item->product,
                    $item->variant,
                    $recvQty,
                    'transfer_in',
                    $transfer->uuid,
                    $user,
                    "Stock Transfer In: {$transfer->transfer_number} from {$transfer->sourceStore?->name}"
                );

                $item->update(['quantity_received' => $recvQty]);
            }

            $transfer->update([
                'status' => 'received',
                'received_by' => $user?->id,
                'received_at' => now(),
            ]);

            return $transfer->fresh(['sourceStore', 'destinationStore', 'items.product', 'items.variant', 'receivedBy']);
        });
    }

    /**
     * Cancel transfer and return stock if already in transit.
     */
    public function cancelTransfer(StockTransfer $transfer, ?User $user = null, ?string $reason = null): StockTransfer
    {
        if (in_array($transfer->status, ['received', 'cancelled'])) {
            throw new InvalidArgumentException("Transfer #{$transfer->transfer_number} cannot be cancelled.");
        }

        return DB::transaction(function () use ($transfer, $user, $reason) {
            // If already in transit, restore deducted stock to source store
            if ($transfer->status === 'in_transit') {
                $transfer->loadMissing(['items.product', 'items.variant', 'sourceStore']);
                foreach ($transfer->items as $item) {
                    if ((float) $item->quantity_sent > 0) {
                        $this->inventoryService->addStock(
                            $transfer->sourceStore,
                            $item->product,
                            $item->variant,
                            (float) $item->quantity_sent,
                            'transfer_in',
                            $transfer->uuid,
                            $user,
                            "Cancelled Transfer Restored: {$transfer->transfer_number}"
                        );
                    }
                }
            }

            $noteSuffix = $reason ? " | Cancelled: {$reason}" : ' | Cancelled';
            $transfer->update([
                'status' => 'cancelled',
                'notes' => ($transfer->notes ?? '') . $noteSuffix,
            ]);

            return $transfer->fresh(['sourceStore', 'destinationStore', 'items.product']);
        });
    }

    /**
     * Retrieve cross-branch inventory availability for a given product.
     */
    public function getCrossStoreStock(int $productId, ?int $variantId = null): Collection
    {
        $stores = Store::where('is_active', true)->get();

        $inventories = Inventory::where('product_id', $productId)
            ->when($variantId, fn ($q) => $q->where('variant_id', $variantId))
            ->get()
            ->keyBy('store_id');

        return $stores->map(function (Store $store) use ($inventories) {
            $inv = $inventories->get($store->id);

            return [
                'store_id' => $store->id,
                'store_code' => $store->code,
                'store_name' => $store->name,
                'address' => $store->address,
                'phone' => $store->phone,
                'quantity_on_hand' => (float) ($inv?->quantity_on_hand ?? 0.00),
                'quantity_reserved' => (float) ($inv?->quantity_reserved ?? 0.00),
                'quantity_available' => max(0.00, (float) (($inv?->quantity_on_hand ?? 0.00) - ($inv?->quantity_reserved ?? 0.00))),
            ];
        });
    }
}
