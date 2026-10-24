@extends('store.layout')

@section('title', 'Digital Receipt — ' . $sale->invoice_number)

@section('content')
<div class="max-w-2xl mx-auto px-4 py-12">
    <div class="bg-paper rounded-3xl p-6 sm:p-10 space-y-8 border border-hairline shadow-md relative overflow-hidden">
        
        <!-- Verified Header Banner -->
        <div class="text-center space-y-3 border-b border-hairline pb-8">
            <div class="w-16 h-16 rounded-full bg-forestLight border border-forest/20 text-forest mx-auto flex items-center justify-center shadow-xs">
                <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7" />
                </svg>
            </div>
            <div class="space-y-1">
                <span class="text-xs uppercase tracking-widest font-bold text-forest">OmniLuxe Flagship Retail</span>
                <h1 class="text-2xl font-serif font-extrabold text-ink tracking-tight">Verified Digital Tax Invoice</h1>
                <p class="text-xs text-sage">Official electronic receipt issued by {{ $sale->store->name ?? 'OmniLuxe Urban Flagship' }}</p>
            </div>
            <div class="inline-block px-4 py-1.5 rounded-full bg-cream border border-hairline text-forest text-xs font-mono font-bold shadow-2xs">
                {{ $sale->invoice_number }}
            </div>
        </div>

        <!-- Meta Information Grid -->
        <div class="grid grid-cols-2 gap-4 text-xs bg-cream p-5 rounded-2xl border border-hairline">
            <div>
                <span class="text-sage block uppercase text-[10px] font-bold tracking-wider">Billed To</span>
                <span class="font-display font-bold text-ink block mt-1 text-sm">{{ $sale->customer->name ?? 'Valued Customer' }}</span>
                @if($maskedPhone)
                    <span class="text-sage font-mono text-[11px] block mt-0.5">🔒 {{ $maskedPhone }}</span>
                @endif
            </div>
            <div class="text-right">
                <span class="text-sage block uppercase text-[10px] font-bold tracking-wider">Date & Time</span>
                <span class="font-display font-bold text-ink block mt-1 text-sm">{{ $sale->sold_at ? $sale->sold_at->format('d M Y, h:i A') : now()->format('d M Y, h:i A') }}</span>
                <span class="text-forest font-semibold text-[11px] block mt-0.5">Status: <span class="capitalize">{{ $sale->status }}</span></span>
            </div>
        </div>

        <!-- Line Items -->
        <div class="space-y-3">
            <div class="text-xs font-bold text-ink uppercase tracking-wider">Purchased Items</div>
            <div class="divide-y divide-hairline border-y border-hairline">
                @foreach($sale->items as $item)
                    <div class="py-4 flex items-start justify-between gap-4 text-xs">
                        <div class="flex-1 space-y-1">
                            <div class="font-display font-bold text-ink text-sm">{{ $item->product_name }}</div>
                            <div class="text-sage text-xs">Qty: {{ $item->quantity }} × {{ $sale->store->currency_symbol ?? 'Rs.' }} {{ number_format($item->unit_price, 2) }}</div>
                            @if($item->serial_number)
                                <div class="text-[11px] text-forest font-mono">IMEI/SN: {{ $item->serial_number }}</div>
                            @endif
                            @if($item->warranty_expires_at)
                                <div class="text-[11px] text-goldLuxury font-semibold">★ Warranty valid until {{ $item->warranty_expires_at->format('d M Y') }}</div>
                            @endif
                        </div>
                        <div class="text-right font-display font-bold text-ink text-sm shrink-0">
                            {{ $sale->store->currency_symbol ?? 'Rs.' }} {{ number_format($item->subtotal, 2) }}
                        </div>
                    </div>
                @endforeach
            </div>
        </div>

        <!-- Totals & Payments -->
        <div class="space-y-2 pt-2 text-xs">
            <div class="flex justify-between text-sage">
                <span>Subtotal</span>
                <span>{{ $sale->store->currency_symbol ?? 'Rs.' }} {{ number_format($sale->subtotal, 2) }}</span>
            </div>
            @if($sale->discount_amount > 0)
                <div class="flex justify-between text-forest font-semibold">
                    <span>VIP Member Savings</span>
                    <span>- {{ $sale->store->currency_symbol ?? 'Rs.' }} {{ number_format($sale->discount_amount, 2) }}</span>
                </div>
            @endif
            @if($sale->tax_amount > 0)
                <div class="flex justify-between text-sage">
                    <span>Tax & Surcharges</span>
                    <span>{{ $sale->store->currency_symbol ?? 'Rs.' }} {{ number_format($sale->tax_amount, 2) }}</span>
                </div>
            @endif
            <div class="flex justify-between text-lg font-display font-extrabold text-forest pt-3 border-t border-hairline">
                <span>Total Amount</span>
                <span>{{ $sale->store->currency_symbol ?? 'Rs.' }} {{ number_format($sale->total_amount, 2) }}</span>
            </div>
        </div>

        <!-- Customer Protection Note -->
        <div class="p-4 rounded-2xl bg-cream border border-hairline text-xs text-sage space-y-1">
            <div class="text-ink font-bold flex items-center gap-1.5">
                <span>🔒</span> Customer Data Privacy & Warranty Protection
            </div>
            <p class="leading-relaxed">
                In strict compliance with consumer data privacy, your mobile phone is masked on public views. To claim warranty services, present this electronic invoice link or your SMS dispatch code at any boutique.
            </p>
        </div>

        <!-- Actions -->
        <div class="flex flex-col sm:flex-row gap-3 pt-2">
            <button onclick="window.print()" class="flex-1 py-3.5 rounded-2xl bg-paper hover:bg-cream border border-hairline text-ink font-display font-bold text-xs flex items-center justify-center gap-2 transition-all shadow-2xs">
                <svg class="w-4 h-4 text-forest" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4H7v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z" />
                </svg>
                <span>Print Official PDF Receipt</span>
            </button>
            <a href="{{ route('store.index') }}" class="flex-1 py-3.5 rounded-2xl bg-forest hover:bg-forestDark text-white font-display font-extrabold text-xs flex items-center justify-center gap-2 transition-all shadow-sm">
                <span>Continue Shopping ➔</span>
            </a>
        </div>
    </div>
</div>
@endsection
