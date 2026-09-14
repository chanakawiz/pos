import React from 'react';
import { usePosStore } from '../stores/usePosStore';
import { Printer, Check, X, ArrowRight, Barcode as BarcodeIcon } from 'lucide-react';

export const ReceiptModal: React.FC = () => {
  const { closeModal, lastCompletedSale } = usePosStore();

  if (!lastCompletedSale) return null;

  const {
    invoice_number,
    sold_at,
    items,
    subtotal,
    tax_amount,
    discount_amount,
    total_amount,
    paid_amount,
    change_amount,
    receipt,
    paymentMethod,
  } = lastCompletedSale;

  const handlePrint = async () => {
    if (window.posApi) {
      await window.posApi.printReceipt(lastCompletedSale);
    } else {
      window.print();
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/85 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-md shadow-2xl overflow-hidden flex flex-col animate-in fade-in zoom-in-95 duration-150 max-h-[90vh]">
        {/* Modal Top Bar */}
        <div className="p-4 border-b border-slate-800 flex items-center justify-between bg-slate-950/50">
          <div className="flex items-center gap-2 text-emerald-400">
            <Check className="w-5 h-5" />
            <span className="font-bold text-sm text-white">Payment Successful</span>
          </div>
          <button
            onClick={closeModal}
            className="p-1.5 text-slate-400 hover:text-white hover:bg-slate-800 rounded-lg transition-colors cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Thermal Receipt Paper Visualizer */}
        <div className="p-6 overflow-y-auto flex-1 flex justify-center bg-slate-950/40">
          <div className="w-[320px] bg-white text-slate-900 p-5 rounded-lg shadow-xl font-mono text-xs select-text border border-slate-200">
            {/* Store Header */}
            <div className="text-center border-b border-dashed border-slate-400 pb-3 mb-3">
              <h2 className="font-black text-base tracking-tight text-black uppercase">
                {receipt?.store_name || 'SMARTSHOP POS'}
              </h2>
              {receipt?.store_address && (
                <div className="text-[10px] text-slate-600 mt-0.5">{receipt.store_address}</div>
              )}
              {receipt?.store_phone && (
                <div className="text-[10px] text-slate-600">Tel: {receipt.store_phone}</div>
              )}
              {receipt?.tax_number && (
                <div className="text-[10px] text-slate-600">Tax ID: {receipt.tax_number}</div>
              )}
            </div>

            {/* Meta */}
            <div className="space-y-1 text-[11px] border-b border-dashed border-slate-400 pb-2 mb-2">
              <div className="flex justify-between">
                <span>Invoice #:</span>
                <span className="font-bold">{invoice_number}</span>
              </div>
              <div className="flex justify-between">
                <span>Date:</span>
                <span>{new Date(sold_at).toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span>Cashier:</span>
                <span>{receipt?.cashier_name || 'Sarah Connor'}</span>
              </div>
            </div>

            {/* Line Items */}
            <div className="border-b border-dashed border-slate-400 pb-2 mb-2">
              <div className="grid grid-cols-12 font-bold pb-1 text-[10px] text-slate-700 uppercase">
                <span className="col-span-6">Item</span>
                <span className="col-span-2 text-center">Qty</span>
                <span className="col-span-4 text-right">Total</span>
              </div>
              <div className="space-y-1.5 pt-1">
                {items?.map((item: any, idx: number) => (
                  <div key={idx} className="grid grid-cols-12 text-[11px] leading-snug">
                    <span className="col-span-6 truncate font-medium">{item.product_name}</span>
                    <span className="col-span-2 text-center text-slate-600">{item.quantity}</span>
                    <span className="col-span-4 text-right font-bold font-mono">
                      ${Number(item.total).toFixed(2)}
                    </span>
                  </div>
                ))}
              </div>
            </div>

            {/* Totals */}
            <div className="space-y-1 text-[11px] border-b border-dashed border-slate-400 pb-2 mb-2">
              <div className="flex justify-between">
                <span>Subtotal:</span>
                <span>${Number(subtotal).toFixed(2)}</span>
              </div>
              {tax_amount > 0 && (
                <div className="flex justify-between">
                  <span>Tax:</span>
                  <span>+${Number(tax_amount).toFixed(2)}</span>
                </div>
              )}
              {discount_amount > 0 && (
                <div className="flex justify-between text-emerald-700">
                  <span>Discount:</span>
                  <span>-${Number(discount_amount).toFixed(2)}</span>
                </div>
              )}
              <div className="flex justify-between text-sm font-black pt-1 border-t border-slate-300">
                <span>TOTAL:</span>
                <span>${Number(total_amount).toFixed(2)}</span>
              </div>
            </div>

            {/* Payment Details */}
            <div className="space-y-1 text-[11px] border-b border-dashed border-slate-400 pb-2 mb-3">
              <div className="flex justify-between">
                <span className="uppercase">Paid ({paymentMethod}):</span>
                <span>${Number(paid_amount).toFixed(2)}</span>
              </div>
              <div className="flex justify-between font-bold">
                <span>Change Given:</span>
                <span>${Number(change_amount).toFixed(2)}</span>
              </div>
            </div>

            {/* Barcode & Footer */}
            <div className="text-center pt-1">
              <div className="flex items-center justify-center gap-1 text-slate-800">
                <BarcodeIcon className="w-10 h-10 stroke-1" />
              </div>
              <div className="text-[9px] text-slate-500 font-mono tracking-widest mt-0.5">
                *{invoice_number}*
              </div>
              <div className="text-[10px] text-slate-600 italic mt-2">
                {receipt?.receipt_footer || 'Thank you for shopping with us!'}
              </div>
            </div>
          </div>
        </div>

        {/* Modal Actions */}
        <div className="p-4 bg-slate-950/80 border-t border-slate-800 flex items-center gap-3">
          <button
            type="button"
            onClick={handlePrint}
            className="flex-1 py-3 px-4 rounded-xl bg-indigo-600 hover:bg-indigo-500 active:scale-[0.99] text-white font-bold text-xs shadow-lg shadow-indigo-600/30 flex items-center justify-center gap-2 transition-all cursor-pointer"
          >
            <Printer className="w-4 h-4" />
            <span>Print Receipt</span>
          </button>

          <button
            type="button"
            onClick={closeModal}
            className="flex-1 py-3 px-4 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 font-semibold text-xs border border-slate-700 flex items-center justify-center gap-2 transition-colors cursor-pointer"
          >
            <span>Next Sale</span>
            <ArrowRight className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
};
