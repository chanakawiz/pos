import { create } from 'zustand';
import { api } from '../services/api';

interface PosState {
  isOnline: boolean;
  syncStatus: 'synced' | 'pending' | 'syncing' | 'error';
  pendingCount: number;
  activeModal: 'payment' | 'hold' | 'cashSession' | 'receipt' | null;
  lastCompletedSale: any | null;
  cashSession: any | null;

  setOnline: (online: boolean) => void;
  setSyncStatus: (status: 'synced' | 'pending' | 'syncing' | 'error') => void;
  setPendingCount: (count: number) => void;
  openModal: (modal: 'payment' | 'hold' | 'cashSession' | 'receipt') => void;
  closeModal: () => void;
  setLastCompletedSale: (sale: any) => void;
  setCashSession: (session: any) => void;
  triggerManualSync: () => Promise<void>;
}

export const usePosStore = create<PosState>((set) => ({
  isOnline: navigator.onLine,
  syncStatus: 'synced',
  pendingCount: 0,
  activeModal: null,
  lastCompletedSale: null,
  cashSession: null,

  setOnline: (online) => set({ isOnline: online }),
  setSyncStatus: (status) => set({ syncStatus: status }),
  setPendingCount: (count) => set({ pendingCount: count }),
  openModal: (modal) => set({ activeModal: modal }),
  closeModal: () => set({ activeModal: null }),
  setLastCompletedSale: (sale) => set({ lastCompletedSale: sale }),
  setCashSession: (session) => set({ cashSession: session }),

  triggerManualSync: async () => {
    set({ syncStatus: 'syncing' });
    try {
      await api.syncStatus();
      set({ syncStatus: 'synced' });
    } catch {
      set({ syncStatus: 'error' });
    }
  },
}));
