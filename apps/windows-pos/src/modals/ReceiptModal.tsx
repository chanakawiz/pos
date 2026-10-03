import React, { useState } from 'react';
import { usePosStore } from '../stores/usePosStore';
import { Printer, Check, X, ArrowRight, Barcode as BarcodeIcon, Globe } from 'lucide-react';

type ReceiptLanguage = 'bilingual' | 'si' | 'en';

export const ReceiptModal: React.FC = () => {
  const { closeModal, lastCompletedSale, language, setLanguage } = usePosStore();
  const [lang, setLang] = useState<ReceiptLanguage>(language);

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

  const storeNameEnv = import.meta.env.VITE_STORE_NAME || 'SMARTSHOP POS';
  const storeNameSiEnv = import.meta.env.VITE_STORE_NAME_SI || 'ස්මාර්ට්ෂොප් වෙළඳසැල';

  // Bilingual translation dictionary
  const t = {
    invoice: lang === 'si' ? 'බිල්පත් අංකය' : lang === 'bilingual' ? 'Invoice / බිල්පත් අංකය' : 'Invoice #',
    date: lang === 'si' ? 'දිනය' : lang === 'bilingual' ? 'Date / දිනය' : 'Date',
    cashier: lang === 'si' ? 'අයකැමි' : lang === 'bilingual' ? 'Cashier / අයකැමි' : 'Cashier',
    item: lang === 'si' ? 'භාණ්ඩය' : lang === 'bilingual' ? 'Item / භාණ්ඩය' : 'Item',
    qty: lang === 'si' ? 'ප්‍රමාණය' : lang === 'bilingual' ? 'Qty / ප්‍රම.' : 'Qty',
    totalCol: lang === 'si' ? 'එකතුව' : lang === 'bilingual' ? 'Total / එකතුව' : 'Total',
    subtotal: lang === 'si' ? 'උප එකතුව' : lang === 'bilingual' ? 'Subtotal / උප එකතුව' : 'Subtotal',
    tax: lang === 'si' ? 'වැට් බදු' : lang === 'bilingual' ? 'Tax / බදු' : 'Tax',
    discount: lang === 'si' ? 'වට්ටම්' : lang === 'bilingual' ? 'Discount / වට්ටම්' : 'Discount',
    grandTotal: lang === 'si' ? 'මුළු එකතුව' : lang === 'bilingual' ? 'TOTAL / මුළු මුදල' : 'TOTAL',
    paid: lang === 'si' ? 'ගෙවූ මුදල' : lang === 'bilingual' ? `Paid / ගෙවූ (${paymentMethod})` : `Paid (${paymentMethod})`,
    change: lang === 'si' ? 'ඉතිරි මුදල' : lang === 'bilingual' ? 'Change / ඉතිරි' : 'Change Given',
    storeNameSi: storeNameSiEnv,
    storeNameEn: storeNameEnv,
    footerSi: 'ස්තූතියි! නැවත එන්න.',
    footerEn: 'Thank you! Please visit again.',
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/85 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-md shadow-2xl overflow-hidden flex flex-col animate-in fade-in zoom-in-95 duration-150 max-h-[92vh]">
        {/* Modal Top Bar */}
        <div className="p-4 border-b border-slate-800 flex items-center justify-between bg-slate-950/50">
          <div className="flex items-center gap-2 text-emerald-400">
            <Check className="w-5 h-5" />
            <span className="font-bold text-sm text-white">Payment Finalized</span>
          </div>

          {/* Language Selector */}
          <div className="flex items-center gap-1 bg-slate-800/80 p-0.5 rounded-xl border border-slate-700/60">
            <Globe className="w-3.5 h-3.5 text-slate-400 ml-1.5" />
            <button
              onClick={() => { setLang('bilingual'); setLanguage('bilingual'); }}
              className={`px-2 py-1 text-[11px] font-bold rounded-lg transition-all cursor-pointer ${
                lang === 'bilingual' ? 'bg-indigo-600 text-white shadow-sm' : 'text-slate-400 hover:text-white'
              }`}
            >
              Dual (EN+සිං)
            </button>
            <button
              onClick={() => { setLang('si'); setLanguage('si'); }}
              className={`px-2 py-1 text-[11px] font-bold rounded-lg transition-all cursor-pointer ${
                lang === 'si' ? 'bg-indigo-600 text-white shadow-sm' : 'text-slate-400 hover:text-white'
              }`}
            >
              සිංහල
            </button>
            <button
              onClick={() => { setLang('en'); setLanguage('en'); }}
              className={`px-2 py-1 text-[11px] font-bold rounded-lg transition-all cursor-pointer ${
                lang === 'en' ? 'bg-indigo-600 text-white shadow-sm' : 'text-slate-400 hover:text-white'
              }`}
            >
              EN
            </button>
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
              {(lang === 'si' || lang === 'bilingual') && (
                <div className="font-bold text-sm tracking-tight text-slate-800 font-sans mb-0.5">
                  {t.storeNameSi}
                </div>
              )}
              <h2 className="font-black text-base tracking-tight text-black uppercase">
                {receipt?.store_name || t.storeNameEn}
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
                <span>{t.invoice}:</span>
                <span className="font-bold font-mono">{invoice_number}</span>
              </div>
              <div className="flex justify-between">
                <span>{t.date}:</span>
                <span>{new Date(sold_at).toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span>{t.cashier}:</span>
                <span>{receipt?.cashier_name || 'Sarah Miller'}</span>
              </div>
            </div>

            {/* Line Items */}
            <div className="border-b border-dashed border-slate-400 pb-2 mb-2">
              <div className="grid grid-cols-12 font-bold pb-1 text-[10px] text-slate-700 uppercase">
                <span className="col-span-6">{t.item}</span>
                <span className="col-span-2 text-center">{t.qty}</span>
                <span className="col-span-4 text-right">{t.totalCol}</span>
              </div>
              <div className="space-y-1.5 pt-1">
                {items?.map((item: any, idx: number) => (
                  <div key={idx} className="grid grid-cols-12 text-[11px] leading-snug">
                    <div className="col-span-6 min-w-0 pr-1">
                      <div className="truncate font-semibold">{item.product_name}</div>
                      {item.sinhala_name && (lang === 'si' || lang === 'bilingual') && (
                        <div className="text-[10px] text-slate-600 font-sans truncate">
                          {item.sinhala_name}
                        </div>
                      )}
                      {item.serial_number && (
                        <div className="text-[9px] text-indigo-700 font-mono font-medium truncate">
                          SN/IMEI: {item.serial_number}
                        </div>
                      )}
                      {item.warranty_notes && (
                        <div className="text-[9px] text-slate-500 font-sans truncate">
                          🛡️ {item.warranty_notes}
                        </div>
                      )}
                    </div>
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
                <span>{t.subtotal}:</span>
                <span>${Number(subtotal).toFixed(2)}</span>
              </div>
              {tax_amount > 0 && (
                <div className="flex justify-between">
                  <span>{t.tax}:</span>
                  <span>+${Number(tax_amount).toFixed(2)}</span>
                </div>
              )}
              {discount_amount > 0 && (
                <div className="flex justify-between text-emerald-700">
                  <span>{t.discount}:</span>
                  <span>-${Number(discount_amount).toFixed(2)}</span>
                </div>
              )}
              <div className="flex justify-between text-sm font-black pt-1 border-t border-slate-300">
                <span>{t.grandTotal}:</span>
                <span className="font-mono">${Number(total_amount).toFixed(2)}</span>
              </div>
            </div>

            {/* Payment Details */}
            <div className="space-y-1 text-[11px] border-b border-dashed border-slate-400 pb-2 mb-3">
              <div className="flex justify-between">
                <span className="uppercase">{t.paid}:</span>
                <span className="font-mono">${Number(paid_amount).toFixed(2)}</span>
              </div>
              <div className="flex justify-between font-bold">
                <span>{t.change}:</span>
                <span className="font-mono">${Number(change_amount).toFixed(2)}</span>
              </div>
            </div>

            {/* Barcode & Footer */}
            <div className="text-center pt-1">
              <div className="flex items-center justify-center gap-1 text-slate-800">
                <BarcodeIcon className="w-12 h-10 stroke-1" />
              </div>
              <div className="text-[9px] text-slate-500 font-mono tracking-widest mt-0.5">
                *{invoice_number}*
              </div>
              <div className="text-[10px] text-slate-600 mt-2 space-y-0.5">
                {(lang === 'si' || lang === 'bilingual') && (
                  <div className="font-sans font-medium">{t.footerSi}</div>
                )}
                {(lang === 'en' || lang === 'bilingual') && (
                  <div className="italic">{t.footerEn}</div>
                )}
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
