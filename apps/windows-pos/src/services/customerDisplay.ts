import { idleCustomerDisplay } from '../../electron/customer-display-types';
import type { CustomerDisplayState } from '../../electron/customer-display-types';
import { roundMoney } from '../../electron/money';
import { useAuthStore } from '../stores/useAuthStore';
import { useCartStore } from '../stores/useCartStore';
import { usePosStore } from '../stores/usePosStore';

/** Subscribe independently of React rendering so logout/clear/hold updates reach the display immediately. */
export function startCustomerDisplay(): () => void {
  const bridge = window.posApi;
  if (!bridge?.publishCustomerDisplay) return () => {};
  let previous = '';
  const publish = () => {
    const { token, user } = useAuthStore.getState();
    const cart = useCartStore.getState();
    const state: CustomerDisplayState = token && user ? {
      storeName: user.store?.name || 'SmartShop POS',
      currencySymbol: user.store?.currency_symbol || '',
      language: usePosStore.getState().language,
      items: cart.items.map((item) => ({ name: item.product.name, sinhalaName: item.product.sinhala_name || '',
        quantity: item.quantity, unitPrice: Number(item.unitPrice), total: roundMoney(item.total) })),
      subtotal: roundMoney(cart.getSubtotal()), tax: roundMoney(cart.getTaxTotal()),
      billDiscount: roundMoney(cart.billDiscount), total: cart.getGrandTotal(),
    } : idleCustomerDisplay();
    const encoded = JSON.stringify(state);
    if (encoded === previous) return;
    previous = encoded;
    void bridge.publishCustomerDisplay(state).catch((error: unknown) => {
      previous = '';
      console.error('Unable to update customer display:', error);
    });
  };
  const subscriptions = [useCartStore.subscribe(publish), useAuthStore.subscribe(publish), usePosStore.subscribe(publish)];
  publish();
  return () => subscriptions.forEach((unsubscribe) => unsubscribe());
}
