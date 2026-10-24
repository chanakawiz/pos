@extends('store.layout')

@section('title', 'Sign In — SmartShop Luxe VIP Member')

@section('content')
<div class="max-w-md mx-auto px-4 py-16 sm:py-24">
    <!-- Card Container -->
    <div class="luxury-card rounded-3xl p-8 relative overflow-hidden shadow-2xl border border-hairline bg-cardDark">
        <!-- Luxury Gold Gradient Accent Bar -->
        <div class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-emeraldAccent via-goldLuxury to-emeraldAccent"></div>

        <!-- Header -->
        <div class="text-center mb-8">
            <div class="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-gradient-to-br from-emeraldAccent/20 to-goldLuxury/20 border border-emeraldAccent/30 mb-4 shadow-lg">
                <svg class="w-7 h-7 text-emeraldAccent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                </svg>
            </div>
            <h1 class="text-2xl font-extrabold font-display text-white tracking-tight">Customer Sign In</h1>
            <p class="text-xs text-slate-400 mt-1.5">Access your orders, digital e-receipts, and VIP club points</p>
        </div>

        @if ($errors->any())
            <div class="mb-6 p-4 rounded-xl bg-red-950/80 border border-red-500/40 text-red-300 text-xs space-y-1">
                @foreach ($errors->all() as $error)
                    <div>• {{ $error }}</div>
                @endforeach
            </div>
        @endif

        <!-- Form -->
        <form action="{{ route('store.login.submit') }}" method="POST" class="space-y-4">
            @csrf
            <div>
                <label class="block text-xs font-semibold text-slate-300 mb-1.5 uppercase tracking-wider">Email or Phone</label>
                <input type="text" name="email" value="{{ old('email', 'customer@lifestyle.test') }}" required autofocus
                    placeholder="e.g. customer@lifestyle.test or 0771234567"
                    class="w-full bg-slateDark border border-hairline rounded-xl px-4 py-3 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-emeraldAccent focus:ring-1 focus:ring-emeraldAccent transition-all">
            </div>

            <div>
                <div class="flex items-center justify-between mb-1.5">
                    <label class="block text-xs font-semibold text-slate-300 uppercase tracking-wider">Password</label>
                    <span class="text-[11px] text-emerald-400 font-mono">Demo: password</span>
                </div>
                <input type="password" name="password" value="password" required
                    placeholder="Enter your password"
                    class="w-full bg-slateDark border border-hairline rounded-xl px-4 py-3 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-emeraldAccent focus:ring-1 focus:ring-emeraldAccent transition-all">
            </div>

            <div class="flex items-center justify-between text-xs text-slate-400 pt-1">
                <label class="flex items-center gap-2 cursor-pointer">
                    <input type="checkbox" name="remember" class="rounded bg-slateDark border-hairline text-emeraldAccent focus:ring-0">
                    <span>Remember me</span>
                </label>
            </div>

            <button type="submit" class="w-full mt-2 py-3.5 px-4 rounded-xl bg-gradient-to-r from-emeraldAccent to-cyanTech hover:from-emerald-400 hover:to-cyan-400 text-black font-extrabold text-sm font-display tracking-wide shadow-lg shadow-emeraldAccent/20 hover:scale-[1.01] active:scale-[0.99] transition-all">
                Sign In to My Account
            </button>
        </form>

        <!-- Demo Quick Sign-in Help -->
        <div class="mt-6 pt-5 border-t border-hairline/60">
            <div class="text-[11px] text-slate-400 text-center mb-3">Instant Demonstration Credentials</div>
            <div class="p-3 rounded-xl bg-slateDark/70 border border-hairline text-xs font-mono text-slate-300 flex items-center justify-between">
                <div>
                    <div class="text-white font-bold">customer@lifestyle.test</div>
                    <div class="text-slate-500 text-[10px]">VIP Gold Member • 350 Points</div>
                </div>
                <span class="text-xs px-2 py-0.5 rounded bg-emeraldAccent/20 text-emerald-400 font-semibold border border-emeraldAccent/30">password</span>
            </div>
        </div>

        <!-- Footer Switcher -->
        <div class="mt-6 text-center text-xs text-slate-400">
            New to SmartShop Luxe?
            <a href="{{ route('store.register') }}" class="text-emeraldAccent font-semibold hover:underline ml-1">Create an Account (+100 Pts)</a>
        </div>
    </div>
</div>
@endsection
