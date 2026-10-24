@extends('store.layout')

@section('title', 'SmartShop — Omnichannel Web Store & Catalog')

@section('content')
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">

    <!-- Hero Section -->
    <div class="relative overflow-hidden rounded-3xl bg-gradient-to-r from-cardDark via-slateDark to-cardDark border border-hairline p-8 md:p-12 shadow-2xl">
        <div class="absolute -right-20 -top-20 w-80 h-80 rounded-full bg-emeraldAccent/10 blur-3xl pointer-events-none"></div>
        <div class="absolute -left-20 -bottom-20 w-80 h-80 rounded-full bg-cyanTech/10 blur-3xl pointer-events-none"></div>
        
        <div class="relative z-10 max-w-2xl space-y-4">
            <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emeraldAccent/15 border border-emeraldAccent/30 text-emerald-400 text-xs font-semibold">
                <span class="w-2 h-2 rounded-full bg-emeraldAccent animate-ping"></span>
                Direct Live In-Store & Online Stock
            </div>
            <h1 class="text-3xl md:text-5xl font-display font-extrabold text-white tracking-tight leading-tight">
                Curated Luxury <br>
                <span class="bg-gradient-to-r from-emeraldAccent via-teal-300 to-cyanTech bg-clip-text text-transparent">Footwear, Apparel & Tech</span>
            </h1>
            <p class="text-slate-400 text-sm md:text-base leading-relaxed">
                Order online with fast islandwide delivery, verified device warranties, and instant digital SMS receipts powered by the SmartShop Retail Engine.
            </p>
            <div class="pt-2 flex flex-wrap gap-4 text-xs text-slate-300">
                <div class="flex items-center gap-1.5 bg-obsidian/60 border border-hairline px-3 py-1.5 rounded-lg">
                    <span class="text-emeraldAccent font-bold">✓</span> Shoe & Sizing Matrix
                </div>
                <div class="flex items-center gap-1.5 bg-obsidian/60 border border-hairline px-3 py-1.5 rounded-lg">
                    <span class="text-cyanTech font-bold">✓</span> IMEI & Serial Audited
                </div>
                <div class="flex items-center gap-1.5 bg-obsidian/60 border border-hairline px-3 py-1.5 rounded-lg">
                    <span class="text-goldLuxury font-bold">✓</span> Official Brand Warranties
                </div>
            </div>
        </div>
    </div>

    <!-- Category Filter Bar -->
    <div class="flex items-center gap-2 overflow-x-auto pb-2 custom-scroll">
        <a href="{{ route('store.index') }}" 
            class="px-4 py-2 rounded-xl text-xs font-display font-bold transition-all whitespace-nowrap {{ !request('category') ? 'bg-emeraldAccent text-black shadow-lg shadow-emeraldAccent/20' : 'bg-cardDark text-slate-300 hover:text-white border border-hairline' }}">
            All Collections
        </a>
        @foreach($categories as $cat)
            <a href="{{ route('store.index', ['category' => $cat->id]) }}" 
                class="px-4 py-2 rounded-xl text-xs font-display font-bold transition-all whitespace-nowrap {{ request('category') == $cat->id ? 'bg-emeraldAccent text-black shadow-lg shadow-emeraldAccent/20' : 'bg-cardDark text-slate-300 hover:text-white border border-hairline' }}">
                {{ $cat->name }}
            </a>
        @endforeach
    </div>

    <!-- Product Grid -->
    <div>
        <div class="flex items-center justify-between mb-4">
            <h2 class="text-base font-display font-bold text-white flex items-center gap-2">
                Available In-Stock Products
                <span class="text-xs px-2 py-0.5 rounded-full bg-slate-800 text-slate-400 border border-hairline font-normal">
                    {{ $products->count() }} items
                </span>
            </h2>
            <div class="text-xs text-slate-500">
                Prices in {{ $store->currency_symbol ?? 'Rs.' }}
            </div>
        </div>

        @if($products->isEmpty())
            <div class="text-center py-20 rounded-2xl bg-cardDark border border-hairline">
                <svg class="w-12 h-12 mx-auto text-slate-600 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
                </svg>
                <div class="text-sm font-bold text-white">No products found</div>
                <div class="text-xs text-slate-500 mt-1">Try another category or clear your search query.</div>
                <a href="{{ route('store.index') }}" class="inline-block mt-4 text-xs font-semibold px-4 py-2 rounded-xl bg-slateDark border border-hairline text-slate-300 hover:text-white">Clear Filter</a>
            </div>
        @else
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5">
                @foreach($products as $product)
                    @php
                        $stockQty = $product->getStockForStore($store->id ?? 1);
                    @endphp
                    <div class="luxury-card rounded-2xl p-4 flex flex-col justify-between group">
                        <!-- Top Badges & Meta -->
                        <div>
                            <div class="flex items-center justify-between gap-2 mb-3">
                                <span class="text-[10px] uppercase font-bold tracking-wider text-slate-400 bg-slateDark px-2 py-0.5 rounded border border-hairline truncate">
                                    {{ $product->category->name ?? 'General' }}
                                </span>
                                @if($stockQty > 0)
                                    <span class="text-[10px] font-semibold text-emerald-400 bg-emerald-950/60 border border-emerald-800/40 px-2 py-0.5 rounded-full shrink-0">
                                        {{ (int) $stockQty }} in stock
                                    </span>
                                @else
                                    <span class="text-[10px] font-semibold text-red-400 bg-red-950/60 border border-red-800/40 px-2 py-0.5 rounded-full shrink-0">
                                        Sold Out
                                    </span>
                                @endif
                            </div>

                            <!-- Product Title & Sinhala Subtitle -->
                            <h3 class="font-display font-bold text-white text-sm leading-snug group-hover:text-emeraldAccent transition-colors">
                                {{ $product->name }}
                            </h3>
                            @if($product->sinhala_name)
                                <div class="text-[11px] text-slate-400 mt-0.5">
                                    {{ $product->sinhala_name }}
                                </div>
                            @endif

                            <!-- Badges row: Serial/IMEI, Warranty -->
                            <div class="flex flex-wrap items-center gap-1.5 mt-3">
                                @if($product->requires_serial)
                                    <span class="inline-flex items-center gap-1 text-[10px] font-semibold text-cyanTech bg-cyan-950/60 border border-cyan-800/40 px-2 py-0.5 rounded">
                                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z" />
                                        </svg>
                                        IMEI / Serial
                                    </span>
                                @endif

                                @if($product->warranty_period)
                                    <span class="inline-flex items-center gap-1 text-[10px] font-semibold text-goldLuxury bg-amber-950/60 border border-amber-800/40 px-2 py-0.5 rounded">
                                        ★ {{ $product->warranty_period }}
                                    </span>
                                @endif
                            </div>
                        </div>

                        <!-- Price & Add Button -->
                        <div class="pt-4 mt-4 border-t border-hairline flex items-center justify-between gap-3">
                            <div>
                                <div class="text-[10px] text-slate-500 uppercase font-semibold">Price</div>
                                <div class="text-sm font-display font-extrabold text-white">
                                    {{ $store->currency_symbol ?? 'Rs.' }} {{ number_format($product->selling_price, 2) }}
                                </div>
                            </div>

                            <button type="button" 
                                onclick="addToCart({
                                    id: {{ $product->id }},
                                    name: '{{ addslashes($product->name) }}',
                                    price: {{ $product->selling_price }},
                                    warranty: '{{ addslashes($product->warranty_period ?? '') }}'
                                })"
                                class="px-3.5 py-2 rounded-xl bg-emeraldAccent/15 hover:bg-emeraldAccent text-emerald-400 hover:text-black border border-emeraldAccent/30 hover:border-emeraldAccent font-display font-bold text-xs flex items-center gap-1.5 transition-all">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 4v16m8-8H4" />
                                </svg>
                                <span>Bag</span>
                            </button>
                        </div>
                    </div>
                @endforeach
            </div>
        @endif
    </div>
</div>
@endsection
