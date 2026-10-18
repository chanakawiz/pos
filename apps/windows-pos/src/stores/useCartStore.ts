import { create } from 'zustand';
import type { Product, CartItem } from '../types/pos';
import { roundMoney } from '../../electron/money';
import { isValidQuantity, roundQuantity } from '../../electron/quantity';

interface CartState {
  items: CartItem[];
  billDiscount: number;
  customer: { id?: number; uuid?: string; name: string; phone?: string | null; email?: string | null; loyalty_points?: number } | null;
  heldBills: { id: string; timestamp: string; note: string; items: CartItem[]; subtotal: number }[];

  // Actions
  addItem: (product: Product, quantity?: number) => void;
  removeItem: (productId: number) => void;
  updateQuantity: (productId: number, quantity: number) => void;
  updateSerial: (productId: number, serial: string) => void;
  updateDiscount: (productId: number, discountAmount: number) => void;
  setBillDiscount: (amount: number) => void;
  setCustomer: (customer: { id?: number; uuid?: string; name: string; phone?: string | null; email?: string | null; loyalty_points?: number } | null) => void;
  clearCart: () => void;
  holdCurrentBill: (note?: string) => void;
  restoreHeldBill: (heldId: string) => void;
  restoreCartItems: (items: CartItem[], billDiscount?: number, customer?: any) => void;
  removeHeldBill: (heldId: string) => void;

  // Selectors
  getSubtotal: () => number;
  getTaxTotal: () => number;
  getTotalDiscount: () => number;
  getGrandTotal: () => number;
}

export const useCartStore = create<CartState>((set, get) => ({
  items: [],
  billDiscount: 0,
  customer: null,
  heldBills: [],

  addItem: (product: Product, quantity = 1) => {
    if (!isValidQuantity(quantity)) throw new Error('Quantity must be positive with up to three decimal places.');
    set((state) => {
      const existingIndex = state.items.findIndex((item) => item.product.id === product.id);
      const unitPrice = product.selling_price;
      const taxRate = product.tax_rate;

      if (existingIndex > -1) {
        const updated = [...state.items];
        const item = updated[existingIndex];
        const newQty = roundQuantity(item.quantity + quantity);
        const subtotal = roundMoney(newQty * item.unitPrice - item.discountAmount);
        const taxAmount = item.taxRate > 0 ? roundMoney((subtotal * item.taxRate) / 100) : 0;
        const total = subtotal + taxAmount;

        updated[existingIndex] = {
          ...item,
          quantity: newQty,
          subtotal,
          taxAmount,
          total,
        };
        return { items: updated };
      }

      const subtotal = roundMoney(quantity * unitPrice);
      const taxAmount = taxRate > 0 ? roundMoney((subtotal * taxRate) / 100) : 0;
      const total = subtotal + taxAmount;

      const newItem: CartItem = {
        product,
        quantity,
        unitPrice,
        discountAmount: 0,
        taxRate,
        taxAmount,
        subtotal,
        total,
        serial_number: null,
        warranty_notes: product.warranty_period ? `Warranty: ${product.warranty_period}` : null,
      };

      return { items: [...state.items, newItem] };
    });
  },

  removeItem: (productId: number) => {
    set((state) => ({
      items: state.items.filter((item) => item.product.id !== productId),
    }));
  },

  updateSerial: (productId: number, serial: string) => {
    set((state) => ({
      items: state.items.map((item) =>
        item.product.id === productId ? { ...item, serial_number: serial } : item
      ),
    }));
  },

  updateQuantity: (productId: number, quantity: number) => {
    if (quantity <= 0) {
      get().removeItem(productId);
      return;
    }

    if (!isValidQuantity(quantity)) throw new Error('Invalid quantity.');
    set((state) => ({
      items: state.items.map((item) => {
        if (item.product.id !== productId) return item;

        const discountAmount = Math.min(item.discountAmount, quantity * item.unitPrice);
        const subtotal = roundMoney(quantity * item.unitPrice - discountAmount);
        const taxAmount = item.taxRate > 0 ? roundMoney((subtotal * item.taxRate) / 100) : 0;
        const total = subtotal + taxAmount;

        return {
          ...item,
          quantity,
          discountAmount,
          subtotal,
          taxAmount,
          total,
        };
      }),
    }));
  },

  updateDiscount: (productId: number, discountAmount: number) => {
    set((state) => ({
      items: state.items.map((item) => {
        if (item.product.id !== productId) return item;

        const discount = Math.max(0, Math.min(item.quantity * item.unitPrice, discountAmount));
        const subtotal = roundMoney(item.quantity * item.unitPrice - discount);
        const taxAmount = item.taxRate > 0 ? roundMoney((subtotal * item.taxRate) / 100) : 0;
        const total = subtotal + taxAmount;

        return {
          ...item,
          discountAmount: discount,
          subtotal,
          taxAmount,
          total,
        };
      }),
    }));
  },

  setBillDiscount: (amount: number) => {
    set({ billDiscount: Math.max(0, amount) });
  },

  setCustomer: (customer) => set({ customer }),

  clearCart: () => set({ items: [], billDiscount: 0, customer: null }),

  holdCurrentBill: (note = 'Quick Hold') => {
    const { items, getGrandTotal } = get();
    if (items.length === 0) return;

    const heldItem = {
      id: `HOLD-${Date.now()}`,
      timestamp: new Date().toLocaleTimeString(),
      note,
      items: [...items],
      subtotal: getGrandTotal(),
    };

    set((state) => ({
      heldBills: [heldItem, ...state.heldBills],
      items: [],
      billDiscount: 0,
      customer: null,
    }));
  },

  restoreHeldBill: (heldId: string) => {
    const bill = get().heldBills.find((b) => b.id === heldId);
    if (!bill) return;

    set((state) => ({
      items: [...bill.items],
      heldBills: state.heldBills.filter((b) => b.id !== heldId),
    }));
  },

  restoreCartItems: (items: CartItem[], billDiscount = 0, customer = null) => {
    set({
      items: [...items],
      billDiscount,
      customer,
    });
  },

  removeHeldBill: (heldId: string) => {
    set((state) => ({
      heldBills: state.heldBills.filter((b) => b.id !== heldId),
    }));
  },

  getSubtotal: () => {
    return get().items.reduce((sum, item) => sum + item.subtotal, 0);
  },

  getTaxTotal: () => {
    return get().items.reduce((sum, item) => sum + item.taxAmount, 0);
  },

  getTotalDiscount: () => {
    const itemDiscounts = get().items.reduce((sum, item) => sum + item.discountAmount, 0);
    return itemDiscounts + get().billDiscount;
  },

  getGrandTotal: () => {
    const subtotal = get().getSubtotal();
    const tax = get().getTaxTotal();
    const billDisc = get().billDiscount;
    return roundMoney(Math.max(0, subtotal + tax - billDisc));
  },
}));
