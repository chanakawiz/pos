<!DOCTYPE html>
<html lang="en" class="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'SmartShop — Luxury Retail & Online Storefront')</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            darkMode: 'class',
            theme: {
                extend: {
                    colors: {
                        obsidian: '#0A0E17',
                        slateDark: '#111827',
                        cardDark: '#162032',
                        cardHover: '#1D2A42',
                        hairline: '#223048',
                        emeraldAccent: '#10B981',
                        cyanTech: '#06B6D4',
                        goldLuxury: '#D4AF37',
                        amberWarning: '#F59E0B',
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
            background-color: #0A0E17;
            color: #F8FAFC;
            font-family: 'Inter', sans-serif;
        }
        .luxury-card {
            background-color: #162032;
            border: 1px solid #223048;
            transition: all 0.25s ease-in-out;
        }
        .luxury-card:hover {
            border-color: #33496B;
            transform: translateY(-2px);
            box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.4);
        }
        .custom-scroll::-webkit-scrollbar {
            width: 6px;
        }
        .custom-scroll::-webkit-scrollbar-thumb {
            background: #223048;
            border-radius: 9999px;
        }
    </style>
</head>
<body class="min-h-screen flex flex-col bg-obsidian text-slate-100 antialiased selection:bg-emeraldAccent selection:text-black">

    <!-- Top Announcement Bar -->
    <div class="bg-gradient-to-r from-emerald-950 via-slate-900 to-emerald-950 border-b border-hairline py-1.5 px-4 text-xs font-medium text-emerald-400 text-center flex items-center justify-center gap-2">
        <span class="inline-block w-2 h-2 rounded-full bg-emeraldAccent animate-pulse"></span>
        <span>Unified Retail Engine Active — Real-Time Stock Synced Across Physical POS & Online Web Store</span>
        <span class="hidden md:inline text-slate-500">•</span>
        <span class="hidden md:inline text-slate-400">Instant SMS E-Receipts on Every Order</span>
    </div>

    <!-- Navigation Header -->
    <header class="sticky top-0 z-40 bg-obsidian/95 backdrop-blur-md border-b border-hairline">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between gap-4">
            <!-- Brand -->
            <a href="{{ route('store.index') }}" class="flex items-center gap-3 group">
                <div class="w-10 h-10 rounded-xl bg-gradient-to-br from-emeraldAccent to-cyanTech flex items-center justify-center shadow-lg shadow-emeraldAccent/20 group-hover:scale-105 transition-transform">
                    <svg class="w-5 h-5 text-black font-bold" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
                    </svg>
                </div>
                <div>
                    <div class="font-display font-extrabold text-lg tracking-tight text-white flex items-center gap-1.5">
                        SMARTSHOP <span class="text-xs px-1.5 py-0.5 rounded bg-emeraldAccent/20 text-emeraldAccent font-semibold border border-emeraldAccent/30">LUXE</span>
                    </div>
                    <div class="text-[10px] text-slate-400 tracking-widest uppercase">POS + ERP + Web Store</div>
                </div>
            </a>

            <!-- Search Bar -->
            <form action="{{ route('store.index') }}" method="GET" class="hidden md:flex flex-1 max-w-md mx-6">
                <div class="relative w-full">
                    <input type="text" name="q" value="{{ request('q') }}" placeholder="Search shoes, fashion, smartphones, IMEI..." 
                        class="w-full bg-slateDark border border-hairline rounded-xl px-4 py-2 pl-10 text-sm text-slate-200 placeholder-slate-500 focus:outline-none focus:border-emeraldAccent focus:ring-1 focus:ring-emeraldAccent transition-all">
                    <svg class="w-4 h-4 text-slate-400 absolute left-3.5 top-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                </div>
            </form>

            <!-- Actions & Cart Drawer Trigger -->
            <div class="flex items-center gap-3">
                <a href="{{ route('store.index') }}" class="hidden sm:inline-flex text-xs font-semibold px-3 py-1.5 rounded-lg bg-cardDark border border-hairline text-slate-300 hover:text-white hover:border-slate-600 transition-colors">
                    Catalog
                </a>

                <a href="/admin" target="_blank" class="hidden sm:inline-flex items-center gap-1.5 text-xs font-semibold px-3 py-1.5 rounded-lg bg-cardDark border border-hairline text-amber-400 hover:text-white hover:border-amber-400/50 transition-colors" title="Open Admin Control Room">
                    <span>⚡</span> Admin ERP
                </a>

                <button onclick="toggleCartDrawer()" class="relative flex items-center gap-2 px-3.5 py-2 rounded-xl bg-cardDark hover:bg-cardHover border border-hairline text-slate-200 transition-all">
                    <svg class="w-5 h-5 text-emeraldAccent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
                    </svg>
                    <span class="text-xs font-bold font-display">Bag</span>
                    <span id="cartCountBadge" class="w-5 h-5 rounded-full bg-emeraldAccent text-black text-[11px] font-extrabold flex items-center justify-center">0</span>
                </button>
            </div>
        </div>
    </header>

    <!-- Main Content Area -->
    <main class="flex-1">
        @if(session('success'))
            <div class="max-w-7xl mx-auto px-4 mt-4">
                <div class="p-4 rounded-xl bg-emerald-950/80 border border-emeraldAccent/40 text-emerald-300 text-sm flex items-center gap-3">
                    <svg class="w-5 h-5 text-emeraldAccent shrink-0" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                    </svg>
                    <span>{{ session('success') }}</span>
                </div>
            </div>
        @endif

        @if(session('error'))
            <div class="max-w-7xl mx-auto px-4 mt-4">
                <div class="p-4 rounded-xl bg-red-950/80 border border-red-500/40 text-red-300 text-sm flex items-center gap-3">
                    <svg class="w-5 h-5 text-red-400 shrink-0" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                    </svg>
                    <span>{{ session('error') }}</span>
                </div>
            </div>
        @endif

        @yield('content')
    </main>

    <!-- Slide-over Shopping Bag Drawer -->
    <div id="cartDrawer" class="fixed inset-0 z-50 overflow-hidden hidden" aria-labelledby="slide-over-title" role="dialog" aria-modal="true">
        <div class="absolute inset-0 bg-black/70 backdrop-blur-sm transition-opacity" onclick="toggleCartDrawer()"></div>
        <div class="pointer-events-none fixed inset-y-0 right-0 flex max-w-full pl-10">
            <div class="pointer-events-auto w-screen max-w-md bg-slateDark border-l border-hairline flex flex-col shadow-2xl">
                <!-- Drawer Header -->
                <div class="p-5 border-b border-hairline flex items-center justify-between">
                    <div class="flex items-center gap-2.5">
                        <svg class="w-5 h-5 text-emeraldAccent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
                        </svg>
                        <h2 class="text-base font-display font-bold text-white tracking-tight">Shopping Bag</h2>
                    </div>
                    <button onclick="toggleCartDrawer()" class="p-1 rounded-lg text-slate-400 hover:text-white hover:bg-cardDark">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>

                <!-- Bag Items List -->
                <div id="cartItemsContainer" class="flex-1 overflow-y-auto p-5 space-y-4 custom-scroll">
                    <!-- Populated dynamically via JS -->
                </div>

                <!-- Checkout Form & Totals -->
                <div class="p-5 bg-cardDark border-t border-hairline space-y-4">
                    <div class="flex items-center justify-between text-sm">
                        <span class="text-slate-400">Subtotal</span>
                        <span id="cartSubtotal" class="font-bold text-white font-display">Rs. 0.00</span>
                    </div>

                    <!-- Fast Online Checkout Form -->
                    <form id="checkoutForm" action="{{ route('store.checkout') }}" method="POST" class="space-y-3">
                        @csrf
                        <input type="hidden" name="cart_items" id="cartItemsInput" value="[]">

                        <div>
                            <label class="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">Your Full Name</label>
                            <input type="text" name="customer_name" required placeholder="e.g. Kasun Fernando"
                                class="w-full bg-slateDark border border-hairline rounded-lg px-3 py-2 text-xs text-white placeholder-slate-500 focus:border-emeraldAccent focus:outline-none">
                        </div>

                        <div>
                            <label class="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">Mobile Number (For SMS Bill)</label>
                            <input type="tel" name="customer_phone" required placeholder="e.g. 0771234567"
                                class="w-full bg-slateDark border border-hairline rounded-lg px-3 py-2 text-xs text-white placeholder-slate-500 focus:border-emeraldAccent focus:outline-none">
                            <span class="text-[10px] text-emerald-400/90 mt-0.5 block">🔒 SMS e-receipt link sent instantly upon order.</span>
                        </div>

                        <div>
                            <label class="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">Shipping Address</label>
                            <textarea name="shipping_address" rows="2" required placeholder="Delivery address, City..."
                                class="w-full bg-slateDark border border-hairline rounded-lg px-3 py-2 text-xs text-white placeholder-slate-500 focus:border-emeraldAccent focus:outline-none"></textarea>
                        </div>

                        <div>
                            <label class="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">Payment Method</label>
                            <select name="payment_method" class="w-full bg-slateDark border border-hairline rounded-lg px-3 py-2 text-xs text-white focus:border-emeraldAccent focus:outline-none">
                                <option value="cod">Cash on Delivery (COD)</option>
                                <option value="card">Credit / Debit Card (Online)</option>
                                <option value="bank_transfer">Direct Bank Transfer</option>
                            </select>
                        </div>

                        <button type="submit" id="checkoutBtn" disabled
                            class="w-full py-3 rounded-xl bg-emeraldAccent hover:bg-emerald-400 text-black font-display font-extrabold text-sm tracking-wide disabled:opacity-40 disabled:cursor-not-allowed shadow-lg shadow-emeraldAccent/20 transition-all">
                            Complete Order & Receive SMS Bill
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- Footer -->
    <footer class="bg-cardDark border-t border-hairline mt-16 py-8 px-4 sm:px-6 lg:px-8 text-xs text-slate-400">
        <div class="max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4">
            <div class="flex items-center gap-2">
                <span class="font-display font-bold text-white text-sm">SMARTSHOP RETAIL SYSTEM</span>
                <span>• Omnichannel POS + ERP + Web Storefront</span>
            </div>
            <div class="flex items-center gap-6">
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
                    <div class="text-center py-16 text-slate-500">
                        <svg class="w-12 h-12 mx-auto mb-3 opacity-30" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
                        </svg>
                        <p class="text-sm font-medium">Your shopping bag is empty.</p>
                        <p class="text-xs text-slate-600 mt-1">Add footwear, apparel, or electronics from the store catalog.</p>
                    </div>
                `;
                checkoutBtn.disabled = true;
            } else {
                checkoutBtn.disabled = false;
                container.innerHTML = cart.map(item => `
                    <div class="p-3 rounded-xl bg-slateDark border border-hairline flex items-center justify-between gap-3">
                        <div class="flex-1 min-w-0">
                            <div class="text-xs font-bold text-white truncate">${item.name}</div>
                            <div class="text-[11px] text-emerald-400 font-semibold mt-0.5">Rs. ${item.price.toLocaleString('en-US', { minimumFractionDigits: 2 })}</div>
                            ${item.warranty ? `<div class="text-[9px] text-goldLuxury font-medium mt-0.5">★ ${item.warranty}</div>` : ''}
                        </div>
                        <div class="flex items-center gap-2 bg-cardDark border border-hairline rounded-lg px-2 py-1">
                            <button type="button" onclick="updateCartQty(${item.product_id}, -1)" class="text-slate-400 hover:text-white font-bold text-xs px-1">-</button>
                            <span class="text-xs font-bold text-white w-4 text-center">${item.quantity}</span>
                            <button type="button" onclick="updateCartQty(${item.product_id}, 1)" class="text-slate-400 hover:text-white font-bold text-xs px-1">+</button>
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
    </script>
</body>
</html>
