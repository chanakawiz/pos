@extends('store.layout')

@section('title', 'My VIP Account & Orders — OmniLuxe Store')

@section('content')
<div class="max-w-6xl mx-auto px-4 py-8 sm:py-12 space-y-8">

    <!-- Top Account Banner & User Greeting -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-6 border-b border-hairline">
        <div class="flex items-center gap-4">
            <div class="w-14 h-14 rounded-2xl bg-forest flex items-center justify-center text-goldLuxury font-display font-black text-xl shadow-sm">
                {{ substr($user->name, 0, 1) }}
            </div>
            <div>
                <div class="flex items-center gap-2">
                    <h1 class="text-2xl font-extrabold font-display text-forest tracking-tight">{{ $user->name }}</h1>
                    <span class="text-xs px-2.5 py-0.5 rounded-full bg-goldLight text-forest font-bold border border-goldLuxury/30">VIP Gold</span>
                </div>
                <div class="text-xs text-sage mt-0.5">
                    {{ $user->email }} • {{ $customer->phone ?? 'SMS Registered' }}
                </div>
            </div>
        </div>

        <div class="flex items-center gap-3">
            <a href="{{ route('store.index') }}" class="px-4 py-2 rounded-xl bg-paper border border-hairline hover:border-forest text-xs font-semibold text-ink transition-colors">
                Browse Catalog
            </a>
            <form action="{{ route('store.logout') }}" method="POST">
                @csrf
                <button type="submit" class="px-4 py-2 rounded-xl bg-red-50 border border-red-200 hover:bg-red-100 text-xs font-semibold text-red-700 transition-colors">
                    Sign Out
                </button>
            </form>
        </div>
    </div>

    <!-- VIP Membership Card & Loyalty Stats Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Luxury Digital Membership Card (Deep Forest Green) -->
        <div class="lg:col-span-1">
            <div class="relative overflow-hidden rounded-3xl p-6 bg-gradient-to-br from-forest via-[#1C3229] to-[#12221C] border border-goldLuxury/50 shadow-lg text-white">
                <!-- Shiny glow effect -->
                <div class="absolute -right-12 -top-12 w-40 h-40 bg-goldLuxury/10 rounded-full blur-2xl pointer-events-none"></div>

                <div class="flex items-center justify-between mb-8">
                    <div class="flex items-center gap-2">
                        <div class="w-7 h-7 rounded-lg bg-goldLuxury flex items-center justify-center text-forest font-extrabold text-xs">
                            O
                        </div>
                        <span class="font-display font-black tracking-widest text-xs text-goldLuxury uppercase">OMNILUXE PRIVILEGE</span>
                    </div>
                    <span class="text-[10px] font-mono px-2 py-0.5 rounded bg-black/40 border border-goldLuxury/30 text-goldLuxury font-bold tracking-wider">
                        TIER 01
                    </span>
                </div>

                <div class="space-y-1 mb-8">
                    <div class="text-[10px] uppercase font-bold tracking-widest text-white/60">Cardholder</div>
                    <div class="text-lg font-display font-extrabold text-white tracking-wide uppercase">{{ $user->name }}</div>
                    <div class="text-xs font-mono text-white/60">ID: {{ substr($customer->uuid ?? $user->uuid, 0, 8) }} •••• {{ substr($customer->uuid ?? $user->uuid, -4) }}</div>
                </div>

                <div class="flex items-end justify-between pt-4 border-t border-white/20">
                    <div>
                        <div class="text-[10px] uppercase font-bold tracking-wider text-white/60">Club Loyalty Points</div>
                        <div class="text-2xl font-black font-display text-goldLuxury">{{ $customer->loyalty_points ?? 100 }} <span class="text-xs font-normal text-white/60">PTS</span></div>
                    </div>
                    <div class="text-right">
                        <div class="text-[10px] uppercase font-bold tracking-wider text-white/60">Store Credit Limit</div>
                        <div class="text-sm font-bold text-white font-mono">Rs. {{ number_format($customer->credit_limit ?? 50000, 0) }}</div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Loyalty Perks & Quick Info -->
        <div class="lg:col-span-2 grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div class="luxury-card rounded-2xl p-5 flex flex-col justify-between">
                <div>
                    <div class="w-10 h-10 rounded-xl bg-forestLight border border-forest/20 flex items-center justify-center text-forest mb-3">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                    </div>
                    <div class="text-xs font-semibold text-sage">Points Value</div>
                    <div class="text-xl font-bold font-display text-forest mt-0.5">Rs. {{ number_format(($customer->loyalty_points ?? 100) * 1.5, 2) }}</div>
                </div>
                <div class="text-[11px] text-sage mt-2">Redeemable at counter POS & online checkout</div>
            </div>

            <div class="luxury-card rounded-2xl p-5 flex flex-col justify-between">
                <div>
                    <div class="w-10 h-10 rounded-xl bg-forestLight border border-forest/20 flex items-center justify-center text-forest mb-3">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                        </svg>
                    </div>
                    <div class="text-xs font-semibold text-sage">Official Warranty</div>
                    <div class="text-xl font-bold font-display text-forest mt-0.5">IMEI Protected</div>
                </div>
                <div class="text-[11px] text-sage mt-2">Digital warranty linked to mobile phone number</div>
            </div>

            <div class="luxury-card rounded-2xl p-5 flex flex-col justify-between">
                <div>
                    <div class="w-10 h-10 rounded-xl bg-goldLight border border-goldLuxury/30 flex items-center justify-center text-goldLuxury mb-3">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
                        </svg>
                    </div>
                    <div class="text-xs font-semibold text-sage">Omnichannel Sync</div>
                    <div class="text-xl font-bold font-display text-forest mt-0.5">Unified POS</div>
                </div>
                <div class="text-[11px] text-sage mt-2">Purchases at store counter show here instantly</div>
            </div>
        </div>
    </div>

    <!-- Orders Archive Section -->
    <div class="luxury-card rounded-3xl p-6 sm:p-8 bg-paper">
        <div class="flex items-center justify-between pb-4 border-b border-hairline mb-6">
            <div>
                <h2 class="text-lg font-bold font-display text-forest tracking-tight">Purchase History & Digital Receipts</h2>
                <p class="text-xs text-sage mt-0.5">All physical POS counter and online storefront orders</p>
            </div>
            <span class="text-xs font-semibold text-sage font-mono">{{ $orders->count() }} Orders</span>
        </div>

        @if($orders->isEmpty())
            <div class="text-center py-12">
                <svg class="w-12 h-12 mx-auto text-sage/40 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                </svg>
                <div class="text-sm font-bold text-ink">No orders yet</div>
                <div class="text-xs text-sage mt-1">When you place orders online or at our physical counter registers, they will appear here.</div>
                <a href="{{ route('store.index') }}" class="inline-block mt-4 text-xs font-semibold px-4 py-2 rounded-xl bg-forest text-white hover:bg-forestDark transition-colors">Start Shopping</a>
            </div>
        @else
            <div class="space-y-4">
                @foreach($orders as $order)
                    <div class="p-4 sm:p-5 rounded-2xl bg-canvas border border-hairline flex flex-col sm:flex-row sm:items-center justify-between gap-4 hover:border-forest/40 transition-all">
                        <div class="space-y-1">
                            <div class="flex items-center gap-3">
                                <span class="font-mono font-bold text-sm text-forest">{{ $order->invoice_number }}</span>
                                <span class="text-[10px] font-semibold px-2 py-0.5 rounded-full {{ $order->payment_status === 'paid' ? 'bg-forestLight text-forest border border-forest/20' : 'bg-amber-50 text-amber-800 border border-amber-200' }}">
                                    {{ strtoupper($order->payment_status) }}
                                </span>
                                <span class="text-xs text-sage">{{ $order->sold_at ? $order->sold_at->format('M d, Y • h:i A') : $order->created_at->format('M d, Y') }}</span>
                            </div>
                            <div class="text-xs text-ink">
                                {{ $order->items->count() }} items: 
                                <span class="text-sage">
                                    {{ $order->items->pluck('product_name')->take(3)->join(', ') }}
                                    @if($order->items->count() > 3)
                                        + {{ $order->items->count() - 3 }} more
                                    @endif
                                </span>
                            </div>
                        </div>

                        <div class="flex items-center justify-between sm:justify-end gap-4 shrink-0">
                            <div class="text-right">
                                <div class="text-[10px] text-sage uppercase font-semibold">Total Amount</div>
                                <div class="text-base font-extrabold font-display text-forest">Rs. {{ number_format($order->total_amount, 2) }}</div>
                            </div>
                            <a href="{{ route('store.receipt', ['invoice' => $order->invoice_number]) }}" class="px-3.5 py-2 rounded-xl bg-paper hover:bg-cream border border-hairline text-xs font-semibold text-forest transition-colors flex items-center gap-1.5">
                                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                </svg>
                                E-Receipt
                            </a>
                        </div>
                    </div>
                @endforeach
            </div>
        @endif
    </div>

</div>
@endsection
