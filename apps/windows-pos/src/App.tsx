import React, { useEffect, useState, useCallback } from 'react';
import { useAuthStore } from './stores/useAuthStore';
import { usePosStore } from './stores/usePosStore';
import { useCartStore } from './stores/useCartStore';
import { api } from './services/api';
import type { Product, Category } from './types/pos';
import { Header } from './components/Header';
import { CategoryBar } from './components/CategoryBar';
import { ProductGrid } from './components/ProductGrid';
import { Cart } from './components/Cart';
import { LoginScreen } from './components/LoginScreen';
import { PaymentModal } from './modals/PaymentModal';
import { ReceiptModal } from './modals/ReceiptModal';
import { HoldBillsModal } from './modals/HoldBillsModal';
import { CashSessionModal } from './modals/CashSessionModal';
import { CustomerModal } from './modals/CustomerModal';
import { RefundModal } from './modals/RefundModal';
import { SyncStatusModal } from './modals/SyncStatusModal';
import { HelpModal } from './modals/HelpModal';
import { syncWorker } from './services/syncWorker';
import { useBarcodeScanner } from './hooks/useBarcodeScanner';
import { posSounds } from './utils/audio';
import { getCachedCatalog, getCachedProductByBarcode } from './services/offlineStorage';
import { openCashDrawer } from './services/hardware';
import { startCustomerDisplay } from './services/customerDisplay';

export const App: React.FC = () => {
  useEffect(startCustomerDisplay, []);
  const { token, user, checkAuth } = useAuthStore();
  const { setOnline, activeModal, closeModal, hardwareMessage, setHardwareMessage } = usePosStore();
  const { addItem } = useCartStore();

  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [selectedCategoryUuid, setSelectedCategoryUuid] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [isLoading, setIsLoading] = useState<boolean>(false);

  // Check auth session on startup
  useEffect(() => {
    checkAuth();
  }, [checkAuth]);

  // Online / Offline window listeners
  useEffect(() => {
    const handleOnline = () => setOnline(true);
    const handleOffline = () => setOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, [setOnline]);

  // Load Categories
  const fetchCategories = useCallback(async () => {
    try {
      const cached = await getCachedCatalog({ limit: 1 });
      if (cached && cached.current_version > 0) {
        setCategories(cached.categories);
        return;
      }
      const res = await api.getCategories();
      setCategories(res.data);
    } catch {
      // Fallback
    }
  }, []);

  // Load Products
  const fetchProducts = useCallback(async () => {
    setIsLoading(true);
    try {
      const cached = await getCachedCatalog({
        category_uuid: selectedCategoryUuid || undefined,
        search: searchTerm || undefined,
        limit: 50,
      });
      if (cached && cached.current_version > 0) {
        setProducts(cached.products);
        return;
      }
      const res = await api.getProducts({
        category_uuid: selectedCategoryUuid || undefined,
        search: searchTerm || undefined,
        per_page: 50,
      });
      setProducts(res.data);
    } catch {
      // Fallback
    } finally {
      setIsLoading(false);
    }
  }, [selectedCategoryUuid, searchTerm]);

  useEffect(() => {
    if (token && user) {
      fetchCategories();
      fetchProducts();
    }
  }, [token, user, fetchCategories, fetchProducts]);

  useEffect(() => {
    const refresh = () => { void fetchCategories(); void fetchProducts(); };
    window.addEventListener('pos:catalog-updated', refresh);
    return () => window.removeEventListener('pos:catalog-updated', refresh);
  }, [fetchCategories, fetchProducts]);

  // Fast Barcode submission
  const handleBarcodeSubmit = useCallback(async (barcode: string) => {
    try {
      const cached = await getCachedProductByBarcode(barcode);
      if (cached) {
        addItem(cached, 1);
        posSounds.playScannerBeep();
        setSearchTerm('');
        return;
      }
      const res = await api.getProductByBarcode(barcode);
      if (res.product) {
        addItem(res.product, 1);
        posSounds.playScannerBeep();
        setSearchTerm('');
        return;
      }
    } catch {
      // Direct barcode endpoint lookup failed, check in-memory catalog
      const matched = products.find(
        (p) => p.barcode === barcode || p.sku.toLowerCase() === barcode.toLowerCase()
      );
      if (matched) {
        addItem(matched, 1);
        posSounds.playScannerBeep();
        setSearchTerm('');
        return;
      }
      posSounds.playErrorChirp();
    }
  }, [addItem, products]);

  // Global USB/Bluetooth Barcode Scanner Hardware Hook
  useBarcodeScanner({
    onScan: (scanned) => {
      handleBarcodeSubmit(scanned);
    },
    enabled: !!token,
  });

  // Hardware Barcode Scanner listener if Electron Bridge is attached
  useEffect(() => {
    if (window.posApi?.onBarcodeScan) {
      const unsubscribe = window.posApi.onBarcodeScan((scannedBarcode) => {
        handleBarcodeSubmit(scannedBarcode);
      });
      return unsubscribe;
    }
  }, [handleBarcodeSubmit]);

  // Start background sync daemon when authenticated
  useEffect(() => {
    if (token) {
      syncWorker.start();
      return () => {
        syncWorker.stop();
      };
    }
  }, [token]);

  // Keyboard shortcuts: Esc to close modals, F1 Help, F3 Returns, F8 Cash Drawer, F7 Sync Status
  useEffect(() => {
    if (!token) return;
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && activeModal) {
        closeModal();
      } else if (e.key === 'F1') {
        e.preventDefault();
        usePosStore.getState().openModal('help');
      } else if (e.key === 'F3' && !activeModal) {
        e.preventDefault();
        usePosStore.getState().openModal('refund');
      } else if (e.key === 'F8') {
        e.preventDefault();
        if (!e.repeat) void openCashDrawer();
      } else if (e.key === 'F7' && !activeModal) {
        e.preventDefault();
        usePosStore.getState().openModal('syncStatus');
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [activeModal, closeModal, token]);

  // If not logged in, render the login screen
  if (!token) {
    return <LoginScreen />;
  }

  return (
    <div className="h-screen w-screen flex flex-col bg-slate-950 text-slate-100 overflow-hidden font-sans">
      {/* Top Application Bar */}
      <Header />
      {hardwareMessage && (
        <div role="alert" className="fixed bottom-4 right-4 z-[70] flex max-w-lg items-center justify-between gap-4 rounded-xl bg-amber-950 border border-amber-700 px-4 py-3 text-sm text-amber-100 shadow-xl">
          <span>{hardwareMessage}</span>
          <button type="button" onClick={() => setHardwareMessage(null)} className="underline cursor-pointer">Dismiss</button>
        </div>
      )}

      {/* Main POS Billing Workspace */}
      <div className="flex-1 flex min-h-0 overflow-hidden">
        {/* Left Side: Product Grid & Category Filter */}
        <div className="flex-1 flex flex-col min-w-0 border-r border-slate-800">
          <CategoryBar
            categories={categories}
            selectedCategoryUuid={selectedCategoryUuid}
            onSelectCategory={setSelectedCategoryUuid}
          />

          <ProductGrid
            products={products}
            isLoading={isLoading}
            searchTerm={searchTerm}
            onSearchChange={setSearchTerm}
            onBarcodeSubmit={handleBarcodeSubmit}
            onProductClick={(product) => addItem(product, 1)}
          />
        </div>

        {/* Right Side: Active Cart & Checkout */}
        <Cart />
      </div>

      {/* Modals */}
      {activeModal === 'payment' && <PaymentModal />}
      {activeModal === 'receipt' && <ReceiptModal />}
      {activeModal === 'hold' && <HoldBillsModal />}
      {activeModal === 'cashSession' && <CashSessionModal />}
      {activeModal === 'customer' && <CustomerModal />}
      {activeModal === 'refund' && <RefundModal />}
      {activeModal === 'syncStatus' && <SyncStatusModal />}
      {activeModal === 'help' && <HelpModal />}
    </div>
  );
};

export default App;
