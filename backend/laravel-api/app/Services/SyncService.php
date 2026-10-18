<?php

namespace App\Services;

use App\Models\Category;
use App\Models\Customer;
use App\Models\Device;
use App\Models\Product;
use App\Models\Sale;
use App\Models\Store;
use App\Models\SyncLog;
use App\Models\User;
use Carbon\Carbon;
use Exception;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class SyncService
{
    public function __construct(
        protected BillingService $billingService
    ) {}

    /**
     * Ingest batch of offline transactions from a terminal.
     */
    public function pushTransactions(Device $device, Store $store, array $transactions): array
    {
        $syncedUuids = [];
        $failedUuids = [];
        $errors = [];

        foreach ($transactions as $tx) {
            $txUuid = $tx['transaction_uuid'] ?? null;
            if (! $txUuid) {
                continue;
            }

            try {
                Validator::make($tx, [
                    'transaction_uuid' => 'required|uuid',
                    'items' => 'required|array|min:1',
                    'items.*.product_id' => 'required_without:items.*.product_uuid|integer',
                    'items.*.product_uuid' => 'required_without:items.*.product_id|uuid',
                    'items.*.quantity' => 'required|numeric|min:0.001|decimal:0,3',
                    'items.*.unit_price' => 'required|numeric|min:0',
                    'items.*.discount_amount' => 'nullable|numeric|min:0',
                    'items.*.tax_rate' => 'nullable|numeric|min:0|max:100',
                    'payments' => 'required|array|min:1',
                    'payments.*.payment_method' => 'required|in:cash,card,bank_transfer,credit',
                    'payments.*.amount' => 'required|numeric|min:0',
                    'discount_amount' => 'nullable|numeric|min:0',
                    'cashier_uuid' => 'nullable|uuid',
                    'sold_at' => 'nullable|date',
                    'invoice_number' => 'nullable|string|max:191',
                ])->validate();
                if ((! empty($tx['store_uuid']) && $tx['store_uuid'] !== $store->uuid) ||
                    (! empty($tx['device_uuid']) && $tx['device_uuid'] !== $device->uuid)) {
                    throw new Exception('Transaction belongs to another store or device.');
                }
                // Idempotency check
                $existing = Sale::where('transaction_uuid', $txUuid)->first();
                if ($existing) {
                    if ($existing->store_id !== $store->id) {
                        throw new Exception('Transaction belongs to another store.');
                    }
                    $syncedUuids[] = $txUuid;

                    continue;
                }

                // Determine cashier
                $cashier = null;
                if (! empty($tx['cashier_uuid'])) {
                    $cashier = User::where('uuid', $tx['cashier_uuid'])->where('store_id', $store->id)->firstOrFail();
                }
                if (! $cashier) {
                    $cashier = User::where('role', 'cashier')->where('store_id', $store->id)->first()
                        ?? User::where('store_id', $store->id)->firstOrFail();
                }

                $tx['source'] = 'offline';
                $tx['sync_status'] = 'synced';

                $this->billingService->processSale($tx, $store, $cashier, $device);
                $syncedUuids[] = $txUuid;
            } catch (Exception $e) {
                Log::error("Sync push failure for {$txUuid}: ".$e->getMessage(), ['trace' => $e->getTraceAsString()]);
                $failedUuids[] = [
                    'uuid' => $txUuid,
                    'error' => $e->getMessage(),
                ];
                $errors[] = "UUID {$txUuid}: ".$e->getMessage();
            }
        }

        $overallStatus = count($failedUuids) === 0 ? 'success' : (count($syncedUuids) > 0 ? 'partial_failure' : 'failed');

        SyncLog::create([
            'device_id' => $device->id,
            'sync_type' => 'push',
            'batch_size' => count($transactions),
            'status' => $overallStatus,
            'error_details' => count($errors) > 0 ? implode("\n", $errors) : null,
            'synced_at' => Carbon::now(),
        ]);

        $device->update(['last_sync_at' => Carbon::now()]);

        return [
            'synced_count' => count($syncedUuids),
            'synced_uuids' => $syncedUuids,
            'failed_uuids' => $failedUuids,
            'server_timestamp' => Carbon::now()->toIso8601String(),
        ];
    }

    /**
     * Pull catalog & customer changes since the client's cached version.
     */
    public function pullDelta(Store $store, int $sinceVersion = 0): array
    {
        // Read the committed high-water mark before querying. Later writes remain for the next pull.
        $currentVersion = (int) DB::table('sync_revisions')->where('id', 1)->value('version');

        $products = Product::withTrashed()->with(['category', 'brand', 'variants', 'inventories' => function ($q) use ($store) {
            $q->where('store_id', $store->id);
        }])
            ->where('version', '>', $sinceVersion)
            ->where('version', '<=', $currentVersion)
            ->get()
            ->map(function ($p) {
                $stock = $p->inventories->first()?->quantity_on_hand ?? 0.00;

                return [
                    'id' => $p->id,
                    'uuid' => $p->uuid,
                    'sku' => $p->sku,
                    'barcode' => $p->barcode,
                    'name' => $p->name,
                    'sinhala_name' => $p->sinhala_name,
                    'warranty_period' => $p->warranty_period,
                    'requires_serial' => (bool) $p->requires_serial,
                    'category' => $p->category ? [
                        'uuid' => $p->category->uuid,
                        'name' => $p->category->name,
                    ] : null,
                    'category_uuid' => $p->category?->uuid,
                    'brand' => $p->brand?->name,
                    'unit' => $p->unit,
                    'cost_price' => (float) $p->cost_price,
                    'selling_price' => (float) $p->selling_price,
                    'tax_rate' => (float) $p->tax_rate,
                    'min_stock_level' => (int) $p->min_stock_level,
                    'stock_quantity' => (float) $stock,
                    'has_variants' => (bool) $p->has_variants,
                    'is_active' => (bool) $p->is_active,
                    'version' => (int) $p->version,
                    'deleted_at' => $p->deleted_at?->toIso8601String(),
                ];
            });

        $categories = Category::withTrashed()->where('version', '>', $sinceVersion)
            ->where('version', '<=', $currentVersion)
            ->get(['id', 'uuid', 'name', 'slug', 'display_order', 'is_active', 'version', 'deleted_at']);

        $customers = Customer::withTrashed()->where('version', '>', $sinceVersion)
            ->where('version', '<=', $currentVersion)
            ->get(['id', 'uuid', 'name', 'phone', 'email', 'address', 'loyalty_points', 'credit_limit', 'balance', 'version', 'deleted_at']);

        $tombstones = DB::table('sync_tombstones')->where('version', '>', $sinceVersion)
            ->where('version', '<=', $currentVersion)->get();
        $appendTombstones = static function ($records, string $type) use ($tombstones) {
            return $records->toBase()->concat($tombstones->where('entity_type', $type)->map(fn ($row) => [
                'uuid' => $row->entity_uuid,
                'version' => (int) $row->version,
                'deleted_at' => $row->deleted_at,
            ]));
        };

        return [
            'current_version' => $currentVersion,
            'products' => $appendTombstones($products, 'products'),
            'categories' => $appendTombstones($categories, 'categories'),
            'customers' => $appendTombstones($customers, 'customers'),
            'server_timestamp' => Carbon::now()->toIso8601String(),
        ];
    }
}
