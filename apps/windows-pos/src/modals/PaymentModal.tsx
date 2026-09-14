import React, { useState } from 'react';
import { useCartStore } from '../stores/useCartStore';
import { usePosStore } from '../stores/usePosStore';
import { api } from '../services/api';
import type { PaymentType } from '../types/pos';
import { X, Banknote, CreditCard, Landmark, CheckCircle, AlertCircle, Loader2 } from 'lucide-react';

export const PaymentModal: React.FC = () => {
  const { items, customer, billDiscount, getGrandTotal, clearCart } = useCartStore();
  const { closeModal, openModal, setLastCompletedSale } = usePosStore();

  const grandTotal = getGrandTotal();

  const [paymentMethod, setPaymentMethod] = useState<PaymentType>('cash');
  const [cashTendered, setCashTendered] = useState<string>(grandTotal.toFixed(2));
  const [referenceNumber, setReferenceNumber] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const tenderedAmount = parseFloat(cashTendered) || 0;
  const changeDue = Math.max(0, tenderedAmount - grandTotal);
  const isSufficient = paymentMethod === 'cash' ? tenderedAmount >= grandTotal : true;

  const handlePreset = (amount: number) => {
    setCashTendered(amount.toFixed(2));
  };

  const handlePay = async () => {
    if (!isSufficient) return;

    setIsSubmitting(true);
    setErrorMessage(null);

    try {
      const payload = {
        transaction_uuid: crypto.randomUUID(),
        customer_id: customer?.id,
        customer_uuid: customer?.uuid,
        discount_amount: billDiscount,
        items: items.map((i) => ({
          product_id: i.product.id,
          product_uuid: i.product.uuid,
          quantity: i.quantity,
          unit_price: i.unitPrice,
          discount_amount: i.discountAmount,
        })),
        payments: [
          {
            payment_method: paymentMethod,
            amount: paymentMethod === 'cash' ? tenderedAmount : grandTotal,
            reference_number: referenceNumber || null,
          },
        ],
      };

      const result = await api.createSale(payload);

      // Trigger hardware cash drawer if electron bridge is present
      if (window.posApi && paymentMethod === 'cash') {
        window.posApi.openCashDrawer().catch(() => {});
      }

      setLastCompletedSale({
        ...result.sale,
        receipt: result.receipt,
        cashTendered: tenderedAmount,
        changeDue: changeDue,
        paymentMethod,
      });

      clearCart();
      closeModal();
      openModal('receipt');
    } catch (err: any) {
      const msg = err.response?.data?.message || 'Failed to complete sale transaction.';
      setErrorMessage(msg);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-lg shadow-2xl overflow-hidden flex flex-col animate-in fade-in zoom-in-95 duration-150">
        {/* Header */}
        <div className="p-6 border-b border-slate-800 flex items-center justify-between">
          <div>
            <h3 className="text-lg font-bold text-white">Finalize Checkout</h3>
            <p className="text-xs text-slate-400 mt-0.5">Select payment method and collect payment</p>
          </div>
          <button
            onClick={closeModal}
            className="p-2 text-slate-400 hover:text-white hover:bg-slate-800 rounded-xl transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-6 flex-1 overflow-y-auto">
          {/* Total Amount Due Banner */}
          <div className="bg-slate-950/80 border border-slate-800 rounded-2xl p-4 flex items-center justify-between">
            <span className="text-sm font-medium text-slate-400">Total Amount Due</span>
            <span className="text-3xl font-black text-emerald-400 font-mono">
              ${grandTotal.toFixed(2)}
            </span>
          </div>

          {/* Payment Method Selector */}
          <div>
            <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
              Payment Method
            </label>
            <div className="grid grid-cols-3 gap-3">
              <button
                type="button"
                onClick={() => {
                  setPaymentMethod('cash');
                  setCashTendered(grandTotal.toFixed(2));
                }}
                className={`flex flex-col items-center justify-center gap-2 p-3.5 rounded-2xl border text-xs font-bold transition-all cursor-pointer ${
                  paymentMethod === 'cash'
                    ? 'bg-indigo-600 border-indigo-500 text-white shadow-lg shadow-indigo-600/30'
                    : 'bg-slate-950/60 border-slate-800 text-slate-400 hover:bg-slate-800/80 hover:text-white'
                }`}
              >
                <Banknote className="w-6 h-6" />
                <span>Cash</span>
              </button>

              <button
                type="button"
                onClick={() => setPaymentMethod('card')}
                className={`flex flex-col items-center justify-center gap-2 p-3.5 rounded-2xl border text-xs font-bold transition-all cursor-pointer ${
                  paymentMethod === 'card'
                    ? 'bg-indigo-600 border-indigo-500 text-white shadow-lg shadow-indigo-600/30'
                    : 'bg-slate-950/60 border-slate-800 text-slate-400 hover:bg-slate-800/80 hover:text-white'
                }`}
              >
                <CreditCard className="w-6 h-6" />
                <span>Card</span>
              </button>

              <button
                type="button"
                onClick={() => setPaymentMethod('bank_transfer')}
                className={`flex flex-col items-center justify-center gap-2 p-3.5 rounded-2xl border text-xs font-bold transition-all cursor-pointer ${
                  paymentMethod === 'bank_transfer'
                    ? 'bg-indigo-600 border-indigo-500 text-white shadow-lg shadow-indigo-600/30'
                    : 'bg-slate-950/60 border-slate-800 text-slate-400 hover:bg-slate-800/80 hover:text-white'
                }`}
              >
                <Landmark className="w-6 h-6" />
                <span>Bank Transfer</span>
              </button>
            </div>
          </div>

          {/* Cash Inputs & Quick Presets */}
          {paymentMethod === 'cash' && (
            <div className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                  Tendered Amount ($)
                </label>
                <div className="relative">
                  <span className="absolute left-4 top-1/2 -translate-y-1/2 text-xl font-bold text-slate-400 font-mono">
                    $
                  </span>
                  <input
                    type="number"
                    step="0.01"
                    min="0"
                    value={cashTendered}
                    onChange={(e) => setCashTendered(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-700/80 rounded-2xl pl-10 pr-4 py-3.5 text-2xl font-black text-white font-mono focus:outline-none focus:ring-2 focus:ring-indigo-500"
                    autoFocus
                  />
                </div>
              </div>

              {/* Quick Cash Presets */}
              <div className="grid grid-cols-5 gap-2">
                <button
                  type="button"
                  onClick={() => handlePreset(grandTotal)}
                  className="py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold rounded-xl border border-slate-700 transition-colors cursor-pointer"
                >
                  Exact
                </button>
                <button
                  type="button"
                  onClick={() => handlePreset(Math.ceil(grandTotal / 10) * 10 || 10)}
                  className="py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold rounded-xl border border-slate-700 transition-colors cursor-pointer"
                >
                  ${Math.ceil(grandTotal / 10) * 10 || 10}
                </button>
                <button
                  type="button"
                  onClick={() => handlePreset(20)}
                  className="py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold rounded-xl border border-slate-700 transition-colors cursor-pointer"
                >
                  $20
                </button>
                <button
                  type="button"
                  onClick={() => handlePreset(50)}
                  className="py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold rounded-xl border border-slate-700 transition-colors cursor-pointer"
                >
                  $50
                </button>
                <button
                  type="button"
                  onClick={() => handlePreset(100)}
                  className="py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold rounded-xl border border-slate-700 transition-colors cursor-pointer"
                >
                  $100
                </button>
              </div>

              {/* Change Return Calculation */}
              <div className="p-4 rounded-2xl bg-indigo-950/30 border border-indigo-900/50 flex items-center justify-between">
                <span className="text-sm font-semibold text-slate-300">Change to Return</span>
                <span
                  className={`text-2xl font-black font-mono ${
                    isSufficient ? 'text-indigo-400' : 'text-rose-400'
                  }`}
                >
                  {isSufficient ? `$${changeDue.toFixed(2)}` : 'Insufficient Cash'}
                </span>
              </div>
            </div>
          )}

          {/* Reference input for Card / Bank Transfer */}
          {paymentMethod !== 'cash' && (
            <div>
              <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                Transaction / Authorization Reference
              </label>
              <input
                type="text"
                placeholder="e.g. CARD-AUTH-9831"
                value={referenceNumber}
                onChange={(e) => setReferenceNumber(e.target.value)}
                className="w-full bg-slate-950 border border-slate-700 rounded-xl px-4 py-3 text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 font-mono"
              />
            </div>
          )}

          {errorMessage && (
            <div className="p-3 bg-rose-950/60 border border-rose-900 text-rose-300 rounded-xl text-xs flex items-center gap-2">
              <AlertCircle className="w-4 h-4 text-rose-400 flex-shrink-0" />
              <span>{errorMessage}</span>
            </div>
          )}
        </div>

        {/* Footer actions */}
        <div className="p-6 border-t border-slate-800 flex items-center gap-3">
          <button
            type="button"
            onClick={closeModal}
            className="flex-1 py-3 px-4 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 font-semibold text-sm transition-colors cursor-pointer"
          >
            Cancel
          </button>

          <button
            type="button"
            onClick={handlePay}
            disabled={!isSufficient || isSubmitting}
            className="flex-2 py-3.5 px-4 rounded-xl bg-emerald-600 hover:bg-emerald-500 active:scale-[0.99] text-white font-bold text-sm shadow-lg shadow-emerald-600/30 flex items-center justify-center gap-2 transition-all disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
          >
            {isSubmitting ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                <span>Processing...</span>
              </>
            ) : (
              <>
                <CheckCircle className="w-4 h-4" />
                <span>Complete Payment</span>
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
};
