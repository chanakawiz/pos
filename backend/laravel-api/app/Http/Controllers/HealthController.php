<?php

namespace App\Http\Controllers;

use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class HealthController extends Controller
{
    /**
     * Liveness probe: returns 200 if the PHP process is executing.
     */
    public function live(): JsonResponse
    {
        return response()->json([
            'status' => 'ok',
            'service' => 'omniluxe-api',
            'timestamp' => now()->toIso8601String(),
            'php_version' => PHP_VERSION,
        ], 200);
    }

    /**
     * Readiness probe: audits database, cache, filesystem, and broadcast configuration.
     */
    public function ready(): JsonResponse
    {
        $checks = [];
        $isHealthy = true;

        // 1. Database Check
        $dbStart = microtime(true);
        try {
            DB::connection()->getPdo();
            DB::select('SELECT 1');
            $dbDuration = round((microtime(true) - $dbStart) * 1000, 2);

            $checks['database'] = [
                'status' => 'up',
                'latency_ms' => $dbDuration,
                'driver' => config('database.default'),
                'database' => config('database.connections.' . config('database.default') . '.database'),
            ];
        } catch (Exception $e) {
            $isHealthy = false;
            $checks['database'] = [
                'status' => 'down',
                'error' => $e->getMessage(),
            ];
        }

        // 2. Cache Check
        try {
            $testKey = 'health_ping_' . uniqid();
            Cache::put($testKey, 'ok', 10);
            $val = Cache::get($testKey);
            Cache::forget($testKey);

            $checks['cache'] = [
                'status' => $val === 'ok' ? 'up' : 'degraded',
                'driver' => config('cache.default'),
            ];
            if ($val !== 'ok') {
                $isHealthy = false;
            }
        } catch (Exception $e) {
            $isHealthy = false;
            $checks['cache'] = [
                'status' => 'down',
                'error' => $e->getMessage(),
            ];
        }

        // 3. Storage Check
        $storageWritable = is_writable(storage_path('framework/cache'));
        $checks['storage'] = [
            'status' => $storageWritable ? 'up' : 'degraded',
            'writable' => $storageWritable,
        ];
        if (!$storageWritable) {
            $isHealthy = false;
        }

        // 4. Reverb WebSockets Config Check
        $reverbHost = config('reverb.servers.reverb.host', '0.0.0.0');
        $reverbPort = config('reverb.servers.reverb.port', 8080);
        $checks['reverb'] = [
            'status' => 'configured',
            'host' => $reverbHost,
            'port' => (int) $reverbPort,
            'driver' => config('broadcasting.default'),
        ];

        $statusCode = $isHealthy ? 200 : 503;

        return response()->json([
            'status' => $isHealthy ? 'healthy' : 'unhealthy',
            'service' => 'omniluxe-api',
            'environment' => config('app.env'),
            'checks' => $checks,
            'timestamp' => now()->toIso8601String(),
        ], $statusCode);
    }
}
