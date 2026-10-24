@extends('store.layout')

@section('title', 'Sign In — OmniLuxe Store VIP Member')

@section('content')
<div class="max-w-md mx-auto px-4 py-12 sm:py-16">
    <!-- Steps Tracker -->
    <div class="mb-6 bg-paper border border-hairline rounded-2xl p-4 shadow-xs">
        <div class="flex items-center justify-between text-xs font-semibold">
            <div class="flex items-center gap-2 text-forest">
                <span class="w-6 h-6 rounded-full bg-forest text-white flex items-center justify-center text-[11px] font-bold">1</span>
                <span>Identification</span>
            </div>
            <div class="w-8 h-[1px] bg-forest"></div>
            <div class="flex items-center gap-2 text-forest">
                <span class="w-6 h-6 rounded-full bg-forest text-white flex items-center justify-center text-[11px] font-bold">2</span>
                <span>Authentication</span>
            </div>
            <div class="w-8 h-[1px] bg-hairline"></div>
            <div class="flex items-center gap-2 text-sage">
                <span class="w-6 h-6 rounded-full bg-cream text-sage flex items-center justify-center text-[11px] font-bold">3</span>
                <span>VIP Active</span>
            </div>
        </div>
    </div>

    <!-- Card Container -->
    <div class="luxury-card rounded-3xl p-8 relative overflow-hidden shadow-sm border border-hairline bg-paper">
        <!-- Accent Bar -->
        <div class="absolute top-0 left-0 right-0 h-1 bg-forest"></div>

        <!-- Header -->
        <div class="text-center mb-6">
            <div class="inline-flex items-center justify-center w-12 h-12 rounded-xl bg-forestLight border border-forest/20 mb-3 shadow-xs">
                <svg class="w-6 h-6 text-forest" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                </svg>
            </div>
            <h1 class="text-2xl font-extrabold font-display text-forest tracking-tight">Customer Sign In</h1>
            <p class="text-xs text-sage mt-1">Access orders, tamper-evident SMS receipts, and VIP club points</p>
        </div>

        @if ($errors->any())
            <div class="mb-5 p-4 rounded-xl bg-red-50 border border-red-200 text-red-800 text-xs space-y-1">
                @foreach ($errors->all() as $error)
                    <div>• {{ $error }}</div>
                @endforeach
            </div>
        @endif

        <!-- Form -->
        <form action="{{ route('store.login.submit') }}" method="POST" class="space-y-4">
            @csrf
            <div>
                <label class="block text-xs font-semibold text-ink mb-1.5 uppercase tracking-wider">Step 1: Email or Phone</label>
                <input type="text" name="email" value="{{ old('email', 'customer@lifestyle.test') }}" required autofocus
                    placeholder="e.g. customer@lifestyle.test or 0771234567"
                    class="w-full bg-canvas border border-hairline rounded-xl px-4 py-2.5 text-sm text-ink placeholder-sage focus:outline-none focus:border-forest focus:ring-1 focus:ring-forest transition-all">
            </div>

            <div>
                <div class="flex items-center justify-between mb-1.5">
                    <label class="block text-xs font-semibold text-ink uppercase tracking-wider">Step 2: Password</label>
                    <span class="text-[11px] text-forest font-mono">Demo: password</span>
                </div>
                <input type="password" name="password" value="password" required
                    placeholder="Enter your password"
                    class="w-full bg-canvas border border-hairline rounded-xl px-4 py-2.5 text-sm text-ink placeholder-sage focus:outline-none focus:border-forest focus:ring-1 focus:ring-forest transition-all">
            </div>

            <div class="flex items-center justify-between text-xs text-sage pt-1">
                <label class="flex items-center gap-2 cursor-pointer">
                    <input type="checkbox" name="remember" class="rounded border-hairline text-forest focus:ring-0">
                    <span class="text-ink">Remember me</span>
                </label>
            </div>

            <button type="submit" class="w-full mt-2 py-3 px-4 rounded-xl bg-forest hover:bg-forestDark text-white font-extrabold text-sm font-display tracking-wide shadow-sm transition-all">
                Sign In to VIP Account
            </button>
        </form>

        <!-- Guest Mode Bypass Button -->
        <div class="mt-4 pt-4 border-t border-hairline">
            <a href="{{ route('store.index') }}" class="w-full py-2.5 px-4 rounded-xl bg-cream hover:bg-hairline text-forest font-bold text-xs flex items-center justify-center gap-2 border border-hairline transition-all">
                <svg class="w-4 h-4 text-forest" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
                </svg>
                <span>Continue Browsing in Guest Mode</span>
            </a>
            <p class="text-[10px] text-sage text-center mt-1.5">No login required to add to cart and receive SMS order bills.</p>
        </div>

        <!-- Instant Demo Credentials -->
        <div class="mt-5 pt-4 border-t border-hairline/60">
            <div class="text-[11px] text-sage text-center mb-2 font-medium">Instant Demonstration VIP Account</div>
            <div class="p-3 rounded-xl bg-cream border border-hairline text-xs font-mono text-ink flex items-center justify-between">
                <div>
                    <div class="text-forest font-bold">customer@lifestyle.test</div>
                    <div class="text-sage text-[10px]">VIP Gold Member • 350 Points</div>
                </div>
                <span class="text-xs px-2 py-0.5 rounded bg-forestLight text-forest font-semibold border border-forest/20">password</span>
            </div>
        </div>

        <!-- Footer Switcher -->
        <div class="mt-5 text-center text-xs text-sage">
            New to OmniLuxe Store?
            <a href="{{ route('store.register') }}" class="text-forest font-semibold hover:underline ml-1">Create VIP Account (+100 Pts)</a>
        </div>
    </div>
</div>
@endsection
