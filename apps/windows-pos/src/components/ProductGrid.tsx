import { useEffect, useRef, useState } from 'react';
import { ArrowUpRight, Barcode, Box, Check, Coffee, Headphones, Laptop, LayoutGrid, List, Milk, Package, Search, ShieldCheck, ShoppingBag, Smartphone, Scale, X } from 'lucide-react';
import type { Product } from '../types/pos';
import { usePosStore } from '../stores/usePosStore';
import { useAuthStore } from '../stores/useAuthStore';
import { weightUnit } from '../../electron/quantity';

interface Props {
  products: Product[];
  isLoading: boolean;
  searchTerm: string;
  onSearchChange: (term: string) => void;
  onBarcodeSubmit: (barcode: string) => void;
  onProductClick: (product: Product) => void;
}

function productIcon(product: Product) {
  const text = `${product.name} ${product.category?.name || ''}`.toLowerCase();
  if (/phone|mobile|iphone|galaxy/.test(text)) return Smartphone;
  if (/laptop|macbook|computer/.test(text)) return Laptop;
  if (/headphone|earbud|airpod|audio/.test(text)) return Headphones;
  if (/milk|dairy/.test(text)) return Milk;
  if (/coffee|tea|drink|beverage/.test(text)) return Coffee;
  if (weightUnit(product.unit)) return Scale;
  if (/apparel|bag|shirt|clothing/.test(text)) return ShoppingBag;
  return Package;
}

export function ProductGrid({ products, isLoading, searchTerm, onSearchChange, onBarcodeSubmit, onProductClick }: Props) {
  const input = useRef<HTMLInputElement>(null);
  const language = usePosStore((state) => state.language);
  const currency = useAuthStore((state) => state.user?.store?.currency_symbol || '$');
  const [view, setView] = useState<'grid' | 'list'>('grid');
  const [sort, setSort] = useState('default');
  useEffect(() => {
    const focus = (event: KeyboardEvent) => {
      if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'f' && !usePosStore.getState().activeModal) {
        event.preventDefault(); input.current?.focus(); input.current?.select();
      }
    };
    window.addEventListener('keydown', focus);
    return () => window.removeEventListener('keydown', focus);
  }, []);
  const sorted = [...products].sort((a, b) => sort === 'price-low' ? Number(a.selling_price) - Number(b.selling_price) : sort === 'price-high' ? Number(b.selling_price) - Number(a.selling_price) : sort === 'name' ? a.name.localeCompare(b.name) : 0);
  return (
    <section className="catalog-main" aria-label="Product catalog">
      <div className="collection-heading"><div><span className="eyebrow"><span className="live-dot" />THE RETAIL COLLECTION</span><h1>Your collection.</h1><p>Thoughtfully organized. Ready for the next sale.</p></div><span className="catalog-count"><Box />{isLoading ? 'Loading catalog' : `${products.length} products in view`}</span></div>
      <div className="catalog-search"><Search /><input ref={input} aria-label="Search products or scan a barcode" placeholder="Search products, SKU, or scan a barcode…" value={searchTerm} onChange={(event) => onSearchChange(event.target.value)} onKeyDown={(event) => { if (event.key === 'Enter' && searchTerm.trim() && !event.defaultPrevented) { event.preventDefault(); onBarcodeSubmit(searchTerm.trim()); } }} /><kbd>Ctrl F</kbd>{searchTerm && <button type="button" aria-label="Clear search" onClick={() => { onSearchChange(''); input.current?.focus(); }}><X /></button>}<button type="button" className="scan-focus" title="Focus barcode input" onClick={() => { input.current?.focus(); input.current?.select(); }}><Barcode /><span>Scan</span></button></div>
      <div className="catalog-toolbar"><span>{searchTerm ? 'Search results' : 'All products'}<b>{products.length}</b></span><div><label className="sort-control">Sort this view<select value={sort} onChange={(event) => setSort(event.target.value)}><option value="default">Catalog order</option><option value="name">Name A–Z</option><option value="price-low">Price: low to high</option><option value="price-high">Price: high to low</option></select></label><div className="view-switch"><button type="button" aria-label="Grid view" aria-pressed={view === 'grid'} onClick={() => setView('grid')}><LayoutGrid /></button><button type="button" aria-label="List view" aria-pressed={view === 'list'} onClick={() => setView('list')}><List /></button></div></div></div>
      <div className="catalog-scroll" aria-busy={isLoading}>
        {isLoading ? <div className="product-collection">{Array.from({ length: 6 }, (_, index) => <div key={index} className="product-skeleton" />)}</div> : products.length === 0 ? <div className="catalog-empty"><Search /><h2>No products found.</h2><p>Try another name, SKU, barcode, or category.</p>{searchTerm && <button className="secondary-button" type="button" onClick={() => onSearchChange('')}>Clear search</button>}</div> :
          <div className={`product-collection ${view === 'list' ? 'is-list' : ''}`}>{sorted.map((product) => {
            const Icon = productIcon(product);
            const lowStock = product.stock_quantity > 0 && product.stock_quantity <= product.min_stock_level;
            const name = language === 'si' ? product.sinhala_name || product.name : product.name;
            return <button type="button" key={product.uuid} data-product-id={product.id} className="product-card" onClick={() => onProductClick(product)} aria-label={`${weightUnit(product.unit) ? 'Weigh' : 'Add'} ${product.name}`}>
              <div className={`product-art ${product.stock_quantity <= 0 ? 'stock-empty' : ''}`}><span className={`stock-label ${lowStock ? 'stock-low' : ''}`}><span />{product.stock_quantity <= 0 ? 'Out of stock' : `${product.stock_quantity} ${product.unit} available`}</span><Icon className="product-illustration" strokeWidth={0.8} aria-hidden="true" /><span className="product-art-caption">{product.category?.name || 'General collection'}</span><span className="product-add"><ArrowUpRight /></span></div>
              <div className="product-info"><span className="product-category">{product.category?.name || 'GENERAL'}</span><h3>{name}</h3>{language === 'bilingual' && product.sinhala_name && <p className="product-translation">{product.sinhala_name}</p>}<div className="product-meta"><span>{product.sku}</span>{product.warranty_period && <span title={product.warranty_period}><ShieldCheck />Warranty</span>}{product.requires_serial && <span><Check />Serial</span>}</div><div className="product-price"><strong>{currency} {Number(product.selling_price).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</strong>{weightUnit(product.unit) && <span>/ {weightUnit(product.unit)}</span>}{product.tax_rate > 0 && <small>+{product.tax_rate}% tax</small>}</div></div>
            </button>;
          })}</div>}
      </div>
      <div className="catalog-footer"><span><span className="live-dot" />Built for the way you sell.</span><span>Search <kbd>Ctrl F</kbd><i />Customer <kbd>F2</kbd><i />Checkout <kbd>F9</kbd></span></div>
    </section>
  );
}
