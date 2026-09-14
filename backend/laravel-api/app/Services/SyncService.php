<?php

namespace App\Services;

use App\Models\Brand;
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
            if (!$txUuid) {
                continue;
            }

            try {
                // Idempotency check
                $existing = Sale::where('transaction_uuid', $txUuid)->first();
                if ($existing) {
                    $syncedUuids[] = $txUuid;
                    continue;
                }

                // Determine cashier
                $cashier = null;
                if (!empty($tx['cashier_uuid'])) {
                    $cashier = User::where('uuid', $tx['cashier_uuid'])->first();
                }
                if (!$cashier) {
                    $cashier = User::where('role', 'cashier')->where('store_id', $store->id)->first()
                        ?? User::first();
                }

                $tx['source'] = 'offline';
                $tx['sync_status'] = 'synced';

                $this->billingService->processSale($tx, $store, $cashier, $device);
                $syncedUuids[] = $txUuid;
            } catch (Exception $e) {
                Log::error("Sync push failure for {$txUuid}: " . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
                $failedUuids[] = [
                    'uuid' => $txUuid,
                    'error' => $e->getMessage(),
                ];
                $errors[] = "UUID {$txUuid}: " . $e->getMessage();
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
        $maxProductVersion = (int) Product::max('version') ?? 1;
        $maxCategoryVersion = (int) Category::max('version') ?? 1;
        $maxCustomerVersion = (int) Customer::max('version') ?? 1;

        $currentVersion = max($maxProductVersion, $maxCategoryVersion, $maxCustomerVersion, 1);

        $products = Product::with(['category', 'brand', 'variants', 'inventories' => function ($q) use ($store) {
            $q->where('store_id', $store->id);
        }])
            ->where('version', '>', $sinceVersion)
            ->get()
            ->map(function ($p) use ($store) {
                $stock = $p->inventories->first()?->quantity_on_hand ?? 0.00;
                return [
                    'uuid' => $p->uuid,
                    'sku' => $p->sku,
                    'barcode' => $p->barcode,
                    'name' => $p->name,
                    'category' => $p->category?->name,
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
                ];
            });

        $categories = Category::where('version', '>', $sinceVersion)
            ->get(['uuid', 'name', 'slug', 'display_order', 'is_active', 'version']);

        $customers = Customer::where('version', '>', $sinceVersion)
            ->get(['uuid', 'name', 'phone', 'email', 'loyalty_points', 'credit_limit', 'balance', 'version']);

        return [
            'current_version' => $currentVersion,
            'products' => $products,
            'categories' => $categories,
            'customers' => $customers,
            'server_timestamp' => Carbon::now()->toIso8601String(),
        ];
    }
}
