import axios from 'axios';
import type { Product, Category, User, SaleReceipt } from '../types/pos';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000/api/v1';

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
  timeout: 10000,
});

apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('pos_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  const deviceUuid = localStorage.getItem('pos_device_uuid');
  if (deviceUuid) {
    config.headers['X-Device-UUID'] = deviceUuid;
  }
  return config;
});

export const api = {
  // Auth
  login: async (credentials: { email?: string; password?: string; pin_code?: string; device_uuid?: string }) => {
    const res = await apiClient.post('/auth/login', credentials);
    return res.data;
  },
  getMe: async (): Promise<{ user: User }> => {
    const res = await apiClient.get('/auth/me');
    return res.data;
  },
  logout: async () => {
    const res = await apiClient.post('/auth/logout');
    return res.data;
  },

  // Products
  getProducts: async (params?: { search?: string; category_uuid?: string; page?: number; per_page?: number }) => {
    const res = await apiClient.get<{ data: Product[]; meta: any }>('/products', { params });
    return res.data;
  },
  getProductByBarcode: async (barcode: string): Promise<{ product: Product }> => {
    const res = await apiClient.get(`/products/barcode/${barcode}`);
    return res.data;
  },
  getCategories: async (): Promise<{ data: Category[] }> => {
    const res = await apiClient.get('/categories');
    return res.data;
  },

  // Sales
  createSale: async (salePayload: any): Promise<{ status: string; sale: any; receipt: SaleReceipt }> => {
    const res = await apiClient.post('/sales', salePayload);
    return res.data;
  },
  getSales: async () => {
    const res = await apiClient.get('/sales');
    return res.data;
  },

  // Cash Register Sessions
  openCashSession: async (data: { opening_balance: number; notes?: string }) => {
    const res = await apiClient.post('/cash-sessions/open', data);
    return res.data;
  },
  getCurrentCashSession: async () => {
    const res = await apiClient.get('/cash-sessions/current');
    return res.data;
  },
  closeCashSession: async (data: { closing_balance: number; notes?: string }) => {
    const res = await apiClient.post('/cash-sessions/close', data);
    return res.data;
  },

  // Sync
  syncPush: async (payload: { device_uuid: string; transactions: any[] }) => {
    const res = await apiClient.post('/sync/push', payload);
    return res.data;
  },
  syncPull: async (params?: { since_version?: number; device_uuid?: string }) => {
    const res = await apiClient.get('/sync/pull', { params });
    return res.data;
  },
  syncStatus: async () => {
    const res = await apiClient.get('/sync/status');
    return res.data;
  },
};
