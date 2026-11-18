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
                <div class="flex items-center justify-between gap-4 mb-2">
                    <div class="text-xs uppercase tracking-widest font-semibold text-forest">
                        {{ $product->category->name ?? 'Premier Collection' }}
                    </div>
                    @if(!empty($reviewSummary))
                        <a href="#customer-reviews" class="inline-flex items-center gap-1.5 text-xs text-sage hover:text-forest transition-colors">
                            <span class="text-goldLuxury text-sm">
                                @for($i = 1; $i <= 5; $i++)
                                    <span>{{ $i <= round($reviewSummary['average_rating']) ? '★' : '☆' }}</span>
                                @endfor
                            </span>
                            <span class="font-bold text-ink">{{ number_format($reviewSummary['average_rating'], 1) }}</span>
                            <span class="text-[11px]">({{ $reviewSummary['reviews_count'] }} {{ \Illuminate\Support\Str::plural('review', $reviewSummary['reviews_count']) }})</span>
                        </a>
                    @endif
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

            <!-- In-Store Boutique Availability -->
            @if(!empty($boutiqueStocks) && count($boutiqueStocks) > 0)
                <div class="p-5 bg-paper rounded-3xl border border-hairline shadow-xs space-y-4">
                    <div class="flex items-center justify-between">
                        <div class="flex items-center gap-2.5">
                            <div class="w-8 h-8 rounded-full bg-cream border border-hairline flex items-center justify-center text-forest">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                                </svg>
                            </div>
                            <div>
                                <h3 class="text-xs uppercase tracking-wider font-bold text-ink">Boutique Availability</h3>
                                <p class="text-[11px] text-sage">Live stock across OmniLuxe physical boutiques</p>
                            </div>
                        </div>
                        <span class="text-[11px] font-semibold text-goldLuxury bg-cream px-2.5 py-1 rounded-full border border-hairline">
                            Click & Collect Ready
                        </span>
                    </div>

                    <div class="divide-y divide-hairline">
                        @foreach($boutiqueStocks as $boutique)
                            <div class="py-2.5 first:pt-1 last:pb-1 flex items-center justify-between gap-3 text-xs">
                                <div>
                                    <div class="font-bold text-ink flex items-center gap-1.5">
                                        {{ $boutique['store_name'] }}
                                        <span class="text-[10px] text-sage font-normal">({{ $boutique['store_code'] }})</span>
                                    </div>
                                    <div class="text-[11px] text-sage truncate max-w-xs">
                                        {{ $boutique['address'] }} • <a href="tel:{{ $boutique['phone'] }}" class="text-forest hover:underline font-medium">{{ $boutique['phone'] }}</a>
                                    </div>
                                </div>

                                <div class="shrink-0 text-right">
                                    @if($boutique['quantity_available'] > 5)
                                        <span class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-medium bg-emerald-50 text-emerald-800 border border-emerald-200">
                                            <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                                            In Stock ({{ (int)$boutique['quantity_available'] }})
                                        </span>
                                    @elseif($boutique['quantity_available'] > 0)
                                        <span class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-medium bg-amber-50 text-amber-800 border border-amber-200">
                                            <span class="w-1.5 h-1.5 rounded-full bg-amber-500"></span>
                                            Low Stock ({{ (int)$boutique['quantity_available'] }})
                                        </span>
                                    @else
                                        <span class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-medium bg-gray-50 text-gray-500 border border-gray-200">
                                            Out of Stock
                                        </span>
                                    @endif
                                </div>
                            </div>
                        @endforeach
                    </div>
                </div>
            @endif

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

    <!-- Customer Reviews & Verified Buyer Ratings Section -->
    <div id="customer-reviews" x-data="{ showForm: false, selectedRating: 5 }" class="mt-20 pt-12 border-t border-hairline space-y-10">
        <div class="flex flex-col md:flex-row md:items-end justify-between gap-6">
            <div>
                <span class="text-xs uppercase tracking-widest font-semibold text-forest">Authentic Customer Feedback</span>
                <h2 class="text-2xl sm:text-3xl font-serif font-extrabold text-ink mt-1">Reviews & Ratings</h2>
                <p class="text-xs text-sage mt-1">Verified purchaser feedback from physical boutique counters and web store orders.</p>
            </div>

            <button
                type="button"
                @click="showForm = !showForm"
                class="inline-flex items-center gap-2 px-5 py-2.5 rounded-full bg-forest text-white hover:bg-forest/90 font-display font-bold text-xs shadow-sm transition-all self-start md:self-auto cursor-pointer">
                <span x-text="showForm ? 'Close Form' : 'Write a Review'"></span>
                <span>★</span>
            </button>
        </div>

        <!-- Rating Summary Card -->
        <div class="bg-cream rounded-3xl p-6 sm:p-8 border border-hairline grid grid-cols-1 md:grid-cols-12 gap-8 items-center">
            <!-- Left: Average Score -->
            <div class="md:col-span-4 text-center md:text-left md:border-r border-hairline md:pr-8">
                <div class="text-5xl font-serif font-extrabold text-ink">
                    {{ number_format($reviewSummary['average_rating'] ?? 5.0, 1) }}
                </div>
                <div class="flex items-center justify-center md:justify-start text-goldLuxury text-lg my-1.5">
                    @for($i = 1; $i <= 5; $i++)
                        <span>{{ $i <= round($reviewSummary['average_rating'] ?? 5.0) ? '★' : '☆' }}</span>
                    @endfor
                </div>
                <div class="text-xs text-sage">
                    Based on {{ $reviewSummary['reviews_count'] ?? 0 }} {{ \Illuminate\Support\Str::plural('review', $reviewSummary['reviews_count'] ?? 0) }}
                </div>
                @if(($reviewSummary['verified_count'] ?? 0) > 0)
                    <div class="mt-3 inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[10px] font-bold text-emerald-800 bg-emerald-100/80 border border-emerald-300">
                        <svg class="w-3 h-3 text-emerald-700" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                        </svg>
                        {{ $reviewSummary['verified_percentage'] ?? 100 }}% Verified Buyers
                    </div>
                @endif
            </div>

            <!-- Right: 5-Star Distribution Bars -->
            <div class="md:col-span-8 space-y-2">
                @foreach([5, 4, 3, 2, 1] as $star)
                    @php
                        $count = $reviewSummary['distribution'][$star] ?? 0;
                        $pct = $reviewSummary['distribution_percentages'][$star] ?? 0;
                    @endphp
                    <div class="flex items-center gap-3 text-xs">
                        <span class="w-12 font-medium text-ink shrink-0">{{ $star }} Star</span>
                        <div class="flex-1 h-2 rounded-full bg-paper border border-hairline overflow-hidden">
                            <div class="h-full bg-goldLuxury rounded-full transition-all duration-500" style="width: {{ $pct }}%"></div>
                        </div>
                        <span class="w-10 text-right text-sage text-[11px] shrink-0">{{ $count }}</span>
                    </div>
                @endforeach
            </div>
        </div>

        <!-- Write a Review Form (Collapsible) -->
        <div x-show="showForm" x-transition.opacity.duration.200ms class="bg-paper p-6 sm:p-8 rounded-3xl border border-hairline shadow-sm space-y-6">
            <div class="border-b border-hairline pb-4">
                <h3 class="text-lg font-serif font-bold text-ink">Share Your Product Experience</h3>
                <p class="text-xs text-sage mt-0.5">Your honest review helps our luxury client community and informs our curation team.</p>
            </div>

            <form action="{{ route('store.product.review', $product->id) }}" method="POST" class="space-y-5">
                @csrf

                <!-- Rating Selector -->
                <div>
                    <label class="block text-xs font-bold text-ink mb-2">Overall Rating *</label>
                    <div class="flex items-center gap-2">
                        <template x-for="star in [1, 2, 3, 4, 5]" :key="star">
                            <button
                                type="button"
                                @click="selectedRating = star"
                                class="text-2xl transition-transform hover:scale-125 focus:outline-none cursor-pointer"
                                :class="star <= selectedRating ? 'text-goldLuxury' : 'text-hairline'">
                                ★
                            </button>
                        </template>
                        <span class="text-xs font-semibold text-sage ml-2" x-text="selectedRating + ' out of 5 stars'"></span>
                    </div>
                    <input type="hidden" name="rating" :value="selectedRating">
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-bold text-ink mb-1.5">Your Name *</label>
                        <input
                            type="text"
                            name="customer_name"
                            value="{{ auth()->user()?->name ?? '' }}"
                            placeholder="e.g. Devon Lane"
                            required
                            class="w-full px-4 py-2.5 rounded-xl bg-cream border border-hairline text-ink text-xs focus:outline-none focus:border-forest transition-colors">
                    </div>
                    <div>
                        <label class="block text-xs font-bold text-ink mb-1.5">Email (For Purchase Verification)</label>
                        <input
                            type="email"
                            name="customer_email"
                            value="{{ auth()->user()?->email ?? '' }}"
                            placeholder="e.g. devon@omniluxe.store"
                            class="w-full px-4 py-2.5 rounded-xl bg-cream border border-hairline text-ink text-xs focus:outline-none focus:border-forest transition-colors">
                    </div>
                </div>

                <div>
                    <label class="block text-xs font-bold text-ink mb-1.5">Review Headline</label>
                    <input
                        type="text"
                        name="title"
                        placeholder="e.g. Flawless craftsmanship, exceptional delivery"
                        class="w-full px-4 py-2.5 rounded-xl bg-cream border border-hairline text-ink text-xs focus:outline-none focus:border-forest transition-colors">
                </div>

                <div>
                    <label class="block text-xs font-bold text-ink mb-1.5">Your Review *</label>
                    <textarea
                        name="comment"
                        rows="4"
                        placeholder="Detail your impressions regarding the design, materials, performance, and boutique packaging..."
                        required
                        class="w-full px-4 py-2.5 rounded-xl bg-cream border border-hairline text-ink text-xs focus:outline-none focus:border-forest transition-colors"></textarea>
                </div>

                <div class="flex items-center justify-end gap-3 pt-2">
                    <button
                        type="button"
                        @click="showForm = false"
                        class="px-5 py-2.5 rounded-full border border-hairline text-ink hover:bg-cream text-xs font-semibold transition-colors">
                        Cancel
                    </button>
                    <button
                        type="submit"
                        class="px-6 py-2.5 rounded-full bg-forest text-white hover:bg-forest/90 font-display font-bold text-xs shadow-sm transition-all cursor-pointer">
                        Publish Review
                    </button>
                </div>
            </form>
        </div>

        <!-- Reviews Feed -->
        <div class="space-y-4">
            @forelse($reviews ?? [] as $rev)
                <div class="bg-paper p-6 rounded-3xl border border-hairline shadow-2xs space-y-3">
                    <div class="flex items-start justify-between gap-4">
                        <div>
                            <div class="flex items-center gap-2">
                                <span class="font-bold text-ink text-sm">{{ $rev->customer_name }}</span>
                                @if($rev->is_verified_purchase)
                                    <span class="inline-flex items-center gap-1 text-[10px] font-bold text-goldLuxury bg-cream px-2 py-0.5 rounded-full border border-goldLuxury/30">
                                        <svg class="w-3 h-3 text-goldLuxury" fill="currentColor" viewBox="0 0 20 20">
                                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                                        </svg>
                                        Verified Buyer
                                    </span>
                                @endif
                            </div>
                            <div class="text-[11px] text-sage mt-0.5">{{ $rev->created_at->format('M d, Y') }}</div>
                        </div>

                        <div class="text-goldLuxury text-sm">
                            @for($i = 1; $i <= 5; $i++)
                                <span>{{ $i <= $rev->rating ? '★' : '☆' }}</span>
                            @endfor
                        </div>
                    </div>

                    @if($rev->title)
                        <h4 class="font-serif font-bold text-ink text-sm">{{ $rev->title }}</h4>
                    @endif

                    <p class="text-xs text-ink/80 leading-relaxed font-sans">{{ $rev->comment }}</p>

                    <div class="pt-2 flex items-center justify-between text-xs text-sage border-t border-hairline/60">
                        <form action="{{ route('store.review.helpful', $rev->uuid) }}" method="POST">
                            @csrf
                            <button type="submit" class="inline-flex items-center gap-1.5 text-xs text-sage hover:text-forest transition-colors cursor-pointer">
                                <span>👍 Helpful</span>
                                @if($rev->helpful_votes > 0)
                                    <span class="font-bold text-ink">({{ $rev->helpful_votes }})</span>
                                @endif
                            </button>
                        </form>
                        <span class="text-[10px]">OmniLuxe Authenticated Review</span>
                    </div>
                </div>
            @empty
                <div class="text-center py-12 bg-cream/60 rounded-3xl border border-hairline p-6">
                    <div class="text-3xl text-goldLuxury mb-2">★</div>
                    <h4 class="font-serif font-bold text-ink text-base">Be the First to Review</h4>
                    <p class="text-xs text-sage mt-1 max-w-sm mx-auto">Share your impression of the {{ $product->name }} with fellow clients.</p>
                    <button
                        type="button"
                        @click="showForm = true"
                        class="mt-4 px-5 py-2 rounded-full bg-forest text-white text-xs font-bold transition-all shadow-xs">
                        Write a Review
                    </button>
                </div>
            @endforelse
        </div>
    </div>
</div>
@endsection
