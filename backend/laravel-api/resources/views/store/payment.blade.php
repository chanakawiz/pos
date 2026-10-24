@extends('store.layout')

@section('title', 'Secure Checkout & Payment — OmniLuxe Store')

@section('content')
<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
    <div class="mb-8 text-center space-y-2">
        <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-forest/10 border border-forest/20 text-forest text-xs font-semibold">
            <span class="w-2 h-2 rounded-full bg-forest animate-pulse"></span>
            Bank-Grade 256-Bit SSL Encrypted
        </span>
        <h1 class="text-2xl md:text-3xl font-display font-extrabold text-forest">Complete Payment</h1>
        <p class="text-sage text-xs md:text-sm">Invoice #{{ $sale->invoice_number }} • Total Due: <strong class="text-ink">{{ $store->currency_symbol ?? 'Rs.' }} {{ number_format($transaction->amount, 2) }}</strong></p>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-12 gap-8 items-start" x-data="{ tab: 'card', isSubmitting: false }">
        
        <!-- Left: Payment Methods & Gateway Forms -->
        <div class="md:col-span-7 space-y-6">
            
            <!-- Payment Method Selector Tabs -->
            <div class="flex rounded-2xl bg-cream border border-hairline p-1.5 gap-1.5">
                <button type="button" @click="tab = 'card'"
                    :class="tab === 'card' ? 'bg-forest text-white shadow-xs' : 'text-sage hover:text-ink'"
                    class="flex-1 py-2.5 rounded-xl text-xs font-display font-bold transition-all flex items-center justify-center gap-2">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <rect x="2" y="5" width="20" height="14" rx="2" stroke-width="1.5" />
                        <line x1="2" y1="10" x2="22" y2="10" stroke-width="1.5" />
                    </svg>
                    Credit / Debit Card
                </button>
                <button type="button" @click="tab = 'payhere'"
                    :class="tab === 'payhere' ? 'bg-forest text-white shadow-xs' : 'text-sage hover:text-ink'"
                    class="flex-1 py-2.5 rounded-xl text-xs font-display font-bold transition-all flex items-center justify-center gap-2">
                    <span class="text-amber-400 font-extrabold text-xs">P</span>
                    PayHere Gateway
                </button>
                <button type="button" @click="tab = 'sandbox'"
                    :class="tab === 'sandbox' ? 'bg-forest text-white shadow-xs' : 'text-sage hover:text-ink'"
                    class="flex-1 py-2.5 rounded-xl text-xs font-display font-bold transition-all flex items-center justify-center gap-2">
                    <span class="text-emerald-400 font-extrabold text-xs">⚡</span>
                    Quick Settle
                </button>
            </div>

            <!-- Tab 1: Credit / Debit Card Direct Authorization -->
            <div x-show="tab === 'card'" class="bg-paper border border-hairline rounded-3xl p-6 shadow-sm space-y-5">
                <div class="flex items-center justify-between pb-3 border-b border-hairline">
                    <span class="text-xs font-display font-bold text-ink">Cardholder Details</span>
                    <div class="flex gap-2">
                        <span class="px-2 py-0.5 rounded bg-cream border border-hairline text-[10px] font-bold text-forest">VISA</span>
                        <span class="px-2 py-0.5 rounded bg-cream border border-hairline text-[10px] font-bold text-forest">Mastercard</span>
                        <span class="px-2 py-0.5 rounded bg-cream border border-hairline text-[10px] font-bold text-forest">AMEX</span>
                    </div>
                </div>

                <form action="{{ route('store.payment.process', ['uuid' => $transaction->uuid]) }}" method="POST" @submit="isSubmitting = true" class="space-y-4">
                    @csrf
                    <div>
                        <label class="block text-[11px] font-semibold text-sage uppercase tracking-wider mb-1">Card Number</label>
                        <div class="relative">
                            <input type="text" name="card_number" required placeholder="4242 •••• •••• 4242" value="4242 •••• •••• 4242"
                                class="w-full bg-canvas border border-hairline rounded-xl px-3.5 py-2.5 text-xs text-ink font-mono focus:border-forest focus:outline-none">
                            <span class="absolute right-3 top-2.5 text-forest">🔒</span>
                        </div>
                    </div>

                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label class="block text-[11px] font-semibold text-sage uppercase tracking-wider mb-1">Expiry (MM/YY)</label>
                            <input type="text" name="card_expiry" required placeholder="12/28" value="12/28"
                                class="w-full bg-canvas border border-hairline rounded-xl px-3.5 py-2.5 text-xs text-ink font-mono focus:border-forest focus:outline-none">
                        </div>
                        <div>
                            <label class="block text-[11px] font-semibold text-sage uppercase tracking-wider mb-1">CVC / CVV</label>
                            <input type="password" name="card_cvc" required placeholder="•••" value="888" maxlength="4"
                                class="w-full bg-canvas border border-hairline rounded-xl px-3.5 py-2.5 text-xs text-ink font-mono focus:border-forest focus:outline-none">
                        </div>
                    </div>

                    <div>
                        <label class="block text-[11px] font-semibold text-sage uppercase tracking-wider mb-1">Name on Card</label>
                        <input type="text" name="card_holder" required placeholder="Cardholder Name" value="{{ $sale->customer?->name ?? 'Kasun Fernando' }}"
                            class="w-full bg-canvas border border-hairline rounded-xl px-3.5 py-2.5 text-xs text-ink focus:border-forest focus:outline-none">
                    </div>

                    <button type="submit" :disabled="isSubmitting"
                        class="w-full py-3.5 rounded-xl bg-forest hover:bg-forestDark text-white font-display font-extrabold text-xs tracking-wider uppercase shadow-md transition-all flex items-center justify-center gap-2">
                        <span x-show="!isSubmitting">Authorize {{ $store->currency_symbol ?? 'Rs.' }} {{ number_format($transaction->amount, 2) }}</span>
                        <span x-show="isSubmitting" class="animate-pulse">Authorizing Payment...</span>
                    </button>
                </form>
            </div>

            <!-- Tab 2: PayHere Gateway Hosted Redirect -->
            <div x-show="tab === 'payhere'" class="bg-paper border border-hairline rounded-3xl p-6 shadow-sm space-y-5" style="display: none;">
                <div class="flex items-center gap-3">
                    <div class="w-10 h-10 rounded-xl bg-amber-500/10 border border-amber-500/20 text-amber-600 flex items-center justify-center font-bold">
                        P
                    </div>
                    <div>
                        <h3 class="text-sm font-bold text-ink">PayHere Official Payment Gateway</h3>
                        <p class="text-xs text-sage">Supports Sri Lanka Local Cards, Genie, Frimi, eZ Cash & mCash.</p>
                    </div>
                </div>

                @php
                    $payload = $transaction->payload_json ?? [];
                @endphp

                <form method="POST" action="{{ $payload['action_url'] ?? 'https://sandbox.payhere.lk/pay/checkout' }}" class="space-y-3">
                    @foreach($payload as $key => $val)
                        @if($key !== 'action_url')
                            <input type="hidden" name="{{ $key }}" value="{{ $val }}">
                        @endif
                    @endforeach

                    <div class="p-4 rounded-2xl bg-cream border border-hairline text-xs text-sage space-y-1.5">
                        <div class="flex justify-between"><span>Merchant ID:</span><span class="font-mono text-ink font-semibold">{{ $payload['merchant_id'] ?? '1210001' }}</span></div>
                        <div class="flex justify-between"><span>Order Reference:</span><span class="font-mono text-ink font-semibold">{{ $sale->invoice_number }}</span></div>
                        <div class="flex justify-between"><span>Security MD5 Hash:</span><span class="font-mono text-[10px] text-forest truncate max-w-xs">{{ $payload['hash'] ?? 'VERIFIED_HASH' }}</span></div>
                    </div>

                    <button type="submit"
                        class="w-full py-3.5 rounded-xl bg-forest hover:bg-forestDark text-white font-display font-extrabold text-xs tracking-wider uppercase shadow-md transition-all flex items-center justify-center gap-2">
                        Proceed to PayHere Gateway &rarr;
                    </button>
                </form>
            </div>

            <!-- Tab 3: Quick Settle Sandbox Mode -->
            <div x-show="tab === 'sandbox'" class="bg-paper border border-hairline rounded-3xl p-6 shadow-sm space-y-4" style="display: none;">
                <div class="flex items-center gap-3">
                    <div class="w-10 h-10 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-600 flex items-center justify-center font-bold">
                        ✓
                    </div>
                    <div>
                        <h3 class="text-sm font-bold text-ink">Sandbox Instant Confirmation</h3>
                        <p class="text-xs text-sage">Test the entire real-time stock and notification pipeline without actual cards.</p>
                    </div>
                </div>

                <form action="{{ route('store.payment.process', ['uuid' => $transaction->uuid]) }}" method="POST">
                    @csrf
                    <input type="hidden" name="card_number" value="4000-0000-0000-TEST">
                    <button type="submit"
                        class="w-full py-3.5 rounded-xl bg-emerald-700 hover:bg-emerald-800 text-white font-display font-extrabold text-xs tracking-wider uppercase shadow-md transition-all flex items-center justify-center gap-2">
                        Simulate Instant Settlement & Receipt &rarr;
                    </button>
                </form>
            </div>

            <!-- Cancel & Back Links -->
            <div class="flex items-center justify-between text-xs text-sage px-2">
                <a href="{{ route('store.payment.cancel', ['uuid' => $transaction->uuid]) }}" class="hover:text-red-600 transition-colors">
                    &larr; Cancel payment and return to store
                </a>
                <span>Order held for 30 minutes</span>
            </div>
        </div>

        <!-- Right: Order Summary Slip -->
        <div class="md:col-span-5 bg-paper border border-hairline rounded-3xl p-6 shadow-sm space-y-5">
            <div class="pb-3 border-b border-hairline">
                <span class="text-[10px] font-bold text-sage uppercase tracking-wider">Order Summary</span>
                <h3 class="font-display font-bold text-forest text-base mt-0.5">{{ $sale->invoice_number }}</h3>
            </div>

            <!-- Order Items -->
            <div class="space-y-3 max-h-60 overflow-y-auto custom-scroll pr-1">
                @foreach($sale->items as $item)
                    <div class="flex items-center justify-between text-xs">
                        <div class="truncate max-w-[180px]">
                            <div class="font-semibold text-ink truncate">{{ $item->product->name }}</div>
                            <div class="text-[10px] text-sage">Qty: {{ (int) $item->quantity }} • {{ $store->currency_symbol ?? 'Rs.' }} {{ number_format($item->unit_price, 2) }}</div>
                        </div>
                        <span class="font-bold text-ink font-mono">{{ $store->currency_symbol ?? 'Rs.' }} {{ number_format($item->total, 2) }}</span>
                    </div>
                @endforeach
            </div>

            <!-- Price Breakdown -->
            <div class="pt-4 border-t border-hairline space-y-2 text-xs">
                <div class="flex justify-between text-sage">
                    <span>Subtotal</span>
                    <span>{{ $store->currency_symbol ?? 'Rs.' }} {{ number_format($sale->subtotal, 2) }}</span>
                </div>
                @if($sale->discount_amount > 0)
                    <div class="flex justify-between text-emerald-600">
                        <span>VIP Points Discount</span>
                        <span>-{{ $store->currency_symbol ?? 'Rs.' }} {{ number_format($sale->discount_amount, 2) }}</span>
                    </div>
                @endif
                <div class="flex justify-between text-sage">
                    <span>Delivery</span>
                    <span class="text-forest font-semibold">Complimentary</span>
                </div>
                <div class="pt-3 border-t border-hairline flex justify-between font-display font-extrabold text-base text-forest">
                    <span>Total Due</span>
                    <span>{{ $store->currency_symbol ?? 'Rs.' }} {{ number_format($sale->total_amount, 2) }}</span>
                </div>
            </div>

            <!-- Customer & Delivery -->
            <div class="pt-4 border-t border-hairline text-xs space-y-1">
                <div class="text-[10px] uppercase font-bold text-sage tracking-wider">Deliver To</div>
                <div class="font-semibold text-ink">{{ $sale->customer?->name }}</div>
                <div class="text-sage text-[11px] leading-relaxed">{{ $sale->customer?->address }}</div>
                <div class="text-forest text-[11px] font-semibold mt-1">📱 SMS Receipt to {{ $sale->customer?->phone }}</div>
            </div>
        </div>

    </div>
</div>
@endsection
