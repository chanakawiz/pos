@extends('store.layout')

@section('title', 'Digital Receipt — ' . $sale->invoice_number)

@section('content')
<div class="max-w-2xl mx-auto px-4 py-10">
    <div class="luxury-card rounded-3xl p-6 sm:p-8 space-y-6 shadow-2xl relative overflow-hidden">
        
        <!-- Verified Header Banner -->
        <div class="text-center space-y-2 border-b border-hairline pb-6">
            <div class="w-14 h-14 rounded-2xl bg-emeraldAccent/15 border border-emeraldAccent/30 text-emeraldAccent mx-auto flex items-center justify-center">
                <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7" />
                </svg>
            </div>
            <h1 class="text-xl font-display font-bold text-white tracking-tight">Verified Digital Tax Invoice</h1>
            <p class="text-xs text-slate-400">Official receipt from {{ $sale->store->name ?? 'SmartShop' }}</p>
            <div class="inline-block px-3 py-1 rounded-full bg-slateDark border border-hairline text-emerald-400 text-xs font-mono font-bold">
                {{ $sale->invoice_number }}
            </div>
        </div>

        <!-- Meta Information Grid -->
        <div class="grid grid-cols-2 gap-4 text-xs bg-slateDark/60 p-4 rounded-2xl border border-hairline">
            <div>
                <span class="text-slate-500 block uppercase text-[10px] font-semibold">Billed To</span>
                <span class="font-bold text-white block mt-0.5">{{ $sale->customer->name ?? 'Valued Customer' }}</span>
                @if($maskedPhone)
                    <span class="text-slate-400 font-mono text-[11px] block mt-0.5">🔒 {{ $maskedPhone }}</span>
                @endif
            </div>
            <div class="text-right">
                <span class="text-slate-500 block uppercase text-[10px] font-semibold">Date & Time</span>
                <span class="font-bold text-white block mt-0.5">{{ $sale->sold_at ? $sale->sold_at->format('d M Y, h:i A') : now()->format('d M Y, h:i A') }}</span>
                <span class="text-emerald-400 font-semibold text-[11px] block mt-0.5">Status: {{ ucfirst($sale->status) }}</span>
            </div>
        </div>

        <!-- Line Items -->
        <div class="space-y-3">
            <div class="text-xs font-bold text-slate-400 uppercase tracking-wider">Purchased Items</div>
            <div class="divide-y divide-hairline border-y border-hairline">
                @foreach($sale->items as $item)
                    <div class="py-3 flex items-start justify-between gap-3 text-xs">
                        <div class="flex-1">
                            <div class="font-bold text-white">{{ $item->product_name }}</div>
                            <div class="text-slate-400 text-[11px]">Qty: {{ $item->quantity }} × Rs. {{ number_format($item->unit_price, 2) }}</div>
                            @if($item->serial_number)
                                <div class="text-[10px] text-cyanTech font-mono mt-0.5">IMEI/SN: {{ $item->serial_number }}</div>
                            @endif
                            @if($item->warranty_expires_at)
                                <div class="text-[10px] text-goldLuxury font-medium mt-0.5">★ Warranty valid until {{ $item->warranty_expires_at->format('d M Y') }}</div>
                            @endif
                        </div>
                        <div class="text-right font-display font-bold text-white shrink-0">
                            Rs. {{ number_format($item->subtotal, 2) }}
                        </div>
                    </div>
                @endforeach
            </div>
        </div>

        <!-- Totals & Payments -->
        <div class="space-y-2 pt-2 text-xs">
            <div class="flex justify-between text-slate-400">
                <span>Subtotal</span>
                <span>Rs. {{ number_format($sale->subtotal, 2) }}</span>
            </div>
            @if($sale->discount_amount > 0)
                <div class="flex justify-between text-emerald-400">
                    <span>Discount</span>
                    <span>- Rs. {{ number_format($sale->discount_amount, 2) }}</span>
                </div>
            @endif
            @if($sale->tax_amount > 0)
                <div class="flex justify-between text-slate-400">
                    <span>Tax</span>
                    <span>Rs. {{ number_format($sale->tax_amount, 2) }}</span>
                </div>
            @endif
            <div class="flex justify-between text-base font-display font-extrabold text-white pt-2 border-t border-hairline">
                <span>Total Amount</span>
                <span class="text-emeraldAccent">Rs. {{ number_format($sale->total_amount, 2) }}</span>
            </div>
        </div>

        <!-- Customer Protection Note -->
        <div class="p-4 rounded-xl bg-slateDark border border-hairline text-[11px] text-slate-400 space-y-1">
            <div class="text-white font-bold flex items-center gap-1.5">
                <span>🛡️</span> Customer Data Protection Notice
            </div>
            <p>
                In compliance with retail privacy standards, your sensitive credentials and phone numbers are encrypted at rest. For warranty claims or exchange service, present this digital receipt or SMS verification.
            </p>
        </div>

        <!-- Actions -->
        <div class="flex flex-col sm:flex-row gap-3 pt-2">
            <button onclick="window.print()" class="flex-1 py-3 rounded-xl bg-cardDark hover:bg-cardHover border border-hairline text-slate-200 font-display font-bold text-xs flex items-center justify-center gap-2 transition-all">
                <svg class="w-4 h-4 text-emeraldAccent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4H7v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z" />
                </svg>
                <span>Print / Save PDF</span>
            </button>
            <a href="{{ route('store.index') }}" class="flex-1 py-3 rounded-xl bg-emeraldAccent hover:bg-emerald-400 text-black font-display font-extrabold text-xs flex items-center justify-center gap-2 transition-all shadow-lg shadow-emeraldAccent/20">
                <span>Continue Shopping</span>
            </a>
        </div>
    </div>
</div>
@endsection
