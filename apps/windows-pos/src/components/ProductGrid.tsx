import React, { useRef, useEffect } from 'react';
import type { Product } from '../types/pos';
import { Search, Barcode, Plus, PackageCheck, AlertTriangle } from 'lucide-react';

interface Props {
  products: Product[];
  isLoading: boolean;
  searchTerm: string;
  onSearchChange: (term: string) => void;
  onBarcodeSubmit: (barcode: string) => void;
  onProductClick: (product: Product) => void;
}

export const ProductGrid: React.FC<Props> = ({
  products,
  isLoading,
  searchTerm,
  onSearchChange,
  onBarcodeSubmit,
  onProductClick,
}) => {
  const searchInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'F1' || e.key === 'F2') {
        e.preventDefault();
        searchInputRef.current?.focus();
        searchInputRef.current?.select();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' && searchTerm.trim().length > 0) {
      e.preventDefault();
      onBarcodeSubmit(searchTerm.trim());
    }
  };

  return (
    <div className="flex-1 flex flex-col min-w-0 bg-slate-950/40 p-6 overflow-hidden">
      {/* Search and Barcode Input bar */}
      <div className="flex items-center gap-3 mb-6">
        <div className="relative flex-1">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
          <input
            ref={searchInputRef}
            type="text"
            placeholder="Search by name, SKU, or scan barcode (Press F1 / F2 to focus)..."
            value={searchTerm}
            onChange={(e) => onSearchChange(e.target.value)}
            onKeyDown={handleKeyDown}
            autoFocus
            className="w-full bg-slate-900 border border-slate-700/80 rounded-2xl pl-12 pr-28 py-3.5 text-sm text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all shadow-inner"
          />
          <div className="absolute right-3 top-1/2 -translate-y-1/2 flex items-center gap-1 bg-slate-800 text-slate-400 text-xs px-2.5 py-1 rounded-lg border border-slate-700 font-mono pointer-events-none">
            <Barcode className="w-4 h-4 text-indigo-400" />
            <span>Barcode</span>
          </div>
        </div>
      </div>

      {/* Grid */}
      <div className="flex-1 overflow-y-auto pr-1">
        {isLoading ? (
          <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4">
            {Array.from({ length: 8 }).map((_, i) => (
              <div key={i} className="h-44 bg-slate-900/60 rounded-2xl border border-slate-800/80 animate-pulse" />
            ))}
          </div>
        ) : products.length === 0 ? (
          <div className="h-full flex flex-col items-center justify-center text-center p-8">
            <div className="w-16 h-16 rounded-full bg-slate-900 flex items-center justify-center text-slate-500 mb-4 border border-slate-800">
              <Search className="w-8 h-8" />
            </div>
            <h3 className="text-lg font-semibold text-slate-300">No products found</h3>
            <p className="text-sm text-slate-500 max-w-sm mt-1">
              Try searching with another keyword or barcode, or select a different category.
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4">
            {products.map((product) => {
              const isLowStock = product.stock_quantity > 0 && product.stock_quantity <= product.min_stock_level;
              const isOutOfStock = product.stock_quantity <= 0;

              return (
                <div
                  key={product.id}
                  onClick={() => onProductClick(product)}
                  className="group relative bg-slate-900/80 hover:bg-slate-800/90 border border-slate-800 hover:border-indigo-500/50 rounded-2xl p-4 flex flex-col justify-between cursor-pointer transition-all duration-150 hover:shadow-xl hover:shadow-indigo-950/40 active:scale-[0.98] select-none"
                >
                  <div>
                    {/* Stock badge & Category */}
                    <div className="flex items-center justify-between gap-2 mb-2">
                      <span className="text-[11px] font-medium text-indigo-400 bg-indigo-950/60 px-2 py-0.5 rounded-md border border-indigo-900/50 truncate max-w-[120px]">
                        {product.category?.name || 'General'}
                      </span>

                      {isOutOfStock ? (
                        <span className="flex items-center gap-1 text-[10px] font-bold text-rose-400 bg-rose-950/60 px-2 py-0.5 rounded-md border border-rose-900/50">
                          <AlertTriangle className="w-3 h-3" />
                          Out of stock
                        </span>
                      ) : isLowStock ? (
                        <span className="flex items-center gap-1 text-[10px] font-bold text-amber-400 bg-amber-950/60 px-2 py-0.5 rounded-md border border-amber-900/50">
                          Low: {product.stock_quantity}
                        </span>
                      ) : (
                        <span className="flex items-center gap-1 text-[10px] font-medium text-emerald-400 bg-emerald-950/60 px-2 py-0.5 rounded-md border border-emerald-900/50">
                          <PackageCheck className="w-3 h-3" />
                          {product.stock_quantity} {product.unit}
                        </span>
                      )}
                    </div>

                    {/* Title */}
                    <h4 className="font-semibold text-slate-100 text-sm line-clamp-2 leading-snug group-hover:text-indigo-200 transition-colors">
                      {product.name}
                    </h4>
                    <div className="text-[11px] text-slate-500 font-mono mt-1">
                      SKU: {product.sku}
                    </div>
                  </div>

                  {/* Price and Add button */}
                  <div className="flex items-center justify-between pt-3 mt-3 border-t border-slate-800/80">
                    <div>
                      <div className="text-base font-bold text-white font-mono">
                        ${Number(product.selling_price).toFixed(2)}
                      </div>
                      {product.tax_rate > 0 && (
                        <span className="text-[10px] text-slate-400">+{product.tax_rate}% Tax</span>
                      )}
                    </div>

                    <button
                      title="Add to Cart"
                      className="w-9 h-9 rounded-xl bg-indigo-600 group-hover:bg-indigo-500 text-white flex items-center justify-center shadow-md shadow-indigo-600/30 transition-transform active:scale-90"
                    >
                      <Plus className="w-5 h-5" />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
};
