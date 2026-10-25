import React, { useCallback, useEffect } from 'react';
import { ShoppingBag, Trash2, UserPlus, Minus, Plus, Tag, PauseCircle, ArrowRight, Star, X, ShieldCheck } from 'lucide-react';
import { useCartStore } from '../stores/useCartStore';
import { usePosStore } from '../stores/usePosStore';
import { useAuthStore } from '../stores/useAuthStore';
import { api } from '../services/api';
import { roundQuantity, weightUnit } from '../../electron/quantity';

export const Cart: React.FC = () => {
  const {
    items,
    customer,
    heldBills,
    billDiscount,
    updateQuantity,
    updateSerial,
    removeItem,
    clearCart,
    holdCurrentBill,
    setBillDiscount,
    getSubtotal,
    getTaxTotal,
    getTotalDiscount,
    getGrandTotal,
  } = useCartStore();

  const { openModal, language } = usePosStore();
  const currency = useAuthStore((state) => state.user?.store?.currency_symbol || '$');

  const subtotal = getSubtotal();
  const taxTotal = getTaxTotal();
  const totalDiscount = getTotalDiscount();
  const grandTotal = getGrandTotal();

  const handleHoldBill = useCallback(async () => {
    const pos = usePosStore.getState();
    if (items.length === 0 || pos.activeModal || pos.isCompletingSale) return;

    const reference = `HOLD-${Math.floor(1000 + Math.random() * 9000)}`;
    const capturedItems = [...items];
    const billSubtotal = getGrandTotal();

    holdCurrentBill(reference);

    try {
      await api.createHeldBill({
        hold_reference: reference,
        cart_items_json: capturedItems,
        subtotal: billSubtotal,
        customer_uuid: customer?.uuid,
      });
    } catch (err) {
      console.warn('Could not sync held bill to server, held locally:', err);
    }
  }, [items, customer?.uuid, getGrandTotal, holdCurrentBill]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      const pos = usePosStore.getState();
      if (pos.activeModal || pos.isCompletingSale || e.repeat) return;

      if (e.key === 'F2') {
        e.preventDefault();
        openModal('customer');
      } else if (e.key === 'F4' && items.length > 0) {
        e.preventDefault();
        void handleHoldBill();
      } else if (e.key === 'F9' && items.length > 0) {
        e.preventDefault();
        openModal('payment');
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [handleHoldBill, items.length, openModal]);

  const handleDiscountClick = () => {
    if (typeof window.prompt === 'function' && (window as any).smokePrompt) {
      const value = window.prompt('Bill discount:', String(billDiscount));
      if (value !== null) {
        const amount = Number(value);
        if (Number.isFinite(amount) && amount >= 0) {
          setBillDiscount(amount);
          return;
        }
      }
    }
    const val = prompt('Enter bill discount amount:', billDiscount.toString());
    if (val !== null) {
      const parsed = parseFloat(val);
      if (!isNaN(parsed) && parsed >= 0) {
        setBillDiscount(parsed);
      }
    }
  };

  return (
    <div className="w-[410px] 2xl:w-[450px] bg-slate-900/95 backdrop-blur-md border-l border-slate-800 flex flex-col h-full select-none shadow-2xl shrink-0">
      {/* Top Header: Current Sale & Clear */}
      <div className="p-4 border-b border-slate-800 flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-xl bg-indigo-600/20 border border-indigo-500/30 flex items-center justify-center text-indigo-400">
            <ShoppingBag className="w-4 h-4" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-sm font-extrabold text-white tracking-tight">Current Sale</h2>
              <span className="text-[10px] font-mono font-bold bg-indigo-950/80 text-indigo-300 border border-indigo-900/60 px-2 py-0.5 rounded-full">
                {items.length.toString().padStart(2, '0')} items
              </span>
            </div>
            <p className="text-[10px] text-slate-400">Station Lane Checkout</p>
          </div>
        </div>

        <button
          type="button"
          onClick={clearCart}
          disabled={items.length === 0}
          title="Clear Cart"
          className="p-2 text-slate-400 hover:text-rose-400 hover:bg-slate-800/80 rounded-xl transition-colors disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer"
        >
          <Trash2 className="w-4 h-4" />
        </button>
      </div>

      {/* Customer Bar */}
      <div className="px-4 py-2.5 bg-slate-950/60 border-b border-slate-800/80 flex items-center justify-between">
        {customer ? (
          <div className="flex items-center justify-between w-full">
            <div className="flex items-center gap-2.5 min-w-0">
              <div className="w-7 h-7 rounded-lg bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 flex items-center justify-center font-bold text-xs">
                {customer.name.charAt(0)}
              </div>
              <div className="min-w-0">
                <div className="text-xs font-bold text-white truncate">{customer.name}</div>
                <div className="text-[10px] text-slate-400 truncate">{customer.phone || 'VIP Customer'}</div>
              </div>
            </div>

            <div className="flex items-center gap-2">
              {Number(customer.loyalty_points) > 0 && (
                <button
                  type="button"
                  title="Redeem points for discount"
                  onClick={async () => {
                    if (!customer.uuid) return;
                    const val = prompt(`Redeem points (Available: ${customer.loyalty_points}):`, '50');
                    if (!val || !Number.isInteger(Number(val)) || Number(val) <= 0) return;
                    try {
                      const result = await api.redeemCustomerLoyalty(customer.uuid, Number(val));
                      setBillDiscount(billDiscount + result.discount_value);
                      useCartStore.getState().setCustomer({
                        ...customer,
                        loyalty_points: result.remaining_points,
                      });
                    } catch {
                      usePosStore.getState().setHardwareMessage('Unable to redeem loyalty points. Please try again.');
                    }
                  }}
                  className="flex items-center gap-1 text-[11px] font-bold text-amber-300 bg-amber-950/60 px-2 py-1 rounded-lg border border-amber-800/60 hover:bg-amber-900/60 transition-colors cursor-pointer"
                >
                  <Star className="w-3 h-3 fill-amber-400" />
                  <span>{customer.loyalty_points} pts</span>
                </button>
              )}
              <button
                type="button"
                onClick={() => useCartStore.getState().setCustomer(null)}
                className="p-1 text-slate-400 hover:text-rose-400 rounded-lg cursor-pointer"
                title="Remove Customer"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        ) : (
          <button
            type="button"
            onClick={() => openModal('customer')}
            className="flex items-center justify-between w-full text-slate-300 hover:text-white transition-colors cursor-pointer group"
          >
            <div className="flex items-center gap-2">
              <UserPlus className="w-4 h-4 text-indigo-400 group-hover:scale-110 transition-transform" />
              <span className="text-xs font-semibold">Walk-in Customer</span>
            </div>
            <span className="text-[10px] font-mono text-slate-400 bg-slate-900 px-2 py-0.5 rounded-md border border-slate-800">
              [F2] Add
            </span>
          </button>
        )}
      </div>

      {/* Cart Items List */}
      <div className="flex-1 overflow-y-auto p-4 space-y-2.5">
        {items.length === 0 ? (
          <div className="h-full flex flex-col items-center justify-center text-center p-6 text-slate-500">
            <div className="w-14 h-14 rounded-2xl bg-slate-950 border border-slate-800/80 flex items-center justify-center mb-3 shadow-inner">
              <ShoppingBag className="w-7 h-7 text-slate-600" />
            </div>
            <h3 className="text-sm font-bold text-slate-300">A fresh start.</h3>
            <p className="text-xs text-slate-500 mt-1 max-w-[220px]">
              Choose a product or scan a barcode to begin this sale.
            </p>
          </div>
        ) : (
          items.map(({ product, quantity, unitPrice, total, taxAmount, discountAmount, serial_number }, index) => {
            const isWeighed = !!weightUnit(product.unit);

            return (
              <div
                key={product.id}
                className="bg-slate-950/70 border border-slate-800/90 rounded-2xl p-3 flex flex-col gap-2.5 shadow-sm"
              >
                {/* Title, Unit Price, Line Total */}
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-1.5">
                      <span className="text-[10px] font-mono font-bold text-slate-500">
                        {(index + 1).toString().padStart(2, '0')}.
                      </span>
                      <h4 className="text-xs font-bold text-white truncate">
                        {language === 'si' ? product.sinhala_name || product.name : product.name}
                      </h4>
                    </div>

                    {language === 'bilingual' && product.sinhala_name && (
                      <div className="text-[10px] text-amber-300/90 truncate font-medium ml-4">
                        {product.sinhala_name}
                      </div>
                    )}

                    {/* Warranty & Serial Tags */}
                    <div className="flex items-center gap-1.5 flex-wrap mt-1 ml-4">
                      {product.warranty_period && (
                        <span className="flex items-center gap-0.5 text-[9px] text-cyan-400 bg-cyan-950/70 px-1.5 py-0.5 rounded border border-cyan-800/40">
                          <ShieldCheck className="w-2.5 h-2.5" />
                          {product.warranty_period}
                        </span>
                      )}

                      <button
                        type="button"
                        onClick={() => {
                          const val = prompt(`Enter IMEI or Serial Number for ${product.name}:`, serial_number || '');
                          if (val !== null) {
                            updateSerial(product.id, val.trim());
                          }
                        }}
                        className={`text-[9px] font-mono px-1.5 py-0.5 rounded border transition-colors cursor-pointer ${
                          serial_number
                            ? 'bg-indigo-950 text-indigo-300 border-indigo-700/60'
                            : product.requires_serial
                            ? 'bg-rose-950/80 text-rose-300 border-rose-700/60 animate-pulse font-bold'
                            : 'bg-slate-900 text-slate-400 border-slate-700/60 hover:text-white'
                        }`}
                        title="Click to enter/scan IMEI or Serial Number"
                      >
                        {serial_number
                          ? `S/N: ${serial_number}`
                          : product.requires_serial
                          ? '+ Add IMEI / Serial *'
                          : '+ S/N'}
                      </button>
                    </div>

                    <div className="text-[10px] text-slate-400 font-mono mt-1 ml-4">
                      {currency} {Number(unitPrice).toFixed(2)} / {product.unit}
                    </div>
                  </div>

                  <div className="text-right">
                    <div className="text-xs font-bold text-white font-mono">
                      {currency} {Number(total).toFixed(2)}
                    </div>
                    {taxAmount > 0 && (
                      <div className="text-[9px] text-slate-500">Tax {currency}{Number(taxAmount).toFixed(2)}</div>
                    )}
                  </div>
                </div>

                {/* Stepper & Line Controls */}
                <div className="flex items-center justify-between pt-2 border-t border-slate-850">
                  {isWeighed ? (
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-bold font-mono text-indigo-300 bg-indigo-950/70 px-2 py-1 rounded-lg border border-indigo-900/50">
                        {quantity.toFixed(3)} {product.unit}
                      </span>
                      <button
                        type="button"
                        onClick={() => usePosStore.getState().openWeighing(product, true)}
                        className="text-xs font-semibold px-2 py-1 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg border border-slate-700 transition-colors cursor-pointer"
                      >
                        Reweigh
                      </button>
                    </div>
                  ) : (
                    <div className="flex items-center gap-2 bg-slate-900 px-2 py-1 rounded-xl border border-slate-800">
                      <button
                        type="button"
                        onClick={() => updateQuantity(product.id, roundQuantity(quantity - 1))}
                        className="w-5 h-5 rounded-lg flex items-center justify-center text-slate-400 hover:text-white hover:bg-slate-800 transition-colors cursor-pointer"
                      >
                        <Minus className="w-3 h-3" />
                      </button>
                      <span className="text-xs font-bold text-white font-mono w-6 text-center">
                        {quantity}
                      </span>
                      <button
                        type="button"
                        onClick={() => updateQuantity(product.id, roundQuantity(quantity + 1))}
                        className="w-5 h-5 rounded-lg flex items-center justify-center text-slate-400 hover:text-white hover:bg-slate-800 transition-colors cursor-pointer"
                      >
                        <Plus className="w-3 h-3" />
                      </button>
                    </div>
                  )}

                  <div className="flex items-center gap-2">
                    {discountAmount > 0 && (
                      <span className="text-[10px] text-emerald-400 font-medium bg-emerald-950/60 px-1.5 py-0.5 rounded border border-emerald-900/50">
                        -{currency}{discountAmount.toFixed(2)}
                      </span>
                    )}
                    <button
                      type="button"
                      onClick={() => removeItem(product.id)}
                      className="p-1 text-slate-500 hover:text-rose-400 transition-colors cursor-pointer"
                      title="Remove item"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Cart Summary & Checkout Footer */}
      <div className="p-4 bg-slate-950/90 border-t border-slate-800 flex flex-col gap-3">
        {/* Held Notice Pill if active held bills exist */}
        {heldBills.length > 0 && (
          <button
            type="button"
            onClick={() => openModal('hold')}
            className="flex items-center justify-between w-full px-3 py-2 bg-amber-950/50 hover:bg-amber-950/80 border border-amber-800/50 rounded-xl text-amber-200 text-xs font-bold transition-colors cursor-pointer"
          >
            <div className="flex items-center gap-2">
              <PauseCircle className="w-4 h-4 text-amber-400" />
              <span>Held ({heldBills.length})</span>
            </div>
            <span className="text-[10px] underline">View / Resume</span>
          </button>
        )}

        {/* Breakdown */}
        <div className="space-y-1 text-xs text-slate-400">
          <div className="flex justify-between">
            <span>Subtotal</span>
            <span className="font-mono text-slate-200">{currency} {subtotal.toFixed(2)}</span>
          </div>

          <div className="flex justify-between">
            <span>Tax Amount</span>
            <span className="font-mono text-slate-200">+{currency} {taxTotal.toFixed(2)}</span>
          </div>

          {totalDiscount > 0 && (
            <div className="flex justify-between text-emerald-400 font-medium">
              <span>Total Discounts</span>
              <span className="font-mono">-{currency} {totalDiscount.toFixed(2)}</span>
            </div>
          )}

          <div className="pt-2 border-t border-slate-800 flex justify-between items-baseline">
            <div>
              <span className="text-sm font-bold text-white">Grand Total</span>
              <div className="text-[10px] text-slate-500">
                {items.length} {items.length === 1 ? 'item' : 'items'} in sale
              </div>
            </div>
            <span className="text-2xl font-black text-emerald-400 font-mono">
              {currency} {grandTotal.toFixed(2)}
            </span>
          </div>
        </div>

        {/* Quick Action Buttons */}
        <div className="grid grid-cols-2 gap-2 pt-1">
          <button
            type="button"
            onClick={handleHoldBill}
            disabled={items.length === 0}
            className="flex items-center justify-center gap-1.5 py-2.5 px-3 rounded-xl bg-slate-800 hover:bg-slate-750 text-slate-200 font-bold text-xs border border-slate-700 transition-colors disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer"
          >
            <PauseCircle className="w-4 h-4 text-amber-400" />
            <span>Hold (F4)</span>
          </button>

          <button
            type="button"
            onClick={handleDiscountClick}
            disabled={items.length === 0}
            className="flex items-center justify-center gap-1.5 py-2.5 px-3 rounded-xl bg-slate-800 hover:bg-slate-750 text-slate-200 font-bold text-xs border border-slate-700 transition-colors disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer"
          >
            <Tag className="w-4 h-4 text-indigo-400" />
            <span>Discount</span>
          </button>
        </div>

        {/* Main Pay Now Button */}
        <button
          type="button"
          onClick={() => openModal('payment')}
          disabled={items.length === 0}
          className="w-full py-3.5 px-4 bg-gradient-to-r from-emerald-600 to-teal-500 hover:from-emerald-500 hover:to-teal-400 active:scale-[0.99] text-white font-extrabold text-sm rounded-xl shadow-lg shadow-emerald-600/30 flex items-center justify-center gap-2 transition-all disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer"
        >
          <span>PROCEED TO PAY (F9)</span>
          <ArrowRight className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
};

