import React, { useEffect } from 'react';
import { useCartStore } from '../stores/useCartStore';
import { usePosStore } from '../stores/usePosStore';
import { Trash2, Plus, Minus, ShoppingBag, PauseCircle, ArrowRight, UserCheck, Tag, X } from 'lucide-react';

export const Cart: React.FC = () => {
  const {
    items,
    customer,
    heldBills,
    billDiscount,
    updateQuantity,
    removeItem,
    clearCart,
    holdCurrentBill,
    setBillDiscount,
    getSubtotal,
    getTaxTotal,
    getTotalDiscount,
    getGrandTotal,
  } = useCartStore();

  const { openModal } = usePosStore();

  const subtotal = getSubtotal();
  const taxTotal = getTaxTotal();
  const totalDiscount = getTotalDiscount();
  const grandTotal = getGrandTotal();

  // Keyboard shortcut listener for F4 (Hold) and F9 (Pay)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'F4') {
        e.preventDefault();
        holdCurrentBill();
      } else if (e.key === 'F9' && items.length > 0) {
        e.preventDefault();
        openModal('payment');
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [items.length, holdCurrentBill, openModal]);

  return (
    <div className="w-[420px] bg-slate-900 border-l border-slate-800 flex flex-col h-full select-none">
      {/* Cart Top Bar */}
      <div className="p-4 border-b border-slate-800 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-lg bg-indigo-600/20 text-indigo-400 flex items-center justify-center border border-indigo-500/30">
            <ShoppingBag className="w-4 h-4" />
          </div>
          <div>
            <h2 className="text-sm font-bold text-white leading-none">Current Sale</h2>
            <span className="text-[11px] text-slate-400">
              {items.length} {items.length === 1 ? 'item' : 'items'}
            </span>
          </div>
        </div>

        <div className="flex items-center gap-2">
          {heldBills.length > 0 && (
            <button
              onClick={() => openModal('hold')}
              className="flex items-center gap-1.5 text-xs bg-amber-500/10 text-amber-400 hover:bg-amber-500/20 px-2.5 py-1.5 rounded-lg border border-amber-500/30 font-semibold transition-colors cursor-pointer"
            >
              <PauseCircle className="w-3.5 h-3.5" />
              <span>Held ({heldBills.length})</span>
            </button>
          )}

          {items.length > 0 && (
            <button
              onClick={clearCart}
              title="Clear Cart"
              className="p-1.5 text-slate-400 hover:text-rose-400 hover:bg-slate-800 rounded-lg transition-colors cursor-pointer"
            >
              <Trash2 className="w-4 h-4" />
            </button>
          )}
        </div>
      </div>

      {/* Customer Header Tag if assigned */}
      {customer && (
        <div className="px-4 py-2 bg-indigo-950/40 border-b border-indigo-900/40 flex items-center justify-between text-xs">
          <div className="flex items-center gap-2 text-indigo-300">
            <UserCheck className="w-3.5 h-3.5 text-indigo-400" />
            <span className="font-semibold">{customer.name}</span>
          </div>
          <button
            onClick={() => useCartStore.getState().setCustomer(null)}
            className="text-slate-400 hover:text-white"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      )}

      {/* Cart Items List */}
      <div className="flex-1 overflow-y-auto p-4 space-y-3">
        {items.length === 0 ? (
          <div className="h-full flex flex-col items-center justify-center text-center text-slate-500">
            <ShoppingBag className="w-12 h-12 stroke-[1.5] mb-3 opacity-40 text-indigo-400" />
            <p className="text-sm font-medium text-slate-400">Cart is empty</p>
            <p className="text-xs text-slate-500 max-w-[200px] mt-1">
              Click products or scan barcodes to begin transaction
            </p>
          </div>
        ) : (
          items.map(({ product, quantity, unitPrice, taxAmount, total, discountAmount }) => (
            <div
              key={product.id}
              className="bg-slate-950/60 border border-slate-800 rounded-xl p-3 flex flex-col gap-2 hover:border-slate-700 transition-colors"
            >
              <div className="flex items-start justify-between gap-2">
                <div className="flex-1 min-w-0">
                  <h4 className="text-xs font-semibold text-white truncate">{product.name}</h4>
                  <div className="text-[11px] text-slate-400 font-mono">
                    ${Number(unitPrice).toFixed(2)} / {product.unit}
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-xs font-bold text-white font-mono">
                    ${Number(total).toFixed(2)}
                  </div>
                  {taxAmount > 0 && (
                    <div className="text-[10px] text-slate-400">Tax: ${taxAmount.toFixed(2)}</div>
                  )}
                </div>
              </div>

              {/* Quantity Controls & Delete */}
              <div className="flex items-center justify-between pt-2 border-t border-slate-800/80">
                <div className="flex items-center gap-2 bg-slate-900 px-2 py-1 rounded-lg border border-slate-800">
                  <button
                    onClick={() => updateQuantity(product.id, quantity - 1)}
                    className="w-6 h-6 rounded flex items-center justify-center text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
                  >
                    <Minus className="w-3.5 h-3.5" />
                  </button>
                  <span className="text-xs font-bold text-white font-mono w-6 text-center">
                    {quantity}
                  </span>
                  <button
                    onClick={() => updateQuantity(product.id, quantity + 1)}
                    className="w-6 h-6 rounded flex items-center justify-center text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
                  >
                    <Plus className="w-3.5 h-3.5" />
                  </button>
                </div>

                <div className="flex items-center gap-2">
                  {discountAmount > 0 && (
                    <span className="text-[10px] text-emerald-400 font-medium bg-emerald-950/60 px-1.5 py-0.5 rounded border border-emerald-900/50">
                      -${discountAmount.toFixed(2)}
                    </span>
                  )}
                  <button
                    onClick={() => removeItem(product.id)}
                    className="p-1 text-slate-500 hover:text-rose-400 transition-colors"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Cart Summary & Checkout Footer */}
      <div className="p-4 bg-slate-950/80 border-t border-slate-800 flex flex-col gap-3">
        {/* Breakdown */}
        <div className="space-y-1.5 text-xs text-slate-400">
          <div className="flex justify-between">
            <span>Subtotal</span>
            <span className="font-mono text-slate-200">${subtotal.toFixed(2)}</span>
          </div>

          <div className="flex justify-between">
            <span>Tax Amount</span>
            <span className="font-mono text-slate-200">+${taxTotal.toFixed(2)}</span>
          </div>

          {totalDiscount > 0 && (
            <div className="flex justify-between text-emerald-400 font-medium">
              <span>Total Discounts</span>
              <span className="font-mono">-${totalDiscount.toFixed(2)}</span>
            </div>
          )}

          <div className="pt-2 border-t border-slate-800 flex justify-between items-baseline">
            <span className="text-sm font-semibold text-white">Grand Total</span>
            <span className="text-2xl font-black text-emerald-400 font-mono">
              ${grandTotal.toFixed(2)}
            </span>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="grid grid-cols-2 gap-2 pt-1">
          <button
            onClick={() => holdCurrentBill()}
            disabled={items.length === 0}
            className="flex items-center justify-center gap-1.5 py-2.5 px-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 font-semibold text-xs border border-slate-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
          >
            <PauseCircle className="w-4 h-4 text-amber-400" />
            <span>Hold (F4)</span>
          </button>

          <button
            onClick={() => {
              const amount = prompt('Enter bill discount amount ($):', billDiscount.toString());
              if (amount !== null) {
                const parsed = parseFloat(amount);
                if (!isNaN(parsed)) setBillDiscount(parsed);
              }
            }}
            disabled={items.length === 0}
            className="flex items-center justify-center gap-1.5 py-2.5 px-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 font-semibold text-xs border border-slate-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
          >
            <Tag className="w-4 h-4 text-indigo-400" />
            <span>Discount</span>
          </button>
        </div>

        {/* Main Pay Now Button */}
        <button
          onClick={() => openModal('payment')}
          disabled={items.length === 0}
          className="w-full py-3.5 px-4 bg-gradient-to-r from-emerald-600 to-teal-500 hover:from-emerald-500 hover:to-teal-400 active:scale-[0.99] text-white font-bold text-sm rounded-xl shadow-lg shadow-emerald-600/30 flex items-center justify-center gap-2 transition-all disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
        >
          <span>PROCEED TO PAY (F9)</span>
          <ArrowRight className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
};
