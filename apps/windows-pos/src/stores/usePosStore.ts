import { create } from 'zustand';
import type { Product } from '../types/pos';

export type PosModalType = 'payment' | 'hold' | 'cashSession' | 'receipt' | 'customer' | 'refund' | 'syncStatus' | 'help' | 'weighing';

interface PosState {
  isOnline: boolean;
  syncStatus: 'synced' | 'pending' | 'syncing' | 'error';
  pendingCount: number;
  isCompletingSale: boolean;
  hardwareMessage: string | null;
  setHardwareMessage: (message: string | null) => void;
  activeModal: PosModalType | null;
  weighingProduct: Product | null;
  replaceWeight: boolean;
  openWeighing: (product: Product, replace?: boolean) => void;
  lastCompletedSale: any | null;
  cashSession: any | null;
  language: 'bilingual' | 'si' | 'en';

  setOnline: (online: boolean) => void;
  setLanguage: (lang: 'bilingual' | 'si' | 'en') => void;
  setSyncStatus: (status: 'synced' | 'pending' | 'syncing' | 'error') => void;
  setPendingCount: (count: number) => void;
  openModal: (modal: PosModalType) => void;
  closeModal: () => void;
  setLastCompletedSale: (sale: any) => void;
  setCashSession: (session: any) => void;
  triggerManualSync: () => Promise<void>;
}

export const usePosStore = create<PosState>((set) => ({
  isOnline: navigator.onLine,
  syncStatus: 'synced',
  pendingCount: 0,
  isCompletingSale: false,
  hardwareMessage: null,
  setHardwareMessage: (hardwareMessage) => set({ hardwareMessage }),
  activeModal: null,
  weighingProduct: null,
  replaceWeight: false,
  openWeighing: (product, replace = false) => set((state) => state.activeModal || state.isCompletingSale ? {} : {
    activeModal: 'weighing', weighingProduct: product, replaceWeight: replace,
  }),
  lastCompletedSale: null,
  cashSession: null,
  language: ((import.meta.env.VITE_DEFAULT_LANGUAGE as any) || 'bilingual') as 'bilingual' | 'si' | 'en',

  setOnline: (online) => set({ isOnline: online }),
  setLanguage: (lang) => set({ language: lang }),
  setSyncStatus: (status) => set({ syncStatus: status }),
  setPendingCount: (count) => set({ pendingCount: count }),
  openModal: (modal) => set((state) => state.isCompletingSale ? {} : { activeModal: modal }),
  closeModal: () => set((state) => state.isCompletingSale ? {} : { activeModal: null, weighingProduct: null }),
  setLastCompletedSale: (sale) => set({ lastCompletedSale: sale }),
  setCashSession: (session) => set({ cashSession: session }),

  triggerManualSync: async () => {
    set({ syncStatus: 'syncing' });
    try {
      const { syncWorker } = await import('../services/syncWorker');
      await syncWorker.triggerImmediateSync();
    } catch {
      set({ syncStatus: 'error' });
    }
  },
}));
