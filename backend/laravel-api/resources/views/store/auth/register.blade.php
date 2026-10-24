@extends('store.layout')

@section('title', 'Sign Up — OmniLuxe Store VIP Member')

@section('content')
<div class="max-w-lg mx-auto px-4 py-12 sm:py-16">
    <!-- Steps Tracker -->
    <div class="mb-6 bg-paper border border-hairline rounded-2xl p-4 shadow-xs">
        <div class="flex items-center justify-between text-xs font-semibold">
            <div class="flex items-center gap-2 text-forest">
                <span class="w-6 h-6 rounded-full bg-forest text-white flex items-center justify-center text-[11px] font-bold">1</span>
                <span>Contact Details</span>
            </div>
            <div class="w-8 h-[1px] bg-forest"></div>
            <div class="flex items-center gap-2 text-forest">
                <span class="w-6 h-6 rounded-full bg-forest text-white flex items-center justify-center text-[11px] font-bold">2</span>
                <span>VIP & Password</span>
            </div>
            <div class="w-8 h-[1px] bg-hairline"></div>
            <div class="flex items-center gap-2 text-sage">
                <span class="w-6 h-6 rounded-full bg-cream text-sage flex items-center justify-center text-[11px] font-bold">3</span>
                <span>+100 Points</span>
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
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
                </svg>
            </div>
            <h1 class="text-2xl font-extrabold font-display text-forest tracking-tight">Create VIP Member Account</h1>
            <p class="text-xs text-sage mt-1">Get an instant <span class="text-forest font-bold">100 Loyalty Welcome Points</span>, SMS digital receipts & VIP member pricing</p>
        </div>

        @if ($errors->any())
            <div class="mb-5 p-4 rounded-xl bg-red-50 border border-red-200 text-red-800 text-xs space-y-1">
                @foreach ($errors->all() as $error)
                    <div>• {{ $error }}</div>
                @endforeach
            </div>
        @endif

        <!-- Form -->
        <form action="{{ route('store.register.submit') }}" method="POST" class="space-y-4">
            @csrf
            <div>
                <label class="block text-xs font-semibold text-ink mb-1 uppercase tracking-wider">Step 1: Full Name</label>
                <input type="text" name="name" value="{{ old('name') }}" required autofocus
                    placeholder="e.g. Kasun Fernando"
                    class="w-full bg-canvas border border-hairline rounded-xl px-4 py-2.5 text-sm text-ink placeholder-sage focus:outline-none focus:border-forest focus:ring-1 focus:ring-forest transition-all">
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                    <label class="block text-xs font-semibold text-ink mb-1 uppercase tracking-wider">Mobile Number (SMS)</label>
                    <input type="tel" name="phone" value="{{ old('phone') }}" required
                        placeholder="e.g. 0777123456"
                        class="w-full bg-canvas border border-hairline rounded-xl px-4 py-2.5 text-sm text-ink placeholder-sage focus:outline-none focus:border-forest focus:ring-1 focus:ring-forest transition-all">
                </div>
                <div>
                    <label class="block text-xs font-semibold text-ink mb-1 uppercase tracking-wider">Email Address</label>
                    <input type="email" name="email" value="{{ old('email') }}" required
                        placeholder="e.g. kasun@example.com"
                        class="w-full bg-canvas border border-hairline rounded-xl px-4 py-2.5 text-sm text-ink placeholder-sage focus:outline-none focus:border-forest focus:ring-1 focus:ring-forest transition-all">
                </div>
            </div>

            <div>
                <label class="block text-xs font-semibold text-ink mb-1 uppercase tracking-wider">Delivery Street Address</label>
                <input type="text" name="address" value="{{ old('address') }}"
                    placeholder="e.g. 24 Flower Road, Colombo 07"
                    class="w-full bg-canvas border border-hairline rounded-xl px-4 py-2.5 text-sm text-ink placeholder-sage focus:outline-none focus:border-forest focus:ring-1 focus:ring-forest transition-all">
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                    <label class="block text-xs font-semibold text-ink mb-1 uppercase tracking-wider">Step 2: Password</label>
                    <input type="password" name="password" required minlength="6"
                        placeholder="At least 6 characters"
                        class="w-full bg-canvas border border-hairline rounded-xl px-4 py-2.5 text-sm text-ink placeholder-sage focus:outline-none focus:border-forest focus:ring-1 focus:ring-forest transition-all">
                </div>
                <div>
                    <label class="block text-xs font-semibold text-ink mb-1 uppercase tracking-wider">Confirm Password</label>
                    <input type="password" name="password_confirmation" required minlength="6"
                        placeholder="Re-enter password"
                        class="w-full bg-canvas border border-hairline rounded-xl px-4 py-2.5 text-sm text-ink placeholder-sage focus:outline-none focus:border-forest focus:ring-1 focus:ring-forest transition-all">
                </div>
            </div>

            <!-- VIP Checkbox -->
            <div class="p-3 rounded-xl bg-forestLight border border-forest/20 text-xs text-forest flex items-start gap-2.5">
                <input type="checkbox" required id="agree" checked class="mt-0.5 rounded border-forest text-forest focus:ring-0">
                <label for="agree" class="leading-relaxed">
                    <strong>Enroll in OmniLuxe Privilege VIP Club:</strong> Claim 100 Welcome Points, digital SMS warranty e-receipts, and member allocations.
                </label>
            </div>

            <button type="submit" class="w-full mt-2 py-3.5 px-4 rounded-xl bg-forest hover:bg-forestDark text-white font-extrabold text-sm font-display tracking-wide shadow-sm transition-all">
                Complete Registration (+100 Points)
            </button>
        </form>

        <!-- Guest Mode Option -->
        <div class="mt-4 pt-4 border-t border-hairline">
            <a href="{{ route('store.index') }}" class="w-full py-2.5 px-4 rounded-xl bg-cream hover:bg-hairline text-forest font-bold text-xs flex items-center justify-center gap-2 border border-hairline transition-all">
                <svg class="w-4 h-4 text-forest" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
                </svg>
                <span>Continue Browsing in Guest Mode</span>
            </a>
            <p class="text-[10px] text-sage text-center mt-1.5">No login required to order with verified SMS receipts.</p>
        </div>

        <!-- Footer Switcher -->
        <div class="mt-5 text-center text-xs text-sage">
            Already have an account?
            <a href="{{ route('store.login') }}" class="text-forest font-semibold hover:underline ml-1">Sign In</a>
        </div>
    </div>
</div>
@endsection
