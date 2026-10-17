<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Services\SyncService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SyncController extends Controller
{
    public function __construct(
        protected SyncService $syncService
    ) {}

    /**
     * Push batch of offline sales/payments from a terminal.
     */
    public function push(Request $request): JsonResponse
    {
        $request->validate([
            'device_uuid' => 'required|uuid',
            'transactions' => 'required|array|max:50',
        ]);

        $device = Device::where('uuid', $request->device_uuid)->firstOrFail();
        abort_unless($device->is_active && $device->store_id === $request->user()->store_id, 403, 'Device is not authorized for this store.');
        $store = $device->store;

        $result = $this->syncService->pushTransactions(
            device: $device,
            store: $store,
            transactions: $request->transactions
        );

        return response()->json(array_merge(['status' => 'success'], $result));
    }

    /**
     * Pull delta updates since the client's last sync version.
     */
    public function pull(Request $request): JsonResponse
    {
        $request->validate([
            'device_uuid' => 'nullable|uuid',
            'since_version' => 'nullable|integer|min:0',
        ]);

        $deviceUuid = $request->input('device_uuid') ?? $request->header('X-Device-UUID');
        $device = $deviceUuid ? Device::where('uuid', $deviceUuid)->firstOrFail() : null;
        if ($device) {
            abort_unless($device->is_active && $device->store_id === $request->user()->store_id, 403, 'Device is not authorized for this store.');
        }
        $store = $device?->store ?? $request->user()->store;
        abort_unless($store, 403, 'A store must be assigned to synchronize.');

        $sinceVersion = (int) $request->query('since_version', 0);
        $delta = $this->syncService->pullDelta($store, $sinceVersion);

        return response()->json(array_merge(['status' => 'success'], $delta));
    }

    /**
     * Check sync status and server connectivity.
     */
    public function status(Request $request): JsonResponse
    {
        $deviceUuid = $request->query('device_uuid') ?? $request->header('X-Device-UUID');
        $device = $deviceUuid ? Device::where('uuid', $deviceUuid)->first() : null;

        return response()->json([
            'status' => 'success',
            'server_timestamp' => Carbon::now()->toIso8601String(),
            'device' => $device ? [
                'uuid' => $device->uuid,
                'name' => $device->device_name,
                'last_sync_at' => $device->last_sync_at?->toIso8601String(),
                'is_active' => (bool) $device->is_active,
            ] : null,
        ]);
    }
}
