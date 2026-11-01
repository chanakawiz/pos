import React, { useState } from 'react';
import { X, Search, Store, Phone, MapPin, CheckCircle, AlertTriangle, XCircle, RefreshCw } from 'lucide-react';
import { usePosStore } from '../stores/usePosStore';
import { api } from '../services/api';

interface StoreStockItem {
  store_id: number;
  store_code: string;
  store_name: string;
  address?: string;
  phone?: string;
  quantity_on_hand: number;
  quantity_reserved: number;
  quantity_available: number;
}

export const BranchStockModal: React.FC = () => {
  const { closeModal } = usePosStore();
  const [searchTerm, setSearchTerm] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [productInfo, setProductInfo] = useState<{ id: number; name: string; sku: string; barcode: string } | null>(null);
  const [storeStocks, setStoreStocks] = useState<StoreStockItem[]>([]);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const performLookup = async (query: string) => {
    if (!query.trim()) return;
    setIsLoading(true);
    setErrorMessage(null);

    try {
      const res = await api.getCrossStoreStock(query.trim());
      if (res.status === 'success') {
        setProductInfo(res.product);
        setStoreStocks(res.stores || []);
      } else {
        setErrorMessage(res.message || 'Product not found.');
      }
    } catch (e: any) {
      setErrorMessage(e?.response?.data?.message || 'Could not retrieve cross-branch stock.');
      setStoreStocks([]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    performLookup(searchTerm);
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-2xl max-h-[90vh] flex flex-col shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        
        {/* Header */}
        <div className="px-6 py-4 border-b border-slate-800 flex items-center justify-between bg-slate-900/60">
          <div className="flex items-center gap-2.5 text-indigo-400">
            <Store className="w-5 h-5" />
            <div>
              <h2 className="text-base font-bold text-white tracking-tight">Cross-Branch Inventory Inquiry</h2>
              <p className="text-xs text-slate-400">Check real-time stock availability across sibling store outlets</p>
            </div>
          </div>
          <button
            type="button"
            onClick={closeModal}
            className="p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Search Input Bar */}
        <div className="p-6 border-b border-slate-800 bg-slate-950/40">
          <form onSubmit={handleSearchSubmit} className="flex gap-2">
            <div className="relative flex-1">
              <input
                type="text"
                autoFocus
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Scan barcode or enter product SKU / Name..."
                className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 pl-10 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all font-mono"
              />
              <Search className="w-4 h-4 text-slate-500 absolute left-3.5 top-3" />
            </div>
            <button
              type="submit"
              disabled={isLoading || !searchTerm.trim()}
              className="px-5 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 text-white font-semibold text-xs tracking-wide shadow-md flex items-center gap-1.5 transition-all"
            >
              {isLoading ? <RefreshCw className="w-4 h-4 animate-spin" /> : <Search className="w-4 h-4" />}
              <span>Check Stock</span>
            </button>
          </form>

          {errorMessage && (
            <div className="mt-3 p-3 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-300 text-xs flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 shrink-0" />
              <span>{errorMessage}</span>
            </div>
          )}
        </div>

        {/* Product Meta Header (When Found) */}
        {productInfo && (
          <div className="px-6 py-3 bg-indigo-950/20 border-b border-indigo-500/20 flex items-center justify-between">
            <div>
              <div className="text-sm font-bold text-white">{productInfo.name}</div>
              <div className="text-xs text-slate-400 font-mono">
                SKU: <span className="text-indigo-300 font-bold">{productInfo.sku}</span> | Barcode: {productInfo.barcode || 'N/A'}
              </div>
            </div>
            <div className="text-xs font-semibold text-indigo-400 bg-indigo-500/10 px-2.5 py-1 rounded-full border border-indigo-500/30">
              {storeStocks.reduce((acc, s) => acc + s.quantity_available, 0)} Total Units in Network
            </div>
          </div>
        )}

        {/* Store Inventory List */}
        <div className="flex-1 overflow-y-auto p-6 space-y-3">
          {storeStocks.length === 0 && !isLoading && !errorMessage ? (
            <div className="text-center py-12 text-slate-500">
              <Store className="w-12 h-12 mx-auto mb-3 opacity-30" />
              <p className="text-sm font-medium text-slate-300">No product queried yet.</p>
              <p className="text-xs text-slate-500 mt-1">Scan a barcode or enter SKU above to verify sibling branch stock.</p>
            </div>
          ) : (
            storeStocks.map((store) => {
              const isAvailable = store.quantity_available > 0;
              const isLow = store.quantity_available > 0 && store.quantity_available < 5;

              return (
                <div
                  key={store.store_id}
                  className="p-4 rounded-xl bg-slate-950/60 border border-slate-800 flex flex-col sm:flex-row sm:items-center justify-between gap-3 hover:border-slate-700 transition-all"
                >
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-sm text-white">{store.store_name}</span>
                      <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-slate-800 text-slate-300 border border-slate-700">
                        {store.store_code}
                      </span>
                    </div>

                    <div className="text-xs text-slate-400 flex items-center gap-3 flex-wrap">
                      {store.address && (
                        <span className="flex items-center gap-1">
                          <MapPin className="w-3 h-3 text-slate-500" />
                          {store.address}
                        </span>
                      )}
                      {store.phone && (
                        <span className="flex items-center gap-1 text-slate-300 font-mono">
                          <Phone className="w-3 h-3 text-slate-500" />
                          {store.phone}
                        </span>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center gap-4 shrink-0 sm:justify-end">
                    <div className="text-right">
                      <div className="text-[10px] uppercase font-bold text-slate-500">Available</div>
                      <div className="text-base font-extrabold font-mono text-white">
                        {store.quantity_available.toFixed(1)}
                      </div>
                    </div>

                    <div className="flex items-center">
                      {isAvailable ? (
                        isLow ? (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold bg-amber-500/10 text-amber-400 border border-amber-500/30">
                            <AlertTriangle className="w-3 h-3" /> Low Stock
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/30">
                            <CheckCircle className="w-3 h-3" /> In Stock
                          </span>
                        )
                      ) : (
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold bg-rose-500/10 text-rose-400 border border-rose-500/30">
                          <XCircle className="w-3 h-3" /> Out of Stock
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>

        {/* Modal Footer */}
        <div className="px-6 py-3 border-t border-slate-800 bg-slate-900 flex justify-between items-center text-xs text-slate-400">
          <span>Press <strong>Esc</strong> to close</span>
          <button
            type="button"
            onClick={closeModal}
            className="px-4 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-white font-medium transition-colors"
          >
            Close
          </button>
        </div>

      </div>
    </div>
  );
};
