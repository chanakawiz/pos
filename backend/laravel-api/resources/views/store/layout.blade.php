<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'OmniLuxe Store — Flagship Omnichannel Retail & POS')</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://js.pusher.com/8.2.0/pusher.min.js"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        canvas: '#FBFBF9',
                        cream: '#F4F2EB',
                        paper: '#FFFFFF',
                        forest: '#233C32',
                        forestDark: '#172B23',
                        forestLight: '#EBF1EE',
                        sage: '#7B846D',
                        ink: '#242B27',
                        hairline: '#E3E5DF',
                        goldLuxury: '#C29B38',
                        goldLight: '#FAF3DF',
                        amberWarning: '#D97706',
                    },
                    fontFamily: {
                        sans: ['Inter', 'sans-serif'],
                        display: ['Outfit', 'sans-serif'],
                    }
                }
            }
        }
    </script>
    <style>
        body {
            background-color: #FBFBF9;
            color: #242B27;
            font-family: 'Inter', sans-serif;
        }
        .luxury-card {
            background-color: #FFFFFF;
            border: 1px solid #E3E5DF;
            transition: all 0.2s ease-in-out;
        }
        .luxury-card:hover {
            border-color: #233C32;
            transform: translateY(-2px);
            box-shadow: 0 10px 25px -5px rgba(35, 60, 50, 0.08);
        }
        .custom-scroll::-webkit-scrollbar {
            width: 6px;
        }
        .custom-scroll::-webkit-scrollbar-thumb {
            background: #E3E5DF;
            border-radius: 9999px;
        }
    </style>
</head>
<body class="min-h-screen flex flex-col bg-canvas text-ink antialiased selection:bg-forest selection:text-white">

    <!-- Top Announcement Bar (Editorial Cream) -->
    <div class="bg-cream border-b border-hairline py-1.5 px-4 text-xs font-medium text-forest text-center flex items-center justify-center gap-2">
        <span class="inline-block w-2 h-2 rounded-full bg-forest animate-pulse"></span>
        <span>OmniLuxe Engine Active — Real-Time Stock Synced Across Physical POS, Web Store & Mobile App</span>
        <span class="hidden md:inline text-sage">•</span>
        <span class="hidden md:inline text-ink/80">Instant SMS E-Receipts on Every Order</span>
    </div>

    <!-- Navigation Header (Clean Paper White) -->
    <header class="sticky top-0 z-40 bg-paper/95 backdrop-blur-md border-b border-hairline shadow-sm">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between gap-4">
            <!-- Brand -->
            <a href="{{ route('store.index') }}" class="flex items-center gap-3 group">
                <div class="w-10 h-10 rounded-xl bg-forest flex items-center justify-center shadow-md group-hover:scale-105 transition-transform">
                    <span class="font-display font-black text-goldLuxury text-lg">O</span>
                </div>
                <div>
                    <div class="font-display font-extrabold text-lg tracking-tight text-forest flex items-center gap-1.5">
                        OMNILUXE <span class="text-xs px-1.5 py-0.5 rounded bg-forest/10 text-forest font-bold border border-forest/20">STORE</span>
                    </div>
                    <div class="text-[10px] text-sage tracking-widest uppercase font-semibold">POS + ERP + Web + Mobile App</div>
                </div>
            </a>

            <!-- Search Bar -->
            <form action="{{ route('store.index') }}" method="GET" class="hidden md:flex flex-1 max-w-md mx-6">
                <div class="relative w-full">
                    <input type="text" name="q" value="{{ request('q') }}" placeholder="Search shoes, fashion, smartphones, IMEI..." 
                        class="w-full bg-cream/70 border border-hairline rounded-xl px-4 py-2 pl-10 text-sm text-ink placeholder-sage focus:outline-none focus:border-forest focus:ring-1 focus:ring-forest focus:bg-paper transition-all">
                    <svg class="w-4 h-4 text-sage absolute left-3.5 top-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                </div>
            </form>

            <!-- Actions & Cart Drawer Trigger -->
            <div class="flex items-center gap-2.5">
                <a href="{{ route('store.index') }}" class="hidden sm:inline-flex text-xs font-semibold px-3 py-1.5 rounded-lg bg-cream border border-hairline text-ink hover:text-forest hover:border-forest/40 transition-colors">
                    Catalog
                </a>

                @auth
                    <a href="{{ route('store.account') }}" class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-cream border border-goldLuxury/50 text-xs font-semibold text-forest hover:bg-goldLight transition-colors shadow-sm" title="My VIP Account & Orders">
                        <span class="w-2 h-2 rounded-full bg-goldLuxury"></span>
                        <span>{{ Str::limit(auth()->user()->name, 12) }}</span>
                    </a>
                @else
                    <a href="{{ route('store.login') }}" class="text-xs font-semibold px-2.5 py-1.5 text-ink hover:text-forest transition-colors">
                        Sign In
                    </a>
                    <a href="{{ route('store.register') }}" class="hidden sm:inline-flex text-xs font-bold px-3 py-1.5 rounded-lg bg-forest text-white hover:bg-forestDark transition-colors shadow-sm">
                        Join VIP (+100 Pts)
                    </a>
                @endauth

                <!-- Real-Time Push Notification Indicator -->
                <button type="button" onclick="showPusherToast('Notifications Active', 'Subscribed to real-time order and loyalty updates via Pusher Broadcast.', 'info')" 
                    class="relative p-2 rounded-xl bg-cream border border-hairline text-forest hover:border-forest transition-colors" title="Push Notifications">
                    <svg class="w-5 h-5 text-forest" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                    </svg>
                    <span id="pusherLiveDot" class="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                </button>

                <button onclick="toggleCartDrawer()" class="relative flex items-center gap-2 px-3.5 py-2 rounded-xl bg-forest hover:bg-forestDark text-white transition-all shadow-sm">
                    <svg class="w-5 h-5 text-goldLuxury" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
                    </svg>
                    <span class="text-xs font-bold font-display">Cart</span>
                    <span id="cartCountBadge" class="w-5 h-5 rounded-full bg-goldLuxury text-forest text-[11px] font-extrabold flex items-center justify-center">0</span>
                </button>
            </div>
        </div>
    </header>

    <!-- Real-Time Push Notification Toast Container (Pusher Protocol) -->
    <div id="pusherToastContainer" class="fixed top-20 right-4 z-50 flex flex-col gap-2 pointer-events-none max-w-sm w-full"></div>

    <!-- Main Content Area -->
    <main class="flex-1">
        @if(session('success'))
            <div class="max-w-7xl mx-auto px-4 mt-4">
                <div class="p-4 rounded-xl bg-forestLight border border-forest/30 text-forest text-sm flex items-center gap-3">
                    <svg class="w-5 h-5 text-forest shrink-0" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                    </svg>
                    <span class="font-medium">{{ session('success') }}</span>
                </div>
            </div>
        @endif

        @if(session('error'))
            <div class="max-w-7xl mx-auto px-4 mt-4">
                <div class="p-4 rounded-xl bg-red-50 border border-red-200 text-red-800 text-sm flex items-center gap-3">
                    <svg class="w-5 h-5 text-red-600 shrink-0" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                    </svg>
                    <span>{{ session('error') }}</span>
                </div>
            </div>
        @endif

        @yield('content')
    </main>

    <!-- Slide-over Shopping Cart Drawer (Editorial Light Theme) -->
    <div id="cartDrawer" class="fixed inset-0 z-50 overflow-hidden hidden" aria-labelledby="slide-over-title" role="dialog" aria-modal="true">
        <div class="absolute inset-0 bg-ink/40 backdrop-blur-sm transition-opacity" onclick="toggleCartDrawer()"></div>
        <div class="pointer-events-none fixed inset-y-0 right-0 flex max-w-full pl-10">
            <div class="pointer-events-auto w-screen max-w-md bg-paper border-l border-hairline flex flex-col shadow-2xl">
                <!-- Drawer Header -->
                <div class="p-5 border-b border-hairline flex items-center justify-between bg-cream">
                    <div class="flex items-center gap-2.5">
                        <svg class="w-5 h-5 text-forest" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
                        </svg>
                        <h2 class="text-base font-display font-bold text-forest tracking-tight">Shopping Cart</h2>
                    </div>
                    <button onclick="toggleCartDrawer()" class="p-1 rounded-lg text-sage hover:text-ink hover:bg-paper">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>

                <!-- Guest Mode Notice in Cart -->
                <div class="p-3 bg-forestLight border-b border-hairline text-xs text-forest flex items-center gap-2">
                    <svg class="w-4 h-4 text-forest shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                    </svg>
                    <span><strong>Guest Mode Active:</strong> Order directly without an account. Verified SMS receipt dispatched on order.</span>
                </div>

                <!-- Cart Items List -->
                <div id="cartItemsContainer" class="flex-1 overflow-y-auto p-5 space-y-4 custom-scroll bg-canvas">
                    <!-- Populated dynamically via JS -->
                </div>

                <!-- Checkout Form & Totals -->
                <div class="p-5 bg-paper border-t border-hairline space-y-4">
                    <div class="flex items-center justify-between text-sm">
                        <span class="text-sage font-medium">Subtotal</span>
                        <span id="cartSubtotal" class="font-bold text-forest font-display text-base">Rs. 0.00</span>
                    </div>

                    <!-- Fast Online Checkout Form -->
                    <form id="checkoutForm" action="{{ route('store.checkout') }}" method="POST" class="space-y-3">
                        @csrf
                        <input type="hidden" name="cart_items" id="cartItemsInput" value="[]">

                        @php
                            $authedCustomer = auth()->check() ? \App\Models\Customer::where('email', auth()->user()->email)->first() : null;
                        @endphp
                        <div>
                            <label class="block text-[11px] font-semibold text-sage uppercase tracking-wider mb-1">Your Full Name</label>
                            <input type="text" name="customer_name" required value="{{ auth()->check() ? auth()->user()->name : '' }}" placeholder="e.g. Kasun Fernando"
                                class="w-full bg-canvas border border-hairline rounded-lg px-3 py-2 text-xs text-ink placeholder-sage/70 focus:border-forest focus:outline-none">
                        </div>

                        <div>
                            <label class="block text-[11px] font-semibold text-sage uppercase tracking-wider mb-1">Mobile Number (For SMS Bill)</label>
                            <input type="tel" name="customer_phone" required value="{{ $authedCustomer->phone ?? '' }}" placeholder="e.g. 0771234567"
                                class="w-full bg-canvas border border-hairline rounded-lg px-3 py-2 text-xs text-ink placeholder-sage/70 focus:border-forest focus:outline-none">
                            <span class="text-[10px] text-forest/90 mt-0.5 block">🔒 SMS e-receipt link sent instantly upon order.</span>
                        </div>

                        <div>
                            <label class="block text-[11px] font-semibold text-sage uppercase tracking-wider mb-1">Shipping Address</label>
                            <textarea name="shipping_address" rows="2" required placeholder="Delivery address, City..."
                                class="w-full bg-canvas border border-hairline rounded-lg px-3 py-2 text-xs text-ink placeholder-sage/70 focus:border-forest focus:outline-none">{{ $authedCustomer->address ?? '' }}</textarea>
                        </div>

                        <div>
                            <label class="block text-[11px] font-semibold text-sage uppercase tracking-wider mb-1">Payment Method</label>
                            <select name="payment_method" class="w-full bg-canvas border border-hairline rounded-lg px-3 py-2 text-xs text-ink focus:border-forest focus:outline-none">
                                <option value="cod">Cash on Delivery (COD)</option>
                                <option value="card">Credit / Debit Card (Online PayHere)</option>
                                <option value="bank_transfer">Direct Bank Transfer</option>
                            </select>
                        </div>

                        <button type="submit" id="checkoutBtn" disabled
                            class="w-full py-3.5 rounded-xl bg-forest hover:bg-forestDark text-white font-display font-extrabold text-sm tracking-wide disabled:opacity-40 disabled:cursor-not-allowed shadow-md transition-all">
                            Complete Order & Receive SMS Bill
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- Footer (Warm Cream) -->
    <footer class="bg-cream border-t border-hairline mt-16 py-8 px-4 sm:px-6 lg:px-8 text-xs text-sage">
        <div class="max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4">
            <div class="flex items-center gap-2">
                <span class="font-display font-bold text-forest text-sm">OMNILUXE STORE</span>
                <span>• Omnichannel POS + ERP + Web Storefront</span>
            </div>
            <div class="flex items-center gap-6 text-ink/80">
                <span>🔐 Data Privacy Protected</span>
                <span>📱 Real-Time Sync</span>
                <span>⚡ Powered by Laravel & Flutter</span>
            </div>
        </div>
    </footer>

    <!-- Cart JavaScript Engine -->
    <script>
        let cart = JSON.parse(localStorage.getItem('smartshop_cart') || '[]');

        function saveCart() {
            localStorage.setItem('smartshop_cart', JSON.stringify(cart));
            renderCart();
        }

        function addToCart(product) {
            const existing = cart.find(i => i.product_id === product.id);
            if (existing) {
                existing.quantity += 1;
            } else {
                cart.push({
                    product_id: product.id,
                    name: product.name,
                    price: parseFloat(product.price),
                    image: product.image,
                    warranty: product.warranty,
                    quantity: 1
                });
            }
            saveCart();
            openCartDrawer();
        }

        function updateCartQty(productId, delta) {
            const item = cart.find(i => i.product_id === productId);
            if (item) {
                item.quantity += delta;
                if (item.quantity <= 0) {
                    cart = cart.filter(i => i.product_id !== productId);
                }
                saveCart();
            }
        }

        function renderCart() {
            const container = document.getElementById('cartItemsContainer');
            const countBadge = document.getElementById('cartCountBadge');
            const subtotalEl = document.getElementById('cartSubtotal');
            const itemsInput = document.getElementById('cartItemsInput');
            const checkoutBtn = document.getElementById('checkoutBtn');

            const totalCount = cart.reduce((acc, item) => acc + item.quantity, 0);
            const subtotal = cart.reduce((acc, item) => acc + (item.price * item.quantity), 0);

            countBadge.innerText = totalCount;
            subtotalEl.innerText = 'Rs. ' + subtotal.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
            itemsInput.value = JSON.stringify(cart);

            if (cart.length === 0) {
                container.innerHTML = `
                    <div class="text-center py-16 text-sage">
                        <svg class="w-12 h-12 mx-auto mb-3 opacity-30 text-sage" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
                        </svg>
                        <p class="text-sm font-medium text-ink">Your shopping cart is empty.</p>
                        <p class="text-xs text-sage mt-1">Add footwear, apparel, or electronics from the store catalog.</p>
                    </div>
                `;
                checkoutBtn.disabled = true;
            } else {
                checkoutBtn.disabled = false;
                container.innerHTML = cart.map(item => `
                    <div class="p-3.5 rounded-xl bg-paper border border-hairline flex items-center justify-between gap-3 shadow-sm">
                        <div class="flex-1 min-w-0">
                            <div class="text-xs font-bold text-ink truncate">${item.name}</div>
                            <div class="text-[11px] text-forest font-semibold mt-0.5">Rs. ${item.price.toLocaleString('en-US', { minimumFractionDigits: 2 })}</div>
                            ${item.warranty ? `<div class="text-[9px] text-goldLuxury font-medium mt-0.5">★ ${item.warranty}</div>` : ''}
                        </div>
                        <div class="flex items-center gap-2 bg-cream border border-hairline rounded-lg px-2 py-1">
                            <button type="button" onclick="updateCartQty(${item.product_id}, -1)" class="text-sage hover:text-ink font-bold text-xs px-1">-</button>
                            <span class="text-xs font-bold text-forest w-4 text-center">${item.quantity}</span>
                            <button type="button" onclick="updateCartQty(${item.product_id}, 1)" class="text-sage hover:text-ink font-bold text-xs px-1">+</button>
                        </div>
                    </div>
                `).join('');
            }
        }

        function toggleCartDrawer() {
            const drawer = document.getElementById('cartDrawer');
            drawer.classList.toggle('hidden');
        }

        function openCartDrawer() {
            document.getElementById('cartDrawer').classList.remove('hidden');
        }

        // Initialize cart on page load
        document.addEventListener('DOMContentLoaded', renderCart);

        // Real-Time Laravel Reverb WebSocket Client
        @php
            $reverbCustomerUuid = null;
            if (auth()->check()) {
                $userCustomer = auth()->user()->customerProfile ?? \App\Models\Customer::where('user_id', auth()->id())->first();
                $reverbCustomerUuid = $userCustomer?->uuid;
            }
        @endphp

        const reverbConfig = {
            key: '{{ env('REVERB_APP_KEY', 'wopxltn0qoeuklfyjfgz') }}',
            host: '{{ env('REVERB_HOST', 'localhost') }}',
            port: {{ (int) env('REVERB_PORT', 8080) }},
            scheme: '{{ env('REVERB_SCHEME', 'http') }}',
            customerUuid: '{{ $reverbCustomerUuid ?? '' }}',
            csrfToken: document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || ''
        };

        try {
            if (typeof Pusher !== 'undefined' && reverbConfig.key) {
                const reverbClient = new Pusher(reverbConfig.key, {
                    wsHost: reverbConfig.host,
                    wsPort: reverbConfig.port,
                    wssPort: reverbConfig.port,
                    forceTLS: reverbConfig.scheme === 'https',
                    enabledTransports: ['ws', 'wss'],
                    authEndpoint: '/broadcasting/auth',
                    auth: {
                        headers: {
                            'X-CSRF-TOKEN': reverbConfig.csrfToken,
                            'Accept': 'application/json'
                        }
                    }
                });

                // 1. Private Customer Channel (Strict isolation: only authenticated account owner receives their orders & VIP points)
                if (reverbConfig.customerUuid) {
                    const privateChannel = reverbClient.subscribe('private-customer.' + reverbConfig.customerUuid);
                    privateChannel.bind('notification.created', function(data) {
                        showReverbToast(data.title || 'Order Update', data.body || 'Transaction recorded.');
                    });
                }

                // 2. Public Promotions Channel (Harmless marketing announcements for all visitors)
                const promoChannel = reverbClient.subscribe('promotions');
                promoChannel.bind('promotion.published', function(data) {
                    showReverbToast(data.title || 'Exclusive Collection', data.body || 'New arrivals drop.');
                });

                // Update live status pulse
                reverbClient.connection.bind('connected', function() {
                    const dot = document.getElementById('pusherLiveDot');
                    if (dot) dot.className = 'absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-emerald-500 animate-pulse';
                });
                reverbClient.connection.bind('disconnected', function() {
                    const dot = document.getElementById('pusherLiveDot');
                    if (dot) dot.className = 'absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-amber-400';
                });
            }
        } catch(e) {
            console.warn('Reverb WebSocket client initialized in offline fallback mode', e);
        }

        // XSS-Safe Toast Notification Renderer
        function showReverbToast(title, body) {
            const container = document.getElementById('pusherToastContainer');
            if (!container) return;

            const toast = document.createElement('div');
            toast.className = 'pointer-events-auto bg-paper border border-forest/30 shadow-2xl rounded-2xl p-4 flex items-start gap-3 transition-all duration-300 transform translate-y-2 opacity-0';

            const iconBox = document.createElement('div');
            iconBox.className = 'w-9 h-9 rounded-xl bg-forest/10 border border-forest/20 flex items-center justify-center shrink-0 text-forest font-bold text-sm';
            iconBox.textContent = '★';

            const contentBox = document.createElement('div');
            contentBox.className = 'flex-1 min-w-0';

            const titleEl = document.createElement('div');
            titleEl.className = 'text-xs font-bold text-ink uppercase tracking-wider truncate';
            titleEl.textContent = title;

            const bodyEl = document.createElement('div');
            bodyEl.className = 'text-xs text-sage mt-0.5';
            bodyEl.textContent = body;

            contentBox.appendChild(titleEl);
            contentBox.appendChild(bodyEl);

            const closeBtn = document.createElement('button');
            closeBtn.className = 'text-sage hover:text-ink text-sm font-bold ml-2';
            closeBtn.textContent = '✕';
            closeBtn.onclick = () => toast.remove();

            toast.appendChild(iconBox);
            toast.appendChild(contentBox);
            toast.appendChild(closeBtn);

            container.appendChild(toast);

            setTimeout(() => {
                toast.classList.remove('translate-y-2', 'opacity-0');
            }, 50);

            setTimeout(() => {
                toast.classList.add('opacity-0', 'translate-y-2');
                setTimeout(() => toast.remove(), 400);
            }, 7000);
        }
    </script>
</body>
</html>
