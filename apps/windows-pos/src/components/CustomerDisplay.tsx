// This entry point deliberately never imports cashier stores, authentication, sync, or API clients.
import { useEffect, useRef, useState } from 'react';
import { idleCustomerDisplay } from '../../electron/customer-display-types';
import type { CustomerDisplayState } from '../../electron/customer-display-types';

declare global {
  interface Window {
    customerDisplayApi?: { onState: (callback: (state: CustomerDisplayState) => void) => () => void };
  }
}

export function CustomerDisplay() {
  const [state, setState] = useState(idleCustomerDisplay);
  const lastRow = useRef<HTMLTableRowElement>(null);
  useEffect(() => window.customerDisplayApi?.onState(setState), []);
  useEffect(() => lastRow.current?.scrollIntoView({ block: 'nearest' }), [state.items]);
  const money = (value: number) => `${state.currencySymbol} ${value.toLocaleString('en-LK', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`.trim();
  return (
    <main className="display" lang={state.language === 'si' ? 'si' : 'en'}>
      <header><div className="brand">OMNILUXE STORE</div><h1>{state.storeName || 'OmniLuxe Flagship'}</h1></header>
      {state.items.length === 0 ? (
        <section className="welcome"><div className="welcome-mark">O</div><h2>Welcome to OmniLuxe Store</h2>
          <p>Thank you for shopping with us at our flagship boutique.</p></section>
      ) : (
        <div className="checkout">
          <section className="items" aria-label="Shopping items"><table><thead><tr>
            <th>Item</th><th>Qty</th><th>Amount</th>
          </tr></thead><tbody>{state.items.map((item, index) => {
            const isSinhala = state.language === 'si';
            const primaryName = isSinhala && item.sinhalaName ? item.sinhalaName : item.name;
            const subtitle = isSinhala ? (item.name !== item.sinhalaName ? item.name : '') : (item.sinhalaName || '');
            return (
              <tr key={index} ref={index === state.items.length - 1 ? lastRow : undefined}>
                <td><strong>{primaryName}</strong>
                  {subtitle && <span className="translation">{subtitle}</span>}
                  <span className="unit-price">{money(item.unitPrice)} × {item.quantity}</span></td>
                <td className="number">{item.quantity}</td><td className="number line-total">{money(item.total)}</td>
              </tr>
            );
          })}</tbody></table></section>
          <aside className="summary">
            <div className="summary-row"><span>Subtotal</span><b>{money(state.subtotal)}</b></div>
            <div className="summary-row"><span>Tax (VAT)</span><b>{money(state.tax)}</b></div>
            {state.billDiscount > 0 && <div className="summary-row"><span>Bill discount</span><b>−{money(state.billDiscount)}</b></div>}
            <div className="total"><span>Total Due</span><strong data-testid="total">{money(state.total)}</strong></div>
            <p className="summary-note">All prices include applicable luxury department taxes.</p>
          </aside>
        </div>
      )}
      <footer>Thank you for shopping at OmniLuxe Store. Please visit again.</footer>
    </main>
  );
}
