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

export const App: React.FC = () => {
  const { token, checkAuth } = useAuthStore();
  const { setOnline, activeModal, closeModal } = usePosStore();
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
    if (token) {
      fetchCategories();
      fetchProducts();
    }
  }, [token, fetchCategories, fetchProducts]);

  // Fast Barcode submission
  const handleBarcodeSubmit = async (barcode: string) => {
    try {
      const res = await api.getProductByBarcode(barcode);
      if (res.product) {
        addItem(res.product, 1);
        setSearchTerm('');
      }
    } catch {
      // If barcode not found directly, keep search term filtered
    }
  };

  // Hardware Barcode Scanner listener if Electron Bridge is attached
  useEffect(() => {
    if (window.posApi?.onBarcodeScan) {
      const unsubscribe = window.posApi.onBarcodeScan((scannedBarcode) => {
        handleBarcodeSubmit(scannedBarcode);
      });
      return unsubscribe;
    }
  }, []);

  // Keyboard shortcut for Escape key to close modals
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && activeModal) {
        closeModal();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [activeModal, closeModal]);

  // If not logged in, render the login screen
  if (!token) {
    return <LoginScreen />;
  }

  return (
    <div className="h-screen w-screen flex flex-col bg-slate-950 text-slate-100 overflow-hidden font-sans">
      {/* Top Application Bar */}
      <Header />

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
    </div>
  );
};

export default App;
