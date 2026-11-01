<div class="space-y-4">
    <div class="overflow-hidden rounded-xl border border-gray-200 dark:border-gray-700">
        <table class="w-full text-left text-sm divide-y divide-gray-200 dark:divide-gray-700">
            <thead class="bg-gray-50 dark:bg-gray-800 text-xs uppercase tracking-wider text-gray-500 font-semibold">
                <tr>
                    <th scope="col" class="px-4 py-3">Boutique Branch</th>
                    <th scope="col" class="px-4 py-3 text-right">On Hand</th>
                    <th scope="col" class="px-4 py-3 text-right">Reserved</th>
                    <th scope="col" class="px-4 py-3 text-right">Available</th>
                    <th scope="col" class="px-4 py-3 text-center">Status</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-200 dark:divide-gray-700 bg-white dark:bg-gray-900">
                @forelse($stocks as $stock)
                    <tr class="hover:bg-gray-50/50 dark:hover:bg-gray-800/50">
                        <td class="px-4 py-3">
                            <div class="font-bold text-gray-900 dark:text-white">{{ $stock['store_name'] }}</div>
                            <div class="text-xs text-gray-500">{{ $stock['store_code'] }} • {{ $stock['address'] }}</div>
                        </td>
                        <td class="px-4 py-3 text-right font-mono font-medium text-gray-700 dark:text-gray-300">
                            {{ number_format($stock['quantity_on_hand'], 2) }}
                        </td>
                        <td class="px-4 py-3 text-right font-mono text-gray-500">
                            {{ number_format($stock['quantity_reserved'], 2) }}
                        </td>
                        <td class="px-4 py-3 text-right font-mono font-bold text-gray-900 dark:text-white">
                            {{ number_format($stock['quantity_available'], 2) }}
                        </td>
                        <td class="px-4 py-3 text-center">
                            @if($stock['quantity_available'] > 5)
                                <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400">
                                    In Stock
                                </span>
                            @elseif($stock['quantity_available'] > 0)
                                <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-amber-50 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400">
                                    Low Stock
                                </span>
                            @else
                                <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-red-50 text-red-700 dark:bg-red-900/30 dark:text-red-400">
                                    Out of Stock
                                </span>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="5" class="px-4 py-6 text-center text-gray-500">
                            No store inventory records available.
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="flex items-center justify-between text-xs text-gray-500 pt-1">
        <span>Real-time cross-store stock inventory inquiry</span>
        <a href="/admin/stock-transfers/create" class="text-primary-600 hover:underline font-semibold flex items-center gap-1">
            Initiate Stock Transfer &rarr;
        </a>
    </div>
</div>
