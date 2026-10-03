<?php

namespace Database\Seeders;

use App\Models\Brand;
use App\Models\Category;
use App\Models\Inventory;
use App\Models\Product;
use App\Models\StockMovement;
use Illuminate\Database\Seeder;

class SmartItemsSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Tech & Smart Brands
        $apple = Brand::firstOrCreate(['slug' => 'apple'], ['name' => 'Apple', 'is_active' => true, 'version' => 1]);
        $samsung = Brand::firstOrCreate(['slug' => 'samsung'], ['name' => 'Samsung', 'is_active' => true, 'version' => 1]);
        $sony = Brand::firstOrCreate(['slug' => 'sony'], ['name' => 'Sony', 'is_active' => true, 'version' => 1]);
        $anker = Brand::firstOrCreate(['slug' => 'anker'], ['name' => 'Anker', 'is_active' => true, 'version' => 1]);
        $xiaomi = Brand::firstOrCreate(['slug' => 'xiaomi'], ['name' => 'Xiaomi', 'is_active' => true, 'version' => 1]);

        // 2. Categories for Smart Items, Mobile Devices & All Goods
        $smartphonesCat = Category::firstOrCreate(
            ['slug' => 'smartphones-tablets'],
            ['name' => 'Smart Phones & Tablets', 'display_order' => 1, 'is_active' => true, 'version' => 1]
        );
        $wearablesCat = Category::firstOrCreate(
            ['slug' => 'smart-wearables'],
            ['name' => 'Smart Wearables & Audio', 'display_order' => 2, 'is_active' => true, 'version' => 1]
        );
        $accessoriesCat = Category::firstOrCreate(
            ['slug' => 'cables-power'],
            ['name' => 'Chargers & Smart Accessories', 'display_order' => 3, 'is_active' => true, 'version' => 1]
        );

        // 3. Products
        $smartProducts = [
            [
                'name' => 'iPhone 15 Pro 128GB Titanium',
                'sinhala_name' => 'අයිෆෝන් 15 ප්‍රෝ 128GB ටයිටේනියම්',
                'sku' => 'MOB-IPH-15P',
                'barcode' => '195949038210',
                'category_id' => $smartphonesCat->id,
                'brand_id' => $apple->id,
                'unit' => 'piece',
                'warranty_period' => '1 Year Apple Care Warranty',
                'requires_serial' => true,
                'cost_price' => 880.00,
                'selling_price' => 999.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 3,
                'stock' => 12,
            ],
            [
                'name' => 'Samsung Galaxy S24 Ultra 256GB',
                'sinhala_name' => 'සැම්සුන්ග් ගැලැක්සි S24 අල්ට්‍රා 256GB',
                'sku' => 'MOB-SAM-S24U',
                'barcode' => '880609530123',
                'category_id' => $smartphonesCat->id,
                'brand_id' => $samsung->id,
                'unit' => 'piece',
                'warranty_period' => '12 Months Samsung Official Warranty',
                'requires_serial' => true,
                'cost_price' => 1050.00,
                'selling_price' => 1199.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 3,
                'stock' => 8,
            ],
            [
                'name' => 'Apple AirPods Pro 2 (USB-C)',
                'sinhala_name' => 'ඇපල් එයාර්පොඩ්ස් ප්‍රෝ 2 (USB-C)',
                'sku' => 'AUD-APP-PRO2',
                'barcode' => '195949052568',
                'category_id' => $wearablesCat->id,
                'brand_id' => $apple->id,
                'unit' => 'set',
                'warranty_period' => '6 Months Company Warranty',
                'requires_serial' => true,
                'cost_price' => 180.00,
                'selling_price' => 249.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 5,
                'stock' => 20,
            ],
            [
                'name' => 'Apple Watch Series 9 GPS 45mm',
                'sinhala_name' => 'ඇපල් වොච් සීරීස් 9 GPS 45mm',
                'sku' => 'SMT-WAT-AW9',
                'barcode' => '195949041289',
                'category_id' => $wearablesCat->id,
                'brand_id' => $apple->id,
                'unit' => 'piece',
                'warranty_period' => '1 Year Apple Official Warranty',
                'requires_serial' => true,
                'cost_price' => 320.00,
                'selling_price' => 429.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 2,
                'stock' => 10,
            ],
            [
                'name' => 'Anker 65W GaN Fast Charger (3-Port)',
                'sinhala_name' => 'ඇන්කර් 65W වේගවත් චාජර් (පෝර්ට් 3)',
                'sku' => 'PWR-ANK-65W',
                'barcode' => '848061061234',
                'category_id' => $accessoriesCat->id,
                'brand_id' => $anker->id,
                'unit' => 'piece',
                'warranty_period' => '18 Months Anker Direct Replacement',
                'requires_serial' => false,
                'cost_price' => 28.00,
                'selling_price' => 49.99,
                'tax_rate' => 0.00,
                'min_stock_level' => 5,
                'stock' => 35,
            ],
            [
                'name' => 'Xiaomi Smart Band 8 Active Black',
                'sinhala_name' => 'ෂියෝමි ස්මාර්ට් බෑන්ඩ් 8 ඇක්ටිව්',
                'sku' => 'SMT-XIA-BND8',
                'barcode' => '694181273456',
                'category_id' => $wearablesCat->id,
                'brand_id' => $xiaomi->id,
                'unit' => 'piece',
                'warranty_period' => '6 Months Warranty',
                'requires_serial' => false,
                'cost_price' => 22.00,
                'selling_price' => 39.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 4,
                'stock' => 25,
            ],
        ];

        foreach ($smartProducts as $item) {
            $stock = $item['stock'];
            unset($item['stock']);

            $product = Product::firstOrCreate(
                ['sku' => $item['sku']],
                array_merge($item, ['is_active' => true, 'version' => 1])
            );

            Inventory::firstOrCreate(
                ['store_id' => 1, 'product_id' => $product->id],
                ['quantity_on_hand' => $stock, 'quantity_reserved' => 0]
            );

            StockMovement::firstOrCreate(
                [
                    'store_id' => 1,
                    'product_id' => $product->id,
                    'type' => 'purchase',
                ],
                [
                    'quantity' => $stock,
                    'before_quantity' => 0,
                    'after_quantity' => $stock,
                    'reference_uuid' => $product->uuid,
                    'notes' => 'Smart item initial stock receiving',
                ]
            );
        }
    }
}
