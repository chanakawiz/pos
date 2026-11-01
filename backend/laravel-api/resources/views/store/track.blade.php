@extends('store.layout')

@section('title', 'Track Order & Returns — OmniLuxe Store')

@section('content')
<div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-10">

    <!-- Header & Search Box -->
    <div class="text-center max-w-2xl mx-auto mb-10">
        <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-cream border border-goldLuxury/30 text-[11px] font-bold text-forest tracking-wider uppercase mb-3">
            <span class="w-2 h-2 rounded-full bg-goldLuxury animate-ping"></span>
            Real-Time Omnichannel Telemetry
        </div>
        <h1 class="font-display font-extrabold text-3xl sm:text-4xl text-forest tracking-tight">
            Track Order & Returns Portal
        </h1>
        <p class="text-sage text-sm mt-2">
            Monitor real-time dispatch progress, courier tracking, and initiate self-service returns or exchanges.
        </p>

        <!-- Search Form -->
        <form action="{{ route('store.track') }}" method="GET" class="mt-6 flex flex-col sm:flex-row gap-2 max-w-lg mx-auto">
            <div class="relative flex-1">
                <input type="text" name="query" value="{{ $query ?? request('query') }}" required 
                    placeholder="Enter Invoice (e.g. INV-...) or Tracking #"
                    class="w-full bg-paper border border-hairline rounded-xl px-4 py-3 pl-10 text-sm text-ink placeholder-sage focus:outline-none focus:border-forest focus:ring-1 focus:ring-forest shadow-sm">
                <svg class="w-5 h-5 text-sage absolute left-3.5 top-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
            </div>
            <button type="submit" class="px-6 py-3 rounded-xl bg-forest hover:bg-forestDark text-white font-display font-bold text-sm tracking-wide shadow-md transition-all">
                Track Order
            </button>
        </form>
    </div>

    @if($error)
        <div class="max-w-2xl mx-auto mb-8 p-4 rounded-2xl bg-amber-50 border border-amber-200 text-amber-900 text-sm flex items-start gap-3 shadow-sm">
            <svg class="w-5 h-5 text-amber-600 shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
            </svg>
            <div>
                <span class="font-bold">Order Search Alert:</span> {{ $error }}
                <div class="mt-1 text-xs text-amber-700">
                    Tip: Enter your exact invoice number from your SMS bill (e.g. <code class="bg-amber-100 px-1 py-0.5 rounded font-mono">{{ $sale->invoice_number ?? 'INV-...' }}</code>) or log into your <a href="{{ route('store.account') }}" class="underline font-bold">VIP Account</a> to view all your past orders.
                </div>
            </div>
        </div>
    @endif

    @if($sale)
        <!-- Order Telemetry Card -->
        <div class="luxury-card rounded-2xl p-6 sm:p-8 mb-8 shadow-sm">
            <!-- Order Meta Header -->
            <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 pb-6 border-b border-hairline">
                <div>
                    <div class="flex items-center gap-3 flex-wrap">
                        <span class="font-display font-extrabold text-2xl text-forest tracking-tight">{{ $sale->invoice_number }}</span>
                        
                        <!-- Fulfillment Badge -->
                        @php
                            $fulfillment = $sale->fulfillment_status ?? 'unfulfilled';
                            $badgeClass = match($fulfillment) {
                                'delivered' => 'bg-emerald-100 text-emerald-800 border-emerald-300',
                                'dispatched' => 'bg-blue-100 text-blue-800 border-blue-300',
                                'packed' => 'bg-purple-100 text-purple-800 border-purple-300',
                                'processing' => 'bg-amber-100 text-amber-800 border-amber-300',
                                'returned' => 'bg-rose-100 text-rose-800 border-rose-300',
                                default => 'bg-stone-100 text-stone-700 border-stone-300',
                            };
                        @endphp
                        <span class="px-3 py-1 rounded-full text-xs font-bold border uppercase tracking-wider {{ $badgeClass }}">
                            {{ ucfirst($fulfillment) }}
                        </span>

                        <!-- Payment Badge -->
                        @php
                            $isPaid = in_array($sale->payment_status, ['paid', 'partial']);
                        @endphp
                        <span class="px-3 py-1 rounded-full text-xs font-bold border uppercase tracking-wider {{ $isPaid ? 'bg-emerald-50 text-emerald-700 border-emerald-200' : 'bg-amber-50 text-amber-700 border-amber-200' }}">
                            Payment: {{ ucfirst($sale->payment_status) }}
                        </span>
                    </div>

                    <div class="text-xs text-sage mt-2 flex items-center gap-3 flex-wrap">
                        <span>Ordered: <strong>{{ $sale->created_at->format('M d, Y h:i A') }}</strong></span>
                        <span>•</span>
                        <span>Outlet: <strong>{{ $sale->store?->name ?? 'OmniLuxe Flagship' }}</strong></span>
                        @if($sale->customer)
                            <span>•</span>
                            <span>Recipient: <strong>{{ $sale->customer->name }}</strong></span>
                        @endif
                    </div>
                </div>

                <div class="flex items-center gap-2">
                    <a href="{{ route('store.receipt', $sale->uuid) }}" target="_blank" 
                        class="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-cream border border-hairline text-xs font-bold text-forest hover:border-forest/50 transition-colors shadow-sm">
                        <svg class="w-4 h-4 text-forest" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                        </svg>
                        Digital E-Receipt
                    </a>
                </div>
            </div>

            <!-- Courier Dispatch Banner (If Assigned) -->
            @if($sale->courier_name || $sale->tracking_number)
                <div class="mt-6 p-4 rounded-xl bg-forestLight/60 border border-forest/20 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <div class="flex items-center gap-3">
                        <div class="w-10 h-10 rounded-xl bg-forest text-white flex items-center justify-center shrink-0">
                            <svg class="w-5 h-5 text-goldLuxury" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16V6a1 1 0 00-1-1H4a1 1 0 00-1 1v10a1 1 0 001 1h1m8-1a1 1 0 01-1 1H9m4-1V8a1 1 0 011-1h2.586a1 1 0 01.707.293l3.414 3.414a1 1 0 01.293.707V16a1 1 0 01-1 1h-1m-6-1a1 1 0 001 1h1M5 17a2 2 0 104 0m-4 0a2 2 0 114 0m6 0a2 2 0 104 0m-4 0a2 2 0 114 0" />
                            </svg>
                        </div>
                        <div>
                            <div class="text-xs font-semibold text-sage uppercase tracking-wider">Priority Dispatch Courier</div>
                            <div class="text-sm font-extrabold text-forest">
                                {{ $sale->courier_name ?? 'OmniLuxe Priority Dispatch' }}
                            </div>
                            <div class="text-xs text-ink/80 font-mono mt-0.5">
                                Tracking Code: <span class="font-bold select-all">{{ $sale->tracking_number ?? 'In Local Sorting' }}</span>
                            </div>
                        </div>
                    </div>
                    @if($sale->estimated_delivery_at)
                        <div class="text-left sm:text-right">
                            <div class="text-[11px] font-semibold text-sage uppercase">Est. Delivery Date</div>
                            <div class="text-sm font-bold text-forest">{{ $sale->estimated_delivery_at->format('M d, Y') }}</div>
                        </div>
                    @endif
                </div>
            @endif

            <!-- Visual Telemetry Timeline -->
            <div class="mt-10">
                <div class="text-xs font-bold text-forest uppercase tracking-wider mb-6 flex items-center gap-2">
                    <span class="w-2 h-2 rounded-full bg-forest"></span>
                    Order Progression Telemetry
                </div>

                <div class="relative">
                    <!-- Desktop Stepper Line -->
                    <div class="hidden md:block absolute top-1/2 left-6 right-6 -translate-y-6 h-0.5 bg-hairline z-0"></div>

                    <div class="grid grid-cols-1 md:grid-cols-5 gap-6 relative z-10">
                        @foreach($timeline as $step)
                            <div class="flex md:flex-col items-start md:items-center text-left md:text-center gap-4 md:gap-2">
                                <!-- Step Circle -->
                                <div class="w-10 h-10 rounded-full flex items-center justify-center shrink-0 border-2 transition-all
                                    {{ $step['completed'] ? 'bg-forest border-forest text-goldLuxury shadow-sm' : ($step['active'] ? 'bg-goldLight border-goldLuxury text-forest ring-4 ring-goldLuxury/20 animate-pulse' : 'bg-cream border-hairline text-sage') }}">
                                    @if($step['completed'])
                                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7" />
                                        </svg>
                                    @else
                                        <span class="text-xs font-bold">{{ $step['step'] }}</span>
                                    @endif
                                </div>

                                <div class="flex-1">
                                    <div class="text-xs font-bold {{ $step['completed'] || $step['active'] ? 'text-forest' : 'text-sage' }}">
                                        {{ $step['title'] }}
                                    </div>
                                    <div class="text-[11px] text-sage mt-0.5 leading-tight">
                                        {{ $step['description'] }}
                                    </div>
                                    @if($step['time'])
                                        <div class="text-[10px] font-semibold text-forest/80 mt-1">
                                            {{ $step['time'] }}
                                        </div>
                                    @endif
                                </div>
                            </div>
                        @endforeach
                    </div>
                </div>
            </div>

            <!-- Ordered Items List -->
            <div class="mt-12 pt-8 border-t border-hairline">
                <div class="flex items-center justify-between mb-4">
                    <h3 class="font-display font-bold text-lg text-forest">Order Contents ({{ $sale->items->count() }} {{ Str::plural('item', $sale->items->count()) }})</h3>
                    <span class="text-xs font-bold text-sage">Total: <span class="font-display text-forest text-base">Rs. {{ number_format($sale->total_amount, 2) }}</span></span>
                </div>

                <div class="space-y-3">
                    @foreach($sale->items as $item)
                        <div class="p-4 rounded-xl bg-canvas border border-hairline flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                            <div class="flex items-center gap-3">
                                <div class="w-10 h-10 rounded-lg bg-cream border border-hairline flex items-center justify-center font-display font-bold text-forest text-sm shrink-0">
                                    {{ $loop->iteration }}
                                </div>
                                <div>
                                    <div class="font-bold text-sm text-ink">{{ $item->product?->name ?? 'Product Item' }}</div>
                                    <div class="text-xs text-sage mt-0.5">
                                        Qty: <strong>{{ (float) $item->quantity }}</strong>
                                        @if($item->serial_number)
                                            <span class="ml-2 font-mono text-[11px] bg-paper px-1.5 py-0.5 rounded border border-hairline">S/N: {{ $item->serial_number }}</span>
                                        @endif
                                        @if($item->warranty_notes)
                                            <span class="ml-2 text-forest font-medium">🛡️ {{ $item->warranty_notes }}</span>
                                        @endif
                                    </div>
                                </div>
                            </div>
                            <div class="text-left sm:text-right">
                                <div class="text-xs text-sage">Rs. {{ number_format($item->unit_price, 2) }} each</div>
                                <div class="text-sm font-bold text-forest font-display">Rs. {{ number_format($item->total, 2) }}</div>
                            </div>
                        </div>
                    @endforeach
                </div>
            </div>

            <!-- Existing Return Requests (If Any) -->
            @if($sale->returnRequests->isNotEmpty())
                <div class="mt-10 pt-8 border-t border-hairline">
                    <h3 class="font-display font-bold text-lg text-forest mb-4">Your Return & Exchange Requests</h3>
                    <div class="space-y-3">
                        @foreach($sale->returnRequests as $returnReq)
                            <div class="p-4 rounded-xl bg-goldLight/40 border border-goldLuxury/30 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                                <div>
                                    <div class="flex items-center gap-2">
                                        <span class="font-mono text-xs font-bold text-forest bg-paper px-2 py-0.5 rounded border border-hairline">{{ $returnReq->request_number }}</span>
                                        <span class="text-xs px-2 py-0.5 rounded-full font-bold uppercase {{ $returnReq->type === 'exchange' ? 'bg-purple-100 text-purple-800' : 'bg-emerald-100 text-emerald-800' }}">
                                            {{ ucfirst($returnReq->type) }}
                                        </span>
                                        <span class="text-xs font-semibold px-2 py-0.5 rounded-full bg-cream border border-hairline text-ink">
                                            Status: {{ ucfirst($returnReq->status) }}
                                        </span>
                                    </div>
                                    <div class="text-xs text-sage mt-1">
                                        Reason: <span class="text-ink font-medium">{{ $returnReq->reason }}</span>
                                    </div>
                                    @if($returnReq->staff_notes)
                                        <div class="text-xs text-forest mt-1 bg-forestLight/60 p-2 rounded-lg">
                                            <strong>Concierge Note:</strong> {{ $returnReq->staff_notes }}
                                        </div>
                                    @endif
                                </div>
                                <div class="text-xs text-sage font-medium">
                                    Submitted: {{ $returnReq->created_at->format('M d, Y') }}
                                </div>
                            </div>
                        @endforeach
                    </div>
                </div>
            @endif

            <!-- Self-Service Return or Exchange Submission Panel -->
            <div class="mt-12 pt-8 border-t border-hairline" id="returns-section">
                <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
                    <div>
                        <h3 class="font-display font-bold text-xl text-forest">Self-Service Returns & Exchanges</h3>
                        <p class="text-xs text-sage mt-1">Eligible orders can request an exchange or full refund within our satisfaction window.</p>
                    </div>
                    <button type="button" onclick="document.getElementById('returnFormContainer').classList.toggle('hidden')" 
                        class="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-forest hover:bg-forestDark text-white text-xs font-bold font-display shadow transition-all">
                        <svg class="w-4 h-4 text-goldLuxury" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                        </svg>
                        Initiate Return or Exchange
                    </button>
                </div>

                <!-- Return Form (Collapsible) -->
                <div id="returnFormContainer" class="{{ session('error') ? '' : 'hidden' }} p-6 rounded-2xl bg-cream border border-hairline">
                    <form action="{{ route('store.track.return', $sale->invoice_number) }}" method="POST" class="space-y-6">
                        @csrf

                        <!-- Return Type Selection -->
                        <div>
                            <label class="block text-xs font-bold text-forest uppercase tracking-wider mb-2">Request Type</label>
                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                <label class="p-4 rounded-xl bg-paper border border-hairline flex items-start gap-3 cursor-pointer hover:border-forest transition-colors">
                                    <input type="radio" name="type" value="exchange" checked class="mt-1 text-forest focus:ring-forest">
                                    <div>
                                        <div class="font-bold text-sm text-forest">Exchange Item</div>
                                        <div class="text-xs text-sage mt-0.5">Swap for another size, color, or alternate variant of equal value.</div>
                                    </div>
                                </label>
                                <label class="p-4 rounded-xl bg-paper border border-hairline flex items-start gap-3 cursor-pointer hover:border-forest transition-colors">
                                    <input type="radio" name="type" value="refund" class="mt-1 text-forest focus:ring-forest">
                                    <div>
                                        <div class="font-bold text-sm text-forest">Full / Partial Refund</div>
                                        <div class="text-xs text-sage mt-0.5">Return items back to our store and receive store credit or bank refund.</div>
                                    </div>
                                </label>
                            </div>
                        </div>

                        <!-- Select Items to Return -->
                        <div>
                            <label class="block text-xs font-bold text-forest uppercase tracking-wider mb-2">Select Item(s) to Return</label>
                            <div class="space-y-3">
                                @foreach($sale->items as $idx => $item)
                                    <div class="p-4 rounded-xl bg-paper border border-hairline flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                                        <div class="flex items-center gap-3">
                                            <input type="checkbox" name="items[{{ $idx }}][selected]" value="1" id="item_check_{{ $item->id }}" 
                                                class="rounded border-hairline text-forest focus:ring-forest w-4 h-4">
                                            <input type="hidden" name="items[{{ $idx }}][sale_item_id]" value="{{ $item->id }}">
                                            <div>
                                                <label for="item_check_{{ $item->id }}" class="font-bold text-xs text-ink cursor-pointer">
                                                    {{ $item->product?->name ?? 'Product Item' }}
                                                </label>
                                                <div class="text-[11px] text-sage">Unit Price: Rs. {{ number_format($item->unit_price, 2) }} | Max Qty: {{ (float) $item->quantity }}</div>
                                            </div>
                                        </div>

                                        <div class="flex items-center gap-3 flex-wrap">
                                            <div>
                                                <label class="block text-[10px] uppercase font-bold text-sage">Qty to Return</label>
                                                <input type="number" name="items[{{ $idx }}][quantity]" value="1" min="1" max="{{ (int) $item->quantity }}" 
                                                    class="w-20 bg-canvas border border-hairline rounded-lg px-2 py-1 text-xs text-center font-bold text-ink focus:border-forest">
                                            </div>

                                            <div>
                                                <label class="block text-[10px] uppercase font-bold text-sage">Condition</label>
                                                <select name="items[{{ $idx }}][item_condition]" class="bg-canvas border border-hairline rounded-lg px-2 py-1 text-xs text-ink focus:border-forest">
                                                    <option value="unopened">Unopened (Brand New)</option>
                                                    <option value="opened_unused">Opened - Unused</option>
                                                    <option value="defective">Defective / Faulty</option>
                                                    <option value="damaged">Damaged in Transit</option>
                                                </select>
                                            </div>

                                            <div>
                                                <label class="block text-[10px] uppercase font-bold text-sage">Exchange Size / Notes</label>
                                                <input type="text" name="items[{{ $idx }}][replacement_notes]" placeholder="e.g. Need Size UK 9" 
                                                    class="w-36 bg-canvas border border-hairline rounded-lg px-2 py-1 text-xs text-ink focus:border-forest">
                                            </div>
                                        </div>
                                    </div>
                                @endforeach
                            </div>
                        </div>

                        <!-- Reason -->
                        <div>
                            <label class="block text-xs font-bold text-forest uppercase tracking-wider mb-2">Reason for Request</label>
                            <select name="reason" required class="w-full bg-paper border border-hairline rounded-xl px-4 py-2.5 text-xs text-ink focus:border-forest">
                                <option value="Wrong size or fit">Wrong size or fit</option>
                                <option value="Defective or damaged product">Defective or damaged product</option>
                                <option value="Item does not match photo / description">Item does not match photo / description</option>
                                <option value="Received incorrect item">Received incorrect item</option>
                                <option value="Changed mind / Not satisfied">Changed mind / Not satisfied</option>
                                <option value="Other">Other</option>
                            </select>
                        </div>

                        <!-- Customer Notes -->
                        <div>
                            <label class="block text-xs font-bold text-forest uppercase tracking-wider mb-2">Additional Instructions</label>
                            <textarea name="customer_notes" rows="3" placeholder="Provide any details to help our concierge assist you smoothly..."
                                class="w-full bg-paper border border-hairline rounded-xl px-4 py-2.5 text-xs text-ink focus:border-forest"></textarea>
                        </div>

                        <div class="flex items-center justify-end gap-3 pt-4 border-t border-hairline">
                            <button type="button" onclick="document.getElementById('returnFormContainer').classList.add('hidden')"
                                class="px-5 py-2.5 rounded-xl bg-canvas border border-hairline text-xs font-bold text-sage hover:text-ink transition-colors">
                                Cancel
                            </button>
                            <button type="submit" 
                                class="px-6 py-2.5 rounded-xl bg-forest hover:bg-forestDark text-white font-display font-bold text-xs tracking-wide shadow-md transition-all">
                                Submit Return Request
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    @endif

</div>
@endsection
