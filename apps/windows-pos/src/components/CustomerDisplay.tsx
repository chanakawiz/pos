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
  const label = (en: string, si: string) => state.language === 'en' ? en : state.language === 'si' ? si : `${en} / ${si}`;
  const money = (value: number) => `${state.currencySymbol} ${value.toLocaleString('en-LK', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`.trim();
  return (
    <main className="display" lang={state.language === 'si' ? 'si' : 'en'}>
      <header><div className="brand">SMARTSHOP</div><h1>{state.storeName}</h1></header>
      {state.items.length === 0 ? (
        <section className="welcome"><div className="welcome-mark">S</div><h2>{label('Welcome', 'ආයුබෝවන්')}</h2>
          <p>{label('Thank you for shopping with us', 'අප සමඟ සාප්පු සවාරි යාම ගැන ස්තූතියි')}</p></section>
      ) : (
        <div className="checkout">
          <section className="items" aria-label="Shopping items"><table><thead><tr>
            <th>{label('Item', 'භාණ්ඩය')}</th><th>{label('Qty', 'ප්‍රමාණය')}</th><th>{label('Amount', 'මුදල')}</th>
          </tr></thead><tbody>{state.items.map((item, index) => (
            <tr key={index} ref={index === state.items.length - 1 ? lastRow : undefined}>
              <td><strong>{state.language === 'si' ? item.sinhalaName || item.name : item.name}</strong>
                {state.language === 'bilingual' && item.sinhalaName && <span className="translation">{item.sinhalaName}</span>}
                <span className="unit-price">{money(item.unitPrice)} × {item.quantity}</span></td>
              <td className="number">{item.quantity}</td><td className="number line-total">{money(item.total)}</td>
            </tr>
          ))}</tbody></table></section>
          <aside className="summary">
            <div className="summary-row"><span>{label('Subtotal', 'උප එකතුව')}</span><b>{money(state.subtotal)}</b></div>
            <div className="summary-row"><span>{label('Tax', 'බදු')}</span><b>{money(state.tax)}</b></div>
            {state.billDiscount > 0 && <div className="summary-row"><span>{label('Bill discount', 'බිල් වට්ටම')}</span><b>−{money(state.billDiscount)}</b></div>}
            <div className="total"><span>{label('Total due', 'මුළු එකතුව')}</span><strong data-testid="total">{money(state.total)}</strong></div>
            <p className="summary-note">{label('Line amounts include line discounts and tax.', 'භාණ්ඩ මුදල් සඳහා වට්ටම් සහ බදු ඇතුළත් වේ.')}</p>
          </aside>
        </div>
      )}
      <footer>{label('Thank you! Please visit again.', 'ස්තූතියි! නැවත එන්න.')}</footer>
    </main>
  );
}
