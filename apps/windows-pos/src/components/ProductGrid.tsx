import React, { useEffect, useRef } from 'react';
import { Search, Barcode, Plus, PackageCheck, AlertTriangle, ShieldCheck, Scale, X } from 'lucide-react';
import type { Product } from '../types/pos';
import { usePosStore } from '../stores/usePosStore';
import { useAuthStore } from '../stores/useAuthStore';
import { weightUnit } from '../../electron/quantity';
import { posSounds } from '../utils/audio';

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
  const language = usePosStore((state) => state.language);
  const currency = useAuthStore((state) => state.user?.store?.currency_symbol || '$');

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'f' && !usePosStore.getState().activeModal) {
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

  const handleCardClick = (product: Product) => {
    posSounds.playScannerBeep();
    onProductClick(product);
  };

  return (
    <div className="flex-1 flex flex-col min-w-0 bg-slate-950/40 p-5 overflow-hidden">
      {/* Search and Barcode Input Bar */}
      <div className="flex items-center gap-3 mb-4 shrink-0">
        <div className="relative flex-1">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
          <input
            ref={searchInputRef}
            type="text"
            placeholder="Search products by name, SKU, or scan barcode (Ctrl + F)..."
            value={searchTerm}
            onChange={(e) => onSearchChange(e.target.value)}
            onKeyDown={handleKeyDown}
            className="w-full bg-slate-900/90 border border-slate-700/80 rounded-2xl pl-11 pr-32 py-3 text-sm text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all shadow-inner"
          />
          {searchTerm && (
            <button
              type="button"
              onClick={() => {
                onSearchChange('');
                searchInputRef.current?.focus();
              }}
              className="absolute right-28 top-1/2 -translate-y-1/2 p-1 text-slate-400 hover:text-white rounded-lg cursor-pointer"
            >
              <X className="w-4 h-4" />
            </button>
          )}
          <button
            type="button"
            onClick={() => {
              searchInputRef.current?.focus();
              searchInputRef.current?.select();
            }}
            className="absolute right-3 top-1/2 -translate-y-1/2 flex items-center gap-1.5 bg-slate-800 hover:bg-slate-700 text-indigo-300 text-xs px-2.5 py-1.5 rounded-xl border border-slate-700 font-mono transition-colors cursor-pointer"
          >
            <Barcode className="w-3.5 h-3.5 text-indigo-400" />
            <span>Barcode</span>
          </button>
        </div>
      </div>

      {/* Grid */}
      <div className="flex-1 overflow-y-auto pr-1">
        {isLoading ? (
          <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 gap-3.5">
            {Array.from({ length: 8 }).map((_, i) => (
              <div key={i} className="h-44 bg-slate-900/60 rounded-2xl border border-slate-800/80 animate-pulse" />
            ))}
          </div>
        ) : products.length === 0 ? (
          <div className="h-full flex flex-col items-center justify-center text-center p-8">
            <div className="w-16 h-16 rounded-full bg-slate-900 flex items-center justify-center text-slate-500 mb-4 border border-slate-800 shadow-inner">
              <Search className="w-8 h-8" />
            </div>
            <h3 className="text-base font-bold text-slate-300">No products found</h3>
            <p className="text-xs text-slate-500 max-w-sm mt-1">
              Try searching with another name, barcode, SKU or select another category pill.
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 gap-3.5">
            {products.map((product) => {
              const isLowStock = product.stock_quantity > 0 && product.stock_quantity <= product.min_stock_level;
              const isOutOfStock = product.stock_quantity <= 0;
              const isWeighed = !!weightUnit(product.unit);

              return (
                <div
                  key={product.id}
                  data-product-id={product.id}
                  onClick={() => handleCardClick(product)}
                  className="product-card group relative bg-slate-900/85 hover:bg-slate-850 border border-slate-800/90 hover:border-indigo-500/60 rounded-2xl p-4 flex flex-col justify-between cursor-pointer transition-all duration-150 hover:shadow-xl hover:shadow-indigo-950/40 active:scale-[0.98] select-none"
                >
                  <div>
                    {/* Stock badge & Category */}
                    <div className="flex items-center justify-between gap-2 mb-2">
                      <span className="text-[10px] font-bold text-indigo-300 bg-indigo-950/70 px-2 py-0.5 rounded-md border border-indigo-900/60 truncate max-w-[110px]">
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

                    {/* Product Name (with Multi-language support) */}
                    {language === 'si' ? (
                      <>
                        <h4 className="font-bold text-slate-100 text-sm line-clamp-2 leading-snug group-hover:text-indigo-200 transition-colors">
                          {product.sinhala_name || product.name}
                        </h4>
                        {product.sinhala_name && (
                          <div className="text-[11px] text-slate-400 font-medium truncate mt-0.5">
                            {product.name}
                          </div>
                        )}
                      </>
                    ) : language === 'en' ? (
                      <h4 className="font-bold text-slate-100 text-sm line-clamp-2 leading-snug group-hover:text-indigo-200 transition-colors">
                        {product.name}
                      </h4>
                    ) : (
                      <>
                        <h4 className="font-bold text-slate-100 text-sm line-clamp-2 leading-snug group-hover:text-indigo-200 transition-colors">
                          {product.name}
                        </h4>
                        {product.sinhala_name && (
                          <div className="text-[11px] text-amber-300 font-medium truncate mt-0.5">
                            {product.sinhala_name}
                          </div>
                        )}
                      </>
                    )}

                    {/* Warranty badge */}
                    {product.warranty_period && (
                      <div className="flex items-center gap-1 text-[10px] text-cyan-400 bg-cyan-950/60 px-1.5 py-0.5 rounded-md border border-cyan-800/40 mt-1.5 w-fit">
                        <ShieldCheck className="w-3 h-3 text-cyan-400" />
                        <span className="truncate max-w-[130px]">{product.warranty_period}</span>
                      </div>
                    )}

                    <div className="text-[10px] text-slate-500 font-mono mt-1">
                      SKU: {product.sku}
                    </div>
                  </div>

                  {/* Price and Add Button */}
                  <div className="flex items-center justify-between pt-3 mt-3 border-t border-slate-800/80">
                    <div>
                      <div className="text-base font-extrabold text-white font-mono leading-none">
                        {currency} {Number(product.selling_price).toFixed(2)}
                        {isWeighed && <span className="text-[11px] text-slate-400 font-sans font-normal ml-0.5">/{product.unit}</span>}
                      </div>
                      {product.tax_rate > 0 && (
                        <span className="text-[10px] text-slate-400">+{product.tax_rate}% Tax</span>
                      )}
                    </div>

                    <button
                      type="button"
                      title={isWeighed ? 'Weigh and Add' : 'Add to Cart'}
                      className="w-8 h-8 rounded-xl bg-indigo-600 group-hover:bg-indigo-500 text-white flex items-center justify-center shadow-md shadow-indigo-600/30 transition-all active:scale-90 cursor-pointer"
                    >
                      {isWeighed ? <Scale className="w-4 h-4" /> : <Plus className="w-4 h-4" />}
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

