@extends('store.layout')

@section('title', 'Sign Up — OmniLuxe Store VIP Member')

@section('content')
<div class="max-w-lg mx-auto px-4 py-12 sm:py-20">
    <!-- Card Container -->
    <div class="luxury-card rounded-3xl p-8 relative overflow-hidden shadow-2xl border border-hairline bg-cardDark">
        <!-- Luxury Gold Gradient Accent Bar -->
        <div class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-emeraldAccent via-goldLuxury to-emeraldAccent"></div>

        <!-- Header -->
        <div class="text-center mb-6">
            <div class="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-gradient-to-br from-goldLuxury/20 to-emeraldAccent/20 border border-goldLuxury/30 mb-3 shadow-lg">
                <svg class="w-7 h-7 text-goldLuxury" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
                </svg>
            </div>
            <h1 class="text-2xl font-extrabold font-display text-white tracking-tight">Create Member Account</h1>
            <p class="text-xs text-slate-400 mt-1">Get an instant <span class="text-goldLuxury font-bold">100 Loyalty Welcome Points</span>, SMS digital receipts & VIP member pricing</p>
        </div>

        @if ($errors->any())
            <div class="mb-5 p-4 rounded-xl bg-red-950/80 border border-red-500/40 text-red-300 text-xs space-y-1">
                @foreach ($errors->all() as $error)
                    <div>• {{ $error }}</div>
                @endforeach
            </div>
        @endif

        <!-- Form -->
        <form action="{{ route('store.register.submit') }}" method="POST" class="space-y-4">
            @csrf
            <div>
                <label class="block text-xs font-semibold text-slate-300 mb-1 uppercase tracking-wider">Full Name</label>
                <input type="text" name="name" value="{{ old('name') }}" required autofocus
                    placeholder="e.g. Kasun Fernando"
                    class="w-full bg-slateDark border border-hairline rounded-xl px-4 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-emeraldAccent focus:ring-1 focus:ring-emeraldAccent transition-all">
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1 uppercase tracking-wider">Mobile Number (SMS)</label>
                    <input type="tel" name="phone" value="{{ old('phone') }}" required
                        placeholder="e.g. 0777123456"
                        class="w-full bg-slateDark border border-hairline rounded-xl px-4 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-emeraldAccent focus:ring-1 focus:ring-emeraldAccent transition-all">
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1 uppercase tracking-wider">Email Address</label>
                    <input type="email" name="email" value="{{ old('email') }}" required
                        placeholder="e.g. kasun@example.com"
                        class="w-full bg-slateDark border border-hairline rounded-xl px-4 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-emeraldAccent focus:ring-1 focus:ring-emeraldAccent transition-all">
                </div>
            </div>

            <div>
                <label class="block text-xs font-semibold text-slate-300 mb-1 uppercase tracking-wider">Delivery Address</label>
                <input type="text" name="address" value="{{ old('address') }}"
                    placeholder="e.g. 24 Flower Road, Colombo 07"
                    class="w-full bg-slateDark border border-hairline rounded-xl px-4 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-emeraldAccent focus:ring-1 focus:ring-emeraldAccent transition-all">
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1 uppercase tracking-wider">Password</label>
                    <input type="password" name="password" required minlength="6"
                        placeholder="At least 6 characters"
                        class="w-full bg-slateDark border border-hairline rounded-xl px-4 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-emeraldAccent focus:ring-1 focus:ring-emeraldAccent transition-all">
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-300 mb-1 uppercase tracking-wider">Confirm Password</label>
                    <input type="password" name="password_confirmation" required minlength="6"
                        placeholder="Re-enter password"
                        class="w-full bg-slateDark border border-hairline rounded-xl px-4 py-2.5 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-emeraldAccent focus:ring-1 focus:ring-emeraldAccent transition-all">
                </div>
            </div>

            <div class="text-[11px] text-slate-400 pt-1 flex items-center gap-2">
                <input type="checkbox" required id="agree" class="rounded bg-slateDark border-hairline text-emeraldAccent focus:ring-0">
                <label for="agree">I agree to receive SMS e-receipts and membership loyalty notifications</label>
            </div>

            <button type="submit" class="w-full mt-2 py-3.5 px-4 rounded-xl bg-gradient-to-r from-goldLuxury via-amber-400 to-emeraldAccent hover:from-amber-300 hover:to-emerald-300 text-black font-extrabold text-sm font-display tracking-wide shadow-lg shadow-goldLuxury/20 hover:scale-[1.01] active:scale-[0.99] transition-all">
                Join OmniLuxe Store VIP (+100 Points)
            </button>
        </form>

        <!-- Footer Switcher -->
        <div class="mt-6 text-center text-xs text-slate-400">
            Already have an account?
            <a href="{{ route('store.login') }}" class="text-emeraldAccent font-semibold hover:underline ml-1">Sign In</a>
        </div>
    </div>
</div>
@endsection
