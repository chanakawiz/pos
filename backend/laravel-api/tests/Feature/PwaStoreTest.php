<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

class PwaStoreTest extends TestCase
{
    use DatabaseTransactions;

    public function test_pwa_manifest_is_served_and_valid_json(): void
    {
        $manifestPath = public_path('manifest.json');
        $this->assertFileExists($manifestPath);

        $content = file_get_contents($manifestPath);
        $manifest = json_decode($content, true);

        $this->assertIsArray($manifest);
        $this->assertEquals('OmniLuxe Store - Flagship Retail', $manifest['name']);
        $this->assertEquals('OmniLuxe', $manifest['short_name']);
        $this->assertEquals('#233C32', $manifest['theme_color']);
        $this->assertEquals('#FBFBF9', $manifest['background_color']);
        $this->assertEquals('standalone', $manifest['display']);
        $this->assertNotEmpty($manifest['icons']);
    }

    public function test_service_worker_script_exists_and_implements_caching(): void
    {
        $swPath = public_path('sw.js');
        $this->assertFileExists($swPath);

        $content = file_get_contents($swPath);
        $this->assertStringContainsString('omniluxe-cache-v1', $content);
        $this->assertStringContainsString('/offline', $content);
        $this->assertStringContainsString('caches.open', $content);
        $this->assertStringContainsString('caches.match', $content);
    }

    public function test_offline_fallback_view_is_accessible(): void
    {
        $response = $this->get('/offline');

        $response->assertStatus(200)
            ->assertSee('Boutique Connection Paused')
            ->assertSee('Offline Mode')
            ->assertSee('+94 11 234 5678')
            ->assertSee('Colombo Flagship');
    }

    public function test_web_storefront_links_pwa_manifest_and_registers_worker(): void
    {
        $response = $this->get('/');

        $response->assertStatus(200)
            ->assertSee('href="/manifest.json"', false)
            ->assertSee('content="#233C32"', false)
            ->assertSee('navigator.serviceWorker.register', false);
    }
}
