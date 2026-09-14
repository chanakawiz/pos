<?php

namespace Database\Seeders;

use App\Models\Brand;
use App\Models\Category;
use App\Models\Customer;
use App\Models\Device;
use App\Models\Inventory;
use App\Models\Product;
use App\Models\StockMovement;
use App\Models\Store;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Role;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Roles
        $superAdminRole = Role::firstOrCreate(['name' => 'super_admin']);
        $adminRole = Role::firstOrCreate(['name' => 'admin']);
        $managerRole = Role::firstOrCreate(['name' => 'manager']);
        $cashierRole = Role::firstOrCreate(['name' => 'cashier']);

        // 2. Default Store
        $store = Store::firstOrCreate(
            ['code' => 'STORE-001'],
            [
                'name' => 'SmartShop Downtown Flagship',
                'phone' => '+1 (555) 019-2834',
                'email' => 'store1@smartshop.com',
                'address' => '742 Evergreen Terrace, Downtown District',
                'tax_number' => 'TAX-US-99824',
                'currency_code' => 'USD',
                'currency_symbol' => '$',
                'receipt_header' => "=== SMARTSHOP DOWNTOWN ===\nThank you for shopping local!",
                'receipt_footer' => "Goods sold are returnable within 7 days.\nVisit us at www.smartshop.com",
                'is_active' => true,
            ]
        );

        // 3. Devices
        $winDevice = Device::firstOrCreate(
            ['pairing_code' => 'POS-WIN-01'],
            [
                'store_id' => $store->id,
                'device_name' => 'Lane 01 - Windows POS',
                'device_type' => 'windows',
                'mac_address' => '00:1B:44:11:3A:B7',
                'app_version' => '1.0.0',
                'is_active' => true,
            ]
        );

        $mobileDevice = Device::firstOrCreate(
            ['pairing_code' => 'POS-IOS-01'],
            [
                'store_id' => $store->id,
                'device_name' => 'Mobile 01 - iPad Pro',
                'device_type' => 'ios',
                'mac_address' => 'F0:18:98:23:44:CD',
                'app_version' => '1.0.0',
                'is_active' => true,
            ]
        );

        // 4. Users
        $admin = User::firstOrCreate(
            ['email' => 'admin@smartshop.com'],
            [
                'store_id' => $store->id,
                'name' => 'System Administrator',
                'password' => Hash::make('password'),
                'role' => 'super_admin',
                'is_active' => true,
            ]
        );
        $admin->syncRoles([$superAdminRole]);

        $manager = User::firstOrCreate(
            ['email' => 'manager@smartshop.com'],
            [
                'store_id' => $store->id,
                'name' => 'Alex Vance (Store Manager)',
                'password' => Hash::make('password'),
                'role' => 'manager',
                'is_active' => true,
            ]
        );
        $manager->syncRoles([$managerRole]);

        $cashier = User::firstOrCreate(
            ['email' => 'cashier1@smartshop.com'],
            [
                'store_id' => $store->id,
                'name' => 'Sarah Connor (Lane 1 Cashier)',
                'pin_code_hash' => Hash::make('1234'),
                'password' => Hash::make('password'),
                'role' => 'cashier',
                'is_active' => true,
            ]
        );
        $cashier->syncRoles([$cashierRole]);

        // 5. Categories
        $categories = [
            'Beverages' => ['slug' => 'beverages', 'order' => 1],
            'Snacks & Chips' => ['slug' => 'snacks-chips', 'order' => 2],
            'Dairy & Eggs' => ['slug' => 'dairy-eggs', 'order' => 3],
            'Bakery & Bread' => ['slug' => 'bakery-bread', 'order' => 4],
            'Personal Care' => ['slug' => 'personal-care', 'order' => 5],
        ];

        $catModels = [];
        foreach ($categories as $name => $meta) {
            $catModels[$name] = Category::firstOrCreate(
                ['slug' => $meta['slug']],
                [
                    'name' => $name,
                    'display_order' => $meta['order'],
                    'is_active' => true,
                    'version' => 1,
                ]
            );
        }

        // 6. Brands
        $brands = [
            'Nescafe' => 'nescafe',
            'Coca-Cola' => 'coca-cola',
            'Lay\'s' => 'lays',
            'Anchor' => 'anchor',
            'SmartChoice' => 'smartchoice',
        ];

        $brandModels = [];
        foreach ($brands as $name => $slug) {
            $brandModels[$name] = Brand::firstOrCreate(
                ['slug' => $slug],
                [
                    'name' => $name,
                    'is_active' => true,
                    'version' => 1,
                ]
            );
        }

        // 7. Products & Inventory
        $productsData = [
            [
                'name' => 'Nescafe Gold Blend 200g',
                'sku' => 'BEV-COF-001',
                'barcode' => '8901030001001',
                'category' => 'Beverages',
                'brand' => 'Nescafe',
                'unit' => 'jar',
                'cost_price' => 7.50,
                'selling_price' => 11.99,
                'tax_rate' => 5.00,
                'min_stock_level' => 10,
                'initial_stock' => 50,
            ],
            [
                'name' => 'Coca-Cola Classic Can 330ml',
                'sku' => 'BEV-SOD-002',
                'barcode' => '8901030001002',
                'category' => 'Beverages',
                'brand' => 'Coca-Cola',
                'unit' => 'can',
                'cost_price' => 0.60,
                'selling_price' => 1.50,
                'tax_rate' => 5.00,
                'min_stock_level' => 24,
                'initial_stock' => 120,
            ],
            [
                'name' => 'Lay\'s Classic Salted Chips 150g',
                'sku' => 'SNK-CHP-001',
                'barcode' => '8901030001003',
                'category' => 'Snacks & Chips',
                'brand' => 'Lay\'s',
                'unit' => 'bag',
                'cost_price' => 1.20,
                'selling_price' => 2.49,
                'tax_rate' => 5.00,
                'min_stock_level' => 15,
                'initial_stock' => 80,
            ],
            [
                'name' => 'Anchor Pure New Zealand Butter 250g',
                'sku' => 'DRY-BUT-001',
                'barcode' => '8901030001004',
                'category' => 'Dairy & Eggs',
                'brand' => 'Anchor',
                'unit' => 'block',
                'cost_price' => 2.80,
                'selling_price' => 4.80,
                'tax_rate' => 0.00,
                'min_stock_level' => 8,
                'initial_stock' => 35,
            ],
            [
                'name' => 'Artisan Whole Wheat Sourdough Bread',
                'sku' => 'BAK-BRD-001',
                'barcode' => '8901030001005',
                'category' => 'Bakery & Bread',
                'brand' => 'SmartChoice',
                'unit' => 'loaf',
                'cost_price' => 1.50,
                'selling_price' => 3.99,
                'tax_rate' => 0.00,
                'min_stock_level' => 5,
                'initial_stock' => 25,
            ],
            [
                'name' => 'Organic Green Tea 25 Tea Bags',
                'sku' => 'BEV-TEA-003',
                'barcode' => '8901030001006',
                'category' => 'Beverages',
                'brand' => 'SmartChoice',
                'unit' => 'box',
                'cost_price' => 2.10,
                'selling_price' => 4.25,
                'tax_rate' => 5.00,
                'min_stock_level' => 10,
                'initial_stock' => 40,
            ],
        ];

        foreach ($productsData as $item) {
            $product = Product::firstOrCreate(
                ['sku' => $item['sku']],
                [
                    'name' => $item['name'],
                    'barcode' => $item['barcode'],
                    'category_id' => $catModels[$item['category']]->id,
                    'brand_id' => $brandModels[$item['brand']]->id,
                    'unit' => $item['unit'],
                    'cost_price' => $item['cost_price'],
                    'selling_price' => $item['selling_price'],
                    'tax_rate' => $item['tax_rate'],
                    'min_stock_level' => $item['min_stock_level'],
                    'is_active' => true,
                    'version' => 1,
                ]
            );

            // Inventory
            $inventory = Inventory::firstOrCreate(
                [
                    'store_id' => $store->id,
                    'product_id' => $product->id,
                    'variant_id' => null,
                ],
                [
                    'quantity_on_hand' => $item['initial_stock'],
                    'quantity_reserved' => 0,
                ]
            );

            // Initial Stock Movement
            StockMovement::firstOrCreate(
                [
                    'store_id' => $store->id,
                    'product_id' => $product->id,
                    'type' => 'adjustment',
                ],
                [
                    'user_id' => $admin->id,
                    'quantity' => $item['initial_stock'],
                    'before_quantity' => 0,
                    'after_quantity' => $item['initial_stock'],
                    'reference_uuid' => 'INIT-STOCK-' . $product->sku,
                    'notes' => 'Opening stock balance',
                ]
            );
        }

        // 8. Sample Customers
        Customer::firstOrCreate(
            ['phone' => '+15550001111'],
            [
                'name' => 'John Doe',
                'email' => 'john.doe@example.com',
                'address' => '123 Market St, Suite 4',
                'loyalty_points' => 150,
                'credit_limit' => 500.00,
                'balance' => 0.00,
                'version' => 1,
            ]
        );

        Customer::firstOrCreate(
            ['phone' => '+15550002222'],
            [
                'name' => 'Jane Smith',
                'email' => 'jane.smith@example.com',
                'address' => '456 Oak Avenue',
                'loyalty_points' => 45,
                'credit_limit' => 200.00,
                'balance' => 0.00,
                'version' => 1,
            ]
        );
    }
}
