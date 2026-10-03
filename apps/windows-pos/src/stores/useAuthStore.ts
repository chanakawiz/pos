import { create } from 'zustand';
import type { User } from '../types/pos';
import { api } from '../services/api';

interface AuthState {
  user: User | null;
  token: string | null;
  deviceUuid: string;                
  isLoading: boolean;
  error: string | null;

  login: (credentials: { email?: string; password?: string; pin_code?: string }) => Promise<boolean>;
  logout: () => Promise<void>;
  checkAuth: () => Promise<void>;
}

export const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  token: localStorage.getItem('pos_token'),
  deviceUuid: localStorage.getItem('pos_device_uuid') || '550e8400-e29b-41d4-a716-446655440000',
  isLoading: false,
  error: null,

  login: async (credentials) => {
    set({ isLoading: true, error: null });
    try {
      const res = await api.login({
        ...credentials,
        device_uuid: get().deviceUuid,
      });

      localStorage.setItem('pos_token', res.token);
      set({
        token: res.token,
        user: res.user,
        isLoading: false,
      });
      return true;
    } catch (err: any) {
      const message = err.response?.data?.message || 'Login failed. Please check credentials.';
      set({ error: message, isLoading: false });
      return false;
    }
  },

  logout: async () => {
    try {
      if (get().token) {
        await api.logout();
      }
    } catch {
      // Ignore network errors on logout
    } finally {
      localStorage.removeItem('pos_token');
      set({ user: null, token: null });
    }
  },

  checkAuth: async () => {
    const token = get().token;
    if (!token) return;

    set({ isLoading: true });
    try {
      const res = await api.getMe();
      set({ user: res.user, isLoading: false });
    } catch {
      localStorage.removeItem('pos_token');
      set({ user: null, token: null, isLoading: false });
    }
  },
}));
