import { useCallback, useEffect, useState } from 'react';
import { ArrowRight, Check, ChevronDown, Minus, PauseCircle, Plus, ShoppingBag, Star, Tag, Trash2, UserPlus, X } from 'lucide-react';
import { useCartStore } from '../stores/useCartStore';
import { usePosStore } from '../stores/usePosStore';
import { useAuthStore } from '../stores/useAuthStore';
import { api } from '../services/api';
import { roundQuantity, weightUnit } from '../../electron/quantity';

export function Cart() {
  const { items, customer, heldBills, billDiscount, updateQuantity, updateSerial, removeItem, clearCart, holdCurrentBill, setBillDiscount, getSubtotal, getTaxTotal, getTotalDiscount, getGrandTotal } = useCartStore();
  const { openModal, language } = usePosStore();
  const currency = useAuthStore((state) => state.user?.store?.currency_symbol || '$');
  const money = (value: number) => `${currency} ${value.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  const [editingDiscount, setEditingDiscount] = useState(false);
  const [discountDraft, setDiscountDraft] = useState('');
  const [editingSerial, setEditingSerial] = useState<number | null>(null);
  const [serialDraft, setSerialDraft] = useState('');
  const handleHold = useCallback(async () => {
    const pos = usePosStore.getState();
    if (items.length === 0 || pos.activeModal || pos.isCompletingSale) return;
    const reference = `HOLD-${Math.floor(1000 + Math.random() * 9000)}`;
    const captured = [...items];
    const subtotal = getGrandTotal();
    holdCurrentBill(reference);
    try { await api.createHeldBill({ hold_reference: reference, cart_items_json: captured, subtotal, customer_uuid: customer?.uuid }); }
    catch (error) { console.warn('Held bill kept locally:', error); }
  }, [items, customer?.uuid, getGrandTotal, holdCurrentBill]);
  useEffect(() => {
    const shortcut = (event: KeyboardEvent) => {
      const pos = usePosStore.getState();
      if (pos.activeModal || pos.isCompletingSale || event.repeat) return;
      if (event.key === 'F2') { event.preventDefault(); openModal('customer'); }
      if (event.key === 'F4') { event.preventDefault(); void handleHold(); }
      if (event.key === 'F9' && items.length) { event.preventDefault(); openModal('payment'); }
    };
    window.addEventListener('keydown', shortcut);
    return () => window.removeEventListener('keydown', shortcut);
  }, [handleHold, items.length, openModal]);
  return (
    <aside className="sale-panel" aria-label="Current sale">
      <div className="sale-heading"><div><span className="eyebrow">THE CHECKOUT</span><h2>Current sale<span>{items.length.toString().padStart(2, '0')}</span></h2></div><button type="button" className="icon-button" title="Clear Cart" aria-label="Clear cart" disabled={!items.length} onClick={clearCart}><Trash2 /></button></div>
      <div className="sale-customer">{customer ? <><span className="customer-avatar">{customer.name.charAt(0)}</span><div><strong>{customer.name}</strong><small>{customer.phone || 'Customer attached'}</small></div>{Number(customer.loyalty_points) > 0 && <button type="button" title="Redeem points for discount" onClick={async () => { if (!customer.uuid) return; const value = prompt(`Redeem points (Available: ${customer.loyalty_points}):`, '50'); if (!value || !Number.isInteger(Number(value)) || Number(value) <= 0) return; try { const result = await api.redeemCustomerLoyalty(customer.uuid, Number(value)); setBillDiscount(billDiscount + result.discount_value); useCartStore.getState().setCustomer({ ...customer, loyalty_points: result.remaining_points }); } catch { usePosStore.getState().setHardwareMessage('Unable to redeem loyalty points. Please try again.'); } }}><Star />{customer.loyalty_points}</button>}<button className="icon-button" title="Remove Customer" aria-label="Remove customer" onClick={() => useCartStore.getState().setCustomer(null)}><X /></button></> : <button type="button" className="add-customer" onClick={() => openModal('customer')}><span className="customer-avatar"><UserPlus /></span><span><strong>Walk-in customer</strong><small>Add a customer to this sale</small></span><kbd>F2</kbd></button>}</div>
      <div className="sale-items">
        {!items.length ? <div className="sale-empty"><div className="empty-bag"><ShoppingBag strokeWidth={1} /><span>+</span></div><h3>A fresh start.</h3><p>Choose a product or scan a barcode.<br />Your next sale starts here.</p><span className="empty-caption">READY WHEN YOU ARE</span></div> : items.map(({ product, quantity, unitPrice, total, taxAmount, discountAmount, serial_number }, index) => <article className="sale-item" key={product.id}>
          <div className="sale-item-top"><span className="line-number">{(index + 1).toString().padStart(2, '0')}</span><div className="sale-item-name"><h3>{language === 'si' ? product.sinhala_name || product.name : product.name}</h3>{language === 'bilingual' && product.sinhala_name && <small>{product.sinhala_name}</small>}<p>{money(Number(unitPrice))} / {product.unit}</p></div><strong className="line-total">{money(Number(total))}</strong></div>
          <div className="sale-item-detail">{product.warranty_period && <span>{product.warranty_period}</span>}<button type="button" className={product.requires_serial && !serial_number ? 'serial-required' : ''} title="Click to enter/scan IMEI or Serial Number" onClick={() => { setEditingSerial(editingSerial === product.id ? null : product.id); setSerialDraft(serial_number || ''); }}>{serial_number ? `S/N ${serial_number}` : product.requires_serial ? 'Add IMEI / serial *' : 'Add serial'}<ChevronDown /></button></div>
          {editingSerial === product.id && <form className="inline-editor" onSubmit={(event) => { event.preventDefault(); updateSerial(product.id, serialDraft.trim()); setEditingSerial(null); }}><input aria-label={`Serial number for ${product.name}`} placeholder="Scan or enter serial / IMEI" value={serialDraft} onChange={(event) => setSerialDraft(event.target.value)} autoFocus /><button type="submit" aria-label="Save serial number"><Check /></button><button type="button" aria-label="Cancel serial editing" onClick={() => setEditingSerial(null)}><X /></button></form>}
          <div className="sale-item-bottom">{weightUnit(product.unit) ? <div className="weighed-quantity"><span>{quantity.toFixed(3)} {weightUnit(product.unit)}</span><button type="button" onClick={() => usePosStore.getState().openWeighing(product, true)}>Reweigh</button></div> : <div className="quantity-stepper"><button type="button" aria-label={`Decrease ${product.name} quantity`} onClick={() => updateQuantity(product.id, roundQuantity(quantity - 1))}><Minus /></button><span>{quantity}</span><button type="button" aria-label={`Increase ${product.name} quantity`} onClick={() => updateQuantity(product.id, roundQuantity(quantity + 1))}><Plus /></button></div>}<div className="line-adjustments">{discountAmount > 0 && <span>−{money(discountAmount)}</span>}{taxAmount > 0 && <small>Tax {money(taxAmount)}</small>}<button type="button" className="icon-button" aria-label={`Remove ${product.name}`} onClick={() => removeItem(product.id)}><X /></button></div></div>
        </article>)}
      </div>
      <div className="sale-summary">
        {heldBills.length > 0 && <button type="button" className="held-notice" onClick={() => openModal('hold')}><PauseCircle /><span>Held ({heldBills.length})</span><ArrowRight /></button>}
        <dl className="sale-breakdown"><div><dt>Subtotal</dt><dd>{money(getSubtotal())}</dd></div><div><dt>Tax</dt><dd>{money(getTaxTotal())}</dd></div>{getTotalDiscount() > 0 && <div className="discount-line"><dt>Discounts</dt><dd>−{money(getTotalDiscount())}</dd></div>}</dl>
        <div className="sale-total"><div><span>Total due</span><small>{items.length} {items.length === 1 ? 'item' : 'items'} in this sale</small></div><strong>{money(getGrandTotal())}</strong></div>
        {editingDiscount && <form className="inline-editor discount-editor" onSubmit={(event) => { event.preventDefault(); const amount = Number(discountDraft); if (Number.isFinite(amount) && amount >= 0) { setBillDiscount(amount); setEditingDiscount(false); } }}><label htmlFor="bill-discount">Bill discount</label><input id="bill-discount" type="number" min="0" step="0.01" value={discountDraft} onChange={(event) => setDiscountDraft(event.target.value)} autoFocus /><button type="submit" aria-label="Apply bill discount"><Check /></button><button type="button" aria-label="Cancel discount editing" onClick={() => setEditingDiscount(false)}><X /></button></form>}
        <div className="sale-actions"><button type="button" disabled={!items.length} onClick={() => void handleHold()}><PauseCircle />Hold<kbd>F4</kbd></button><button type="button" disabled={!items.length} onClick={() => { setEditingDiscount(!editingDiscount); setDiscountDraft(String(billDiscount)); }}><Tag />Discount</button></div>
        <button type="button" className="checkout-button" disabled={!items.length} onClick={() => openModal('payment')}><span>Proceed to pay<kbd>F9</kbd></span><ArrowRight /></button>
        <p className="checkout-note">Every detail, in order.</p>
      </div>
    </aside>
  );
}
