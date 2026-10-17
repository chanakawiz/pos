<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Device;
use App\Models\Inventory;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use App\Services\SyncService;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\TestCase;

class SyncRevisionTest extends TestCase
{
    use DatabaseTransactions;

    public function test_updates_and_new_records_share_one_ordered_revision_sequence(): void
    {
        $service = app(SyncService::class);
        $store = Store::firstOrFail();
        $customer = Customer::firstOrFail();
        for ($i = 0; $i < 3; $i++) {
            $customer->increment('loyalty_points');
        }
        $checkpoint = $service->pullDelta($store)['current_version'];

        $product = Product::firstOrFail();
        $product->update(['selling_price' => 123.45, 'sinhala_name' => 'කිරි', 'requires_serial' => true, 'warranty_period' => '12 months']);
        $newCustomer = Customer::create(['name' => 'New sync customer']);
        $delta = $service->pullDelta($store, $checkpoint);
        $record = collect($delta['products'])->firstWhere('uuid', $product->uuid);

        $this->assertGreaterThan($checkpoint, $record['version']);
        $this->assertSame($product->id, $record['id']);
        $this->assertSame(123.45, $record['selling_price']);
        $this->assertSame('කිරි', $record['sinhala_name']);
        $this->assertTrue($record['requires_serial']);
        $this->assertSame('12 months', $record['warranty_period']);
        $this->assertSame($product->category->uuid, $record['category']['uuid']);
        $this->assertContains($newCustomer->uuid, collect($delta['customers'])->pluck('uuid'));
        $this->assertGreaterThan($product->version, $newCustomer->version);
        $this->assertEmpty($service->pullDelta($store, $delta['current_version'])['products']);
    }

    public function test_inventory_changes_invalidate_the_cached_product_stock(): void
    {
        $service = app(SyncService::class);
        $inventory = Inventory::firstOrFail();
        $checkpoint = $service->pullDelta($inventory->store)['current_version'];
        $inventory->update(['quantity_on_hand' => 7.5]);

        $delta = $service->pullDelta($inventory->store, $checkpoint);
        $record = collect($delta['products'])->firstWhere('uuid', $inventory->product->uuid);
        $this->assertNotNull($record);
        $this->assertSame(7.5, $record['stock_quantity']);
        $this->assertGreaterThan($checkpoint, $record['version']);
    }

    public function test_soft_and_permanent_deletions_and_restores_are_synchronized(): void
    {
        $service = app(SyncService::class);
        $store = Store::firstOrFail();
        $customer = Customer::create(['name' => 'Deletion test customer']);
        $checkpoint = $service->pullDelta($store)['current_version'];
        $customer->delete();
        $delta = $service->pullDelta($store, $checkpoint);
        $record = collect($delta['customers'])->firstWhere('uuid', $customer->uuid);
        $this->assertNotNull($record->deleted_at);

        $checkpoint = $delta['current_version'];
        $customer->restore();
        $delta = $service->pullDelta($store, $checkpoint);
        $this->assertNull(collect($delta['customers'])->firstWhere('uuid', $customer->uuid)->deleted_at);

        $checkpoint = $delta['current_version'];
        $customer->forceDelete();
        $record = collect($service->pullDelta($store, $checkpoint)['customers'])->firstWhere('uuid', $customer->uuid);
        $this->assertNotNull($record['deleted_at']);
        $this->assertGreaterThan($checkpoint, $record['version']);
    }

    public function test_failed_catalog_transaction_rolls_back_its_checkpoint_too(): void
    {
        $service = app(SyncService::class);
        $store = Store::firstOrFail();
        $product = Product::firstOrFail();
        $price = $product->selling_price;
        $checkpoint = $service->pullDelta($store)['current_version'];
        DB::beginTransaction();
        $product->update(['selling_price' => 999]);
        DB::rollBack();

        $this->assertSame($price, $product->fresh()->selling_price);
        $this->assertSame($checkpoint, $service->pullDelta($store)['current_version']);
        $this->assertEmpty($service->pullDelta($store, $checkpoint)['products']);
    }

    public function test_sync_rejects_another_stores_device_and_deactivated_devices(): void
    {
        $cashier = User::where('email', 'cashier1@smartshop.com')->firstOrFail();
        $otherStore = Store::create(['name' => 'Other store', 'code' => 'OTHER-'.Str::random(8)]);
        $otherDevice = Device::create([
            'store_id' => $otherStore->id, 'device_name' => 'Other lane', 'device_type' => 'windows', 'is_active' => true,
        ]);
        $this->actingAs($cashier)->getJson('/api/v1/sync/pull?device_uuid='.$otherDevice->uuid)->assertForbidden();
        $this->actingAs($cashier)->postJson('/api/v1/sync/push', [
            'device_uuid' => $otherDevice->uuid, 'transactions' => [['transaction_uuid' => (string) Str::uuid()]],
        ])->assertForbidden();

        $device = Device::where('store_id', $cashier->store_id)->firstOrFail();
        $device->update(['is_active' => false]);
        $this->actingAs($cashier)->getJson('/api/v1/sync/pull?device_uuid='.$device->uuid)->assertForbidden();
    }
}
