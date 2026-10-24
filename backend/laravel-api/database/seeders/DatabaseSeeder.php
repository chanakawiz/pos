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
                'name' => 'OmniLuxe Store Flagship',
                'phone' => '+94 11 234 5678',
                'email' => 'concierge@omniluxe.store',
                'address' => '420 Galle Road, Colombo 03, Sri Lanka',
                'tax_number' => 'TAX-LK-9982400',
                'currency_code' => 'LKR',
                'currency_symbol' => 'Rs.',
                'receipt_header' => "=== OMNILUXE STORE ===\nFlagship Retail • Real-Time Omnichannel Sync",
                'receipt_footer' => "Warranties honored on presentation of SMS digital receipt.\nVisit store online at http://127.0.0.1:8000/",
                'is_active' => true,
            ]
        );

        // 3. Counter Devices for Cashiers (In-Store Desktop POS Terminals)
        $counter01 = Device::firstOrCreate(
            ['pairing_code' => 'COUNTER-01'],
            [
                'store_id' => $store->id,
                'device_name' => 'Counter Lane 01 - Flagship POS',
                'device_type' => 'windows',
                'mac_address' => '00:1B:44:11:3A:B7',
                'app_version' => '1.0.0',
                'is_active' => true,
            ]
        );

        $counter02 = Device::firstOrCreate(
            ['pairing_code' => 'COUNTER-02'],
            [
                'store_id' => $store->id,
                'device_name' => 'Counter Lane 02 - Express POS',
                'device_type' => 'windows',
                'mac_address' => '00:1B:44:11:3A:C8',
                'app_version' => '1.0.0',
                'is_active' => true,
            ]
        );

        // 4. Users (Admin ERP, Managers, Counter Cashiers, and Online Customers)
        $customerRole = Role::firstOrCreate(['name' => 'customer']);

        // Admin Users for /admin
        $admin = User::firstOrCreate(
            ['email' => 'admin@smartshop.com'],
            [
                'store_id' => $store->id,
                'name' => 'OmniLuxe Administrator',
                'password' => Hash::make('password'),
                'role' => 'super_admin',
                'is_active' => true,
            ]
        );
        $admin->syncRoles([$superAdminRole]);

        $omniluxeAdmin = User::firstOrCreate(
            ['email' => 'admin@omniluxe.store'],
            [
                'store_id' => $store->id,
                'name' => 'OmniLuxe Super Admin',
                'password' => Hash::make('password'),
                'role' => 'super_admin',
                'is_active' => true,
            ]
        );
        $omniluxeAdmin->syncRoles([$superAdminRole]);

        // Manager User for /admin
        $manager = User::firstOrCreate(
            ['email' => 'manager@smartshop.com'],
            [
                'store_id' => $store->id,
                'name' => 'Alex Vance (Flagship Manager)',
                'password' => Hash::make('password'),
                'role' => 'manager',
                'is_active' => true,
            ]
        );
        $manager->syncRoles([$managerRole]);

        // Cashier User for In-Store Counter Terminals
        $cashier = User::firstOrCreate(
            ['email' => 'cashier1@smartshop.com'],
            [
                'store_id' => $store->id,
                'name' => 'Sarah Connor (Counter 1 Cashier)',
                'pin_code_hash' => Hash::make('1234'),
                'password' => Hash::make('password'),
                'role' => 'cashier',
                'is_active' => true,
            ]
        );
        $cashier->syncRoles([$cashierRole]);

        // Online Registered Customer (Web App & Mobile App)
        $onlineCustomer = User::firstOrCreate(
            ['email' => 'customer@lifestyle.test'],
            [
                'store_id' => $store->id,
                'name' => 'Dulantha Perera',
                'password' => Hash::make('password'),
                'role' => 'customer',
                'is_active' => true,
            ]
        );
        $onlineCustomer->syncRoles([$customerRole]);

        // Seed Customer record matching this user
        Customer::firstOrCreate(
            ['phone' => '0771234567'],
            [
                'uuid' => (string) \Illuminate\Support\Str::uuid(),
                'name' => 'Dulantha Perera',
                'email' => 'customer@lifestyle.test',
                'address' => '48 Horton Place, Colombo 07',
                'loyalty_points' => 350,
                'credit_limit' => 500000.00,
                'balance' => 0.00,
                'version' => 1,
            ]
        );

        // 5. High-End Flagship Retail Vertical Categories
        $categories = [
            'Smartphones & Tech' => ['slug' => 'smartphones-tech', 'order' => 1],
            'Designer Fashion & Apparel' => ['slug' => 'designer-fashion-apparel', 'order' => 2],
            'Footwear & Sneakers' => ['slug' => 'footwear-sneakers', 'order' => 3],
            'Vehicles & Luxury Automotive' => ['slug' => 'vehicles-luxury-auto', 'order' => 4],
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

        // 6. Premium Retail Brands across Verticals
        $brands = [
            // Tech Brands
            'Apple' => 'apple',
            'Samsung' => 'samsung',
            'Anker' => 'anker',
            'Sony' => 'sony',
            // Designer Fashion & Apparel Brands
            'Studio Ceylon' => 'studio-ceylon',
            'Zara' => 'zara',
            'Ralph Lauren' => 'ralph-lauren',
            'Levi\'s' => 'levis',
            // Footwear & Sneaker Brands
            'Nike' => 'nike',
            'Adidas' => 'adidas',
            'Clarks' => 'clarks',
            'Puma' => 'puma',
            // Luxury Vehicle & Automotive Brands
            'Toyota' => 'toyota',
            'Land Rover' => 'land-rover',
            'BYD' => 'byd',
            'Honda' => 'honda',
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

        // 7. Products Matrix across all verticals (Turnkey Business Ready)
        $productsData = [
            // --- SMARTPHONES & TECH (Requires IMEI/Serial & Warranties) ---
            [
                'name' => 'Apple iPhone 16 Pro Max 256GB (Space Black)',
                'sku' => 'TECH-IPH-16PM',
                'barcode' => '445566',
                'category' => 'Smartphones & Tech',
                'brand' => 'Apple',
                'unit' => 'device',
                'warranty_period' => '1 Year Official Apple Care',
                'requires_serial' => true,
                'cost_price' => 370000.00,
                'selling_price' => 415000.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 3,
                'initial_stock' => 15,
            ],
            [
                'name' => 'Samsung Galaxy S24 Ultra 512GB (Titanium Gray)',
                'sku' => 'TECH-SAM-S24U',
                'barcode' => '556677',
                'category' => 'Smartphones & Tech',
                'brand' => 'Samsung',
                'unit' => 'device',
                'warranty_period' => '1 Year Samsung Care+',
                'requires_serial' => true,
                'cost_price' => 340000.00,
                'selling_price' => 385000.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 3,
                'initial_stock' => 12,
            ],
            [
                'name' => 'Apple AirPods Pro 2 (USB-C MagSafe)',
                'sku' => 'TECH-APP-APP2',
                'barcode' => '667788',
                'category' => 'Smartphones & Tech',
                'brand' => 'Apple',
                'unit' => 'pair',
                'warranty_period' => '1 Year Genxt Warranty',
                'requires_serial' => true,
                'cost_price' => 68000.00,
                'selling_price' => 78500.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 5,
                'initial_stock' => 25,
            ],
            [
                'name' => 'Anker Nano II 65W GaN Fast Charger',
                'sku' => 'TECH-ANK-65W',
                'barcode' => '990011',
                'category' => 'Smartphones & Tech',
                'brand' => 'Anker',
                'unit' => 'piece',
                'warranty_period' => '18 Months Replacement',
                'requires_serial' => false,
                'cost_price' => 9500.00,
                'selling_price' => 13500.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 10,
                'initial_stock' => 45,
            ],
            [
                'name' => 'Sony WH-1000XM5 Wireless Noise-Cancelling Headphones',
                'sku' => 'TECH-SNY-XM5',
                'barcode' => '778899',
                'category' => 'Smartphones & Tech',
                'brand' => 'Sony',
                'unit' => 'unit',
                'warranty_period' => '1 Year Official Warranty',
                'requires_serial' => true,
                'cost_price' => 98000.00,
                'selling_price' => 115000.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 2,
                'initial_stock' => 8,
            ],

            // --- CLOTHING & APPAREL (Studio Ceylon, Zara, Ralph Lauren) ---
            [
                'name' => 'Apple iPhone 15 Pro 128GB (Natural Titanium)',
                'sku' => 'TECH-IPH-15P',
                'barcode' => '195949038234',
                'category' => 'Smartphones & Tech',
                'brand' => 'Apple',
                'unit' => 'device',
                'warranty_period' => '1 Year Official Apple Warranty',
                'requires_serial' => true,
                'cost_price' => 310000.00,
                'selling_price' => 345000.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 3,
                'initial_stock' => 10,
            ],
            [
                'name' => 'Apple Watch Ultra 2 (Titanium GPS + Cellular)',
                'sku' => 'TECH-APP-WCHULT2',
                'barcode' => '667799',
                'category' => 'Smartphones & Tech',
                'brand' => 'Apple',
                'unit' => 'unit',
                'warranty_period' => '1 Year Official Warranty',
                'requires_serial' => true,
                'cost_price' => 240000.00,
                'selling_price' => 275000.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 2,
                'initial_stock' => 8,
            ],

            // --- DESIGNER FASHION & APPAREL (Studio Ceylon, Zara, Ralph Lauren, Levi's) ---
            [
                'name' => 'The Everyday Linen Shirt (Relaxed Fit)',
                'sku' => 'APP-LIN-SHT01',
                'barcode' => '112233',
                'category' => 'Designer Fashion & Apparel',
                'brand' => 'Studio Ceylon',
                'unit' => 'piece',
                'warranty_period' => null,
                'requires_serial' => false,
                'cost_price' => 4200.00,
                'selling_price' => 6900.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 10,
                'initial_stock' => 50,
            ],
            [
                'name' => 'Sunday Midi Linen Dress (Warm Ivory)',
                'sku' => 'APP-DRS-MID01',
                'barcode' => '887766',
                'category' => 'Designer Fashion & Apparel',
                'brand' => 'Studio Ceylon',
                'unit' => 'piece',
                'warranty_period' => null,
                'requires_serial' => false,
                'cost_price' => 5500.00,
                'selling_price' => 8900.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 5,
                'initial_stock' => 30,
            ],
            [
                'name' => 'Italian Tailored Wool Blazer (Charcoal)',
                'sku' => 'APP-BLZ-CHR01',
                'barcode' => '223344',
                'category' => 'Designer Fashion & Apparel',
                'brand' => 'Zara',
                'unit' => 'piece',
                'warranty_period' => null,
                'requires_serial' => false,
                'cost_price' => 16000.00,
                'selling_price' => 24500.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 3,
                'initial_stock' => 18,
            ],
            [
                'name' => 'Ralph Lauren Custom Slim Fit Mesh Polo',
                'sku' => 'APP-RL-POLO01',
                'barcode' => '223355',
                'category' => 'Designer Fashion & Apparel',
                'brand' => 'Ralph Lauren',
                'unit' => 'piece',
                'warranty_period' => null,
                'requires_serial' => false,
                'cost_price' => 18000.00,
                'selling_price' => 28500.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 5,
                'initial_stock' => 25,
            ],
            [
                'name' => 'Levi\'s 501 Original Fit Denim Jeans',
                'sku' => 'APP-DNM-501',
                'barcode' => '334455',
                'category' => 'Designer Fashion & Apparel',
                'brand' => 'Levi\'s',
                'unit' => 'piece',
                'warranty_period' => null,
                'requires_serial' => false,
                'cost_price' => 9500.00,
                'selling_price' => 14500.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 8,
                'initial_stock' => 40,
            ],

            // --- FOOTWEAR & SNEAKERS (Nike, Adidas, Clarks, Puma) ---
            [
                'name' => 'Nike Air Zoom Pegasus 40 Running Shoes',
                'sku' => 'FTW-NIK-PEG40',
                'barcode' => '789012',
                'category' => 'Footwear & Sneakers',
                'brand' => 'Nike',
                'unit' => 'pair',
                'warranty_period' => '6 Months Manufacturer Guarantee',
                'requires_serial' => false,
                'cost_price' => 26000.00,
                'selling_price' => 38500.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 6,
                'initial_stock' => 28,
            ],
            [
                'name' => 'Adidas Ultraboost Light Running Shoes',
                'sku' => 'FTW-ADI-UB01',
                'barcode' => '890123',
                'category' => 'Footwear & Sneakers',
                'brand' => 'Adidas',
                'unit' => 'pair',
                'warranty_period' => '6 Months Manufacturer Guarantee',
                'requires_serial' => false,
                'cost_price' => 29000.00,
                'selling_price' => 42000.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 4,
                'initial_stock' => 20,
            ],
            [
                'name' => 'Clarks Batcombe Lord Handcrafted Leather Oxford',
                'sku' => 'FTW-CLK-OXF01',
                'barcode' => '123456',
                'category' => 'Footwear & Sneakers',
                'brand' => 'Clarks',
                'unit' => 'pair',
                'warranty_period' => '1 Year Leather Care',
                'requires_serial' => false,
                'cost_price' => 19500.00,
                'selling_price' => 29500.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 4,
                'initial_stock' => 22,
            ],
            [
                'name' => 'Puma Suede Classic XXI Heritage Shoes',
                'sku' => 'FTW-PUM-SUD01',
                'barcode' => '123457',
                'category' => 'Footwear & Sneakers',
                'brand' => 'Puma',
                'unit' => 'pair',
                'warranty_period' => '6 Months Manufacturer Guarantee',
                'requires_serial' => false,
                'cost_price' => 18000.00,
                'selling_price' => 26500.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 5,
                'initial_stock' => 25,
            ],

            // --- VEHICLES & LUXURY AUTOMOTIVE (Toyota, Land Rover, BYD, Honda) ---
            [
                'name' => 'Toyota Land Cruiser Prado 250 (2025 Hybrid AWD)',
                'sku' => 'AUTO-TOY-PRADO250',
                'barcode' => '900001',
                'category' => 'Vehicles & Luxury Automotive',
                'brand' => 'Toyota',
                'unit' => 'vehicle',
                'warranty_period' => '3 Years / 100,000 km Warranty',
                'requires_serial' => true, // VIN / Chassis Number
                'cost_price' => 42000000.00,
                'selling_price' => 48500000.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 1,
                'initial_stock' => 3,
            ],
            [
                'name' => 'Land Rover Defender 110 X-Dynamic HSE',
                'sku' => 'AUTO-LRV-DEF110',
                'barcode' => '900002',
                'category' => 'Vehicles & Luxury Automotive',
                'brand' => 'Land Rover',
                'unit' => 'vehicle',
                'warranty_period' => '3 Years Manufacturer Warranty',
                'requires_serial' => true, // VIN Number
                'cost_price' => 54000000.00,
                'selling_price' => 62000000.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 1,
                'initial_stock' => 2,
            ],
            [
                'name' => 'BYD Seal EV Performance AWD (82.5 kWh)',
                'sku' => 'AUTO-BYD-SEAL01',
                'barcode' => '900003',
                'category' => 'Vehicles & Luxury Automotive',
                'brand' => 'BYD',
                'unit' => 'vehicle',
                'warranty_period' => '8 Years Battery Warranty',
                'requires_serial' => true, // VIN + Battery Pack Serial
                'cost_price' => 17000000.00,
                'selling_price' => 19800000.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 1,
                'initial_stock' => 4,
            ],
            [
                'name' => 'Honda Civic RS Turbo (Sport Edition)',
                'sku' => 'AUTO-HND-CIVICRS',
                'barcode' => '900004',
                'category' => 'Vehicles & Luxury Automotive',
                'brand' => 'Honda',
                'unit' => 'vehicle',
                'warranty_period' => '3 Years Official Warranty',
                'requires_serial' => true,
                'cost_price' => 14500000.00,
                'selling_price' => 16500000.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 1,
                'initial_stock' => 3,
            ],
            [
                'name' => 'Toyota Genuine Ceramic Brake Pad Set & Hybrid Filter',
                'sku' => 'AUTO-TOY-BRK01',
                'barcode' => '900005',
                'category' => 'Vehicles & Luxury Automotive',
                'brand' => 'Toyota',
                'unit' => 'set',
                'warranty_period' => '1 Year Parts Guarantee',
                'requires_serial' => false,
                'cost_price' => 24000.00,
                'selling_price' => 35000.00,
                'tax_rate' => 0.00,
                'min_stock_level' => 5,
                'initial_stock' => 20,
            ],
        ];

        foreach ($productsData as $item) {
            $product = Product::firstOrCreate(
                ['sku' => $item['sku']],
                [
                    'name' => $item['name'],
                    'sinhala_name' => null,
                    'barcode' => $item['barcode'],
                    'category_id' => $catModels[$item['category']]->id,
                    'brand_id' => $brandModels[$item['brand']]->id,
                    'unit' => $item['unit'],
                    'warranty_period' => $item['warranty_period'] ?? null,
                    'requires_serial' => $item['requires_serial'] ?? false,
                    'cost_price' => $item['cost_price'],
                    'selling_price' => $item['selling_price'],
                    'tax_rate' => $item['tax_rate'],
                    'min_stock_level' => $item['min_stock_level'],
                    'is_active' => true,
                    'version' => 1,
                ]
            );

            // Seed Inventory for Flagship Store
            Inventory::firstOrCreate(
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

            // Record Initial Stock Movement
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
                    'notes' => 'Opening stock balance for ' . $product->name,
                ]
            );
        }

        // 8. Sample Customers
        Customer::firstOrCreate(
            ['phone' => '+94771234567'],
            [
                'name' => 'Kasun Fernando',
                'email' => 'kasun.f@example.lk',
                'address' => '12 Havelock Road, Colombo 05',
                'loyalty_points' => 320,
                'credit_limit' => 250000.00,
                'balance' => 0.00,
                'version' => 1,
            ]
        );

        Customer::firstOrCreate(
            ['phone' => '+94719876543'],
            [
                'name' => 'Dilini Perera',
                'email' => 'dilini.p@example.lk',
                'address' => '88 Kandy Road, Kiribathgoda',
                'loyalty_points' => 140,
                'credit_limit' => 100000.00,
                'balance' => 0.00,
                'version' => 1,
            ]
        );
    }
}
