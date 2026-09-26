import { create } from 'zustand';

export type PosModalType = 'payment' | 'hold' | 'cashSession' | 'receipt' | 'customer' | 'refund' | 'syncStatus';

interface PosState {
  isOnline: boolean;
  syncStatus: 'synced' | 'pending' | 'syncing' | 'error';
  pendingCount: number;
  activeModal: PosModalType | null;
  lastCompletedSale: any | null;
  cashSession: any | null;

  setOnline: (online: boolean) => void;
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
      const { syncWorker } = await import('../services/syncWorker');
      await syncWorker.triggerImmediateSync();
    } catch {
      set({ syncStatus: 'error' });
    }
  },
}));
