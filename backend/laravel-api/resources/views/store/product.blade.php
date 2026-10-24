@extends('store.layout')

@section('title', $product->name . ' — OmniLuxe Store')

@section('content')
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
    <!-- Breadcrumb -->
    <nav class="flex items-center gap-2 text-xs text-sage mb-8">
        <a href="{{ route('store.index') }}" class="hover:text-forest transition-colors">Home</a>
        <span>/</span>
        <a href="{{ route('store.shop', ['category' => $product->category_id]) }}" class="hover:text-forest transition-colors">{{ $product->category->name ?? 'Collection' }}</a>
        <span>/</span>
        <span class="text-ink font-semibold truncate max-w-xs">{{ $product->name }}</span>
    </nav>

    <div class="grid grid-cols-1 lg:grid-cols-12 gap-12 items-start">
        <!-- Product Imagery (Left 6 Cols) -->
        <div class="lg:col-span-6 space-y-4">
            <div class="relative bg-cream rounded-3xl overflow-hidden border border-hairline aspect-square flex items-center justify-center p-8 group shadow-sm">
                @if($product->image_url)
                    <img src="{{ $product->image_url }}" alt="{{ $product->name }}" class="w-full h-full object-contain group-hover:scale-105 transition-transform duration-500">
                @else
                    <div class="w-full h-full flex flex-col items-center justify-center text-sage">
                        <div class="w-24 h-24 rounded-full bg-paper border border-hairline flex items-center justify-center shadow-xs mb-4">
                            <span class="font-serif italic text-3xl font-extrabold text-forest">O</span>
                        </div>
                        <span class="text-xs font-semibold tracking-wider uppercase text-forest">OmniLuxe Curated Piece</span>
                    </div>
                @endif

                <!-- Badges -->
                <div class="absolute top-4 left-4 flex flex-col gap-1.5">
                    @if($product->brand)
                        <span class="text-[11px] font-bold text-forest bg-white/90 backdrop-blur-xs px-3 py-1 rounded-full border border-hairline shadow-2xs uppercase tracking-wider">
                            {{ $product->brand->name }}
                        </span>
                    @endif
                    @if($product->warranty_period)
                        <span class="text-[10px] font-semibold text-goldLuxury bg-white/90 backdrop-blur-xs px-2.5 py-0.5 rounded-full border border-goldLuxury/30 shadow-2xs">
                            ★ {{ $product->warranty_period }} Official Warranty
                        </span>
                    @endif
                </div>

                @if($product->requires_serial)
                    <div class="absolute bottom-4 left-4">
                        <span class="inline-flex items-center gap-1.5 text-[11px] font-semibold text-forest bg-forestLight/90 backdrop-blur-xs border border-forest/20 px-3 py-1 rounded-full shadow-2xs">
                            <svg class="w-3.5 h-3.5 text-forest" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                            </svg>
                            Individual IMEI / Serial Tracked
                        </span>
                    </div>
                @endif
            </div>

            <!-- Authentic Guarantee Ribbon -->
            <div class="p-4 bg-paper rounded-2xl border border-hairline flex items-center justify-between text-xs text-sage">
                <span class="flex items-center gap-2">
                    <span class="w-2 h-2 rounded-full bg-forest"></span>
                    100% Genuine Authorized Distributor Stock
                </span>
                <span class="font-semibold text-forest">SKU: {{ $product->sku ?? 'N/A' }}</span>
            </div>
        </div>

        <!-- Product Details (Right 6 Cols) -->
        <div class="lg:col-span-6 space-y-6">
            <div>
                <div class="text-xs uppercase tracking-widest font-semibold text-forest mb-2">
                    {{ $product->category->name ?? 'Premier Collection' }}
                </div>
                <h1 class="text-3xl sm:text-4xl font-serif font-extrabold text-ink leading-tight">
                    {{ $product->name }}
                </h1>
                @if($product->barcode)
                    <div class="mt-2 text-xs font-mono text-sage">
                        Barcode: {{ $product->barcode }}
                    </div>
                @endif
            </div>

            <!-- Price & Stock Status -->
            <div class="p-6 bg-cream rounded-3xl border border-hairline flex flex-wrap items-center justify-between gap-4">
                <div>
                    <div class="text-xs text-sage uppercase font-semibold">Flagship Retail Price</div>
                    <div class="text-3xl font-display font-extrabold text-forest mt-0.5">
                        {{ $store->currency_symbol ?? 'Rs.' }} {{ number_format($product->selling_price, 2) }}
                    </div>
                    <div class="text-[11px] text-sage mt-1">Inclusive of all local luxury duties & digital receipt verification</div>
                </div>

                @php
                    $inventory = $product->inventories->first();
                    $stock = $inventory ? (float)$inventory->quantity_on_hand : 10;
                @endphp
                <div class="text-right">
                    @if($stock > 5)
                        <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-800 border border-emerald-200">
                            <span class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                            In Stock at Colombo Flagship
                        </span>
                    @elseif($stock > 0)
                        <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-amber-50 text-amber-800 border border-amber-200">
                            <span class="w-2 h-2 rounded-full bg-amber-500 animate-pulse"></span>
                            Low Stock (Only {{ $stock }} remaining)
                        </span>
                    @else
                        <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-red-50 text-red-800 border border-red-200">
                            Out of Stock
                        </span>
                    @endif
                </div>
            </div>

            <!-- Description -->
            <div class="space-y-3">
                <h3 class="text-xs uppercase tracking-wider font-bold text-ink">Piece Overview</h3>
                <p class="text-sm text-sage leading-relaxed">
                    {{ $product->description ?? 'Exclusively curated for the OmniLuxe Department Store collection. Each piece is sourced through verified brand channels and backed by official warranty certification and instant tamper-evident SMS e-receipts.' }}
                </p>
            </div>

            <!-- Actions -->
            <div class="pt-4 border-t border-hairline space-y-3">
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <button type="button" 
                        onclick="addToCart({
                            id: {{ $product->id }},
                            name: '{{ addslashes($product->name) }}',
                            price: {{ $product->selling_price }},
                            warranty: '{{ addslashes($product->warranty_period ?? '') }}'
                        })"
                        class="w-full py-4 px-6 rounded-2xl bg-forest hover:bg-forestDark text-white font-display font-bold text-sm flex items-center justify-center gap-2 transition-all shadow-sm">
                        <svg class="w-5 h-5 text-goldLuxury" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 4v16m8-8H4" />
                        </svg>
                        Add to Shopping Cart
                    </button>

                    <button type="button"
                        onclick="addToCart({
                            id: {{ $product->id }},
                            name: '{{ addslashes($product->name) }}',
                            price: {{ $product->selling_price }},
                            warranty: '{{ addslashes($product->warranty_period ?? '') }}'
                        }); openCart();"
                        class="w-full py-4 px-6 rounded-2xl bg-paper hover:bg-cream border border-forest/30 text-forest font-display font-bold text-sm flex items-center justify-center gap-2 transition-all shadow-2xs">
                        Instant Checkout ➔
                    </button>
                </div>

                <div class="text-center text-xs text-sage pt-2">
                    🔒 Instant tamper-evident SMS bill dispatch & White-Glove courier handling.
                </div>
            </div>

            <!-- Collapsible Policy Badges -->
            <div class="divide-y divide-hairline border-y border-hairline pt-2">
                <div class="py-3 flex items-center justify-between text-xs text-sage">
                    <span class="font-semibold text-ink flex items-center gap-2">
                        <svg class="w-4 h-4 text-forest" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4" />
                        </svg>
                        Express White-Glove Delivery
                    </span>
                    <span>1-2 Business Days Islandwide</span>
                </div>
                <div class="py-3 flex items-center justify-between text-xs text-sage">
                    <span class="font-semibold text-ink flex items-center gap-2">
                        <svg class="w-4 h-4 text-forest" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        Official Warranty & Exchange
                    </span>
                    <span>14-Day Boutique Exchange</span>
                </div>
                <div class="py-3 flex items-center justify-between text-xs text-sage">
                    <span class="font-semibold text-ink flex items-center gap-2">
                        <svg class="w-4 h-4 text-forest" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                        </svg>
                        Customer Privacy Protected
                    </span>
                    <span>Masked Mobile & Encrypted Storage</span>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
