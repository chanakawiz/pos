<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Connection Standby • OmniLuxe Store</title>
    <link rel="manifest" href="/manifest.json">
    <meta name="theme-color" content="#233C32">
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700&family=Playfair+Display:ital,wght@0,400;0,600;0,700;1,400&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Outfit', sans-serif;
            background-color: #FBFBF9;
            color: #242B27;
        }
        .font-serif {
            font-family: 'Playfair Display', serif;
        }
    </style>
</head>
<body class="min-h-screen flex items-center justify-center p-6 selection:bg-[#233C32] selection:text-white">
    <div class="max-w-lg w-full text-center space-y-8 bg-[#F4F2EB] p-8 md:p-12 rounded-2xl border border-[#E3E5DF] shadow-sm">
        <!-- Luxury Monogram Emblem -->
        <div class="inline-flex items-center justify-center w-20 h-20 rounded-full bg-[#233C32] text-[#C29B38] border-2 border-[#C29B38] shadow-md mx-auto">
            <svg class="w-10 h-10 animate-pulse" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
            </svg>
        </div>

        <div class="space-y-3">
            <span class="inline-block px-3 py-1 bg-[#233C32]/10 text-[#233C32] text-xs font-semibold tracking-widest uppercase rounded-full">
                Offline Mode • Session Preserved
            </span>
            <h1 class="font-serif text-3xl md:text-4xl font-semibold tracking-tight text-[#242B27]">
                Boutique Connection Paused
            </h1>
            <p class="text-sm md:text-base text-gray-600 leading-relaxed">
                You appear to be temporarily disconnected from the internet. Your shopping cart and preferences remain safe on your device.
            </p>
        </div>

        <div class="pt-2 flex flex-col sm:flex-row gap-3 justify-center">
            <button onclick="window.location.reload()" class="px-8 py-3.5 bg-[#233C32] text-white rounded-xl text-sm font-medium tracking-wide hover:bg-[#1a2d26] transition-all duration-200 shadow-sm flex items-center justify-center gap-2">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
                </svg>
                Retry Connection
            </button>
            <a href="/" class="px-6 py-3.5 bg-white text-[#242B27] border border-[#E3E5DF] rounded-xl text-sm font-medium hover:bg-gray-50 transition-colors">
                Return to Lookbook
            </a>
        </div>

        <div class="pt-6 border-t border-[#E3E5DF] text-xs text-gray-500 space-y-2">
            <p class="font-medium text-gray-700">OmniLuxe VIP Concierge Hotline: <a href="tel:+94112345678" class="text-[#233C32] font-semibold underline">+94 11 234 5678</a></p>
            <p>Physical Boutiques: Colombo Flagship • Kandy Galleria • Galle Fort Boutique</p>
        </div>
    </div>
</body>
</html>
