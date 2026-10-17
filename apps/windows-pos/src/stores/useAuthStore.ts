import { create } from 'zustand';
import type { User } from '../types/pos';
import { api } from '../services/api';
import axios from 'axios';

function cachedUser(): User | null {
  try {
    const user = JSON.parse(localStorage.getItem('pos_user') || 'null') as User | null;
    return user?.uuid && user.store?.uuid ? user : null;
  } catch {
    return null;
  }
}

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
  user: cachedUser(),
  token: localStorage.getItem('pos_token'),
  deviceUuid: localStorage.getItem('pos_device_uuid') || import.meta.env.VITE_DEVICE_UUID || '',
  isLoading: false,
  error: null,

  login: async (credentials) => {
    set({ isLoading: true, error: null });
    try {
      if (window.posApi && !get().deviceUuid) {
        throw new Error('Configure this terminal with its registered device UUID (VITE_DEVICE_UUID) before signing in.');
      }
      const res = await api.login({
        ...credentials,
        device_uuid: get().deviceUuid,
      });

      localStorage.setItem('pos_token', res.token);
      if (get().deviceUuid) localStorage.setItem('pos_device_uuid', get().deviceUuid);
      localStorage.setItem('pos_user', JSON.stringify(res.user));
      set({
        token: res.token,
        user: res.user,
        isLoading: false,
      });
      return true;
    } catch (err: any) {
      const message = err.response?.data?.message || err.message || 'Login failed. Please check credentials.';
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
      localStorage.removeItem('pos_user');
      set({ user: null, token: null });
    }
  },

  checkAuth: async () => {
    const token = get().token;
    if (!token) return;

    set({ isLoading: true });
    try {
      const res = await api.getMe();
      localStorage.setItem('pos_user', JSON.stringify(res.user));
      set({ user: res.user, isLoading: false });
    } catch (error: unknown) {
      if (axios.isAxiosError(error) && [401, 403].includes(error.response?.status ?? 0)) {
        localStorage.removeItem('pos_token');
        localStorage.removeItem('pos_user');
        set({ user: null, token: null, isLoading: false });
      } else {
        // An existing authenticated lane can recover its cached catalog during an outage.
        set({ isLoading: false });
      }
    }
  },
}));
