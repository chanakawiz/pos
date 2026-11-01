<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class HealthCheckTest extends TestCase
{
    use DatabaseTransactions;

    public function test_liveness_probe_returns_200_on_web_and_api(): void
    {
        $webResponse = $this->getJson('/health/live');
        $webResponse->assertStatus(200)
            ->assertJsonPath('status', 'ok')
            ->assertJsonPath('service', 'omniluxe-api')
            ->assertJsonStructure(['status', 'service', 'timestamp', 'php_version']);

        $apiResponse = $this->getJson('/api/v1/health/live');
        $apiResponse->assertStatus(200)
            ->assertJsonPath('status', 'ok');
    }

    public function test_readiness_probe_audits_database_cache_and_storage(): void
    {
        $response = $this->getJson('/health/ready');

        $response->assertStatus(200)
            ->assertJsonPath('status', 'healthy')
            ->assertJsonPath('service', 'omniluxe-api')
            ->assertJsonPath('checks.database.status', 'up')
            ->assertJsonPath('checks.cache.status', 'up')
            ->assertJsonPath('checks.storage.status', 'up')
            ->assertJsonPath('checks.reverb.status', 'configured')
            ->assertJsonStructure([
                'status',
                'service',
                'environment',
                'checks' => [
                    'database' => ['status', 'latency_ms', 'driver', 'database'],
                    'cache' => ['status', 'driver'],
                    'storage' => ['status', 'writable'],
                    'reverb' => ['status', 'host', 'port'],
                ],
                'timestamp',
            ]);
    }

    public function test_api_readiness_probe_returns_healthy(): void
    {
        $response = $this->getJson('/api/v1/health/ready');

        $response->assertStatus(200)
            ->assertJsonPath('status', 'healthy')
            ->assertJsonPath('checks.database.status', 'up');
    }
}
