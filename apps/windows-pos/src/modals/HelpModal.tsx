import React from 'react';
import { usePosStore } from '../stores/usePosStore';
import { X, Keyboard, Zap, ShoppingBag, CreditCard, RotateCcw, PauseCircle, Search, UserCheck } from 'lucide-react';
import { CustomerDisplayControl } from '../components/CustomerDisplayControl';

export const HelpModal: React.FC = () => {
  const { closeModal } = usePosStore();

  const shortcuts = [
    { key: 'F1', label: 'Help & Shortcuts', desc: 'Opens this keyboard shortcuts cheat sheet', icon: Keyboard, color: 'text-indigo-400' },
    { key: 'F2', label: 'Customer CRM', desc: 'Search customer or apply loyalty points', icon: UserCheck, color: 'text-sky-400' },
    { key: 'F3', label: 'Returns & Refunds', desc: 'Look up past invoices for item return', icon: RotateCcw, color: 'text-amber-400' },
    { key: 'F4', label: 'Hold Bill', desc: 'Save active cart to cloud & free register', icon: PauseCircle, color: 'text-amber-500' },
    { key: 'F8', label: 'Cash Drawer', desc: 'Send kickout pulse to open register drawer', icon: Zap, color: 'text-emerald-400' },
    { key: 'F9', label: 'Proceed to Pay', desc: 'Jump directly to payment modal', icon: CreditCard, color: 'text-emerald-500' },
    { key: 'Ctrl + F', label: 'Search / Scan', desc: 'Focus the product search or barcode scanner', icon: Search, color: 'text-slate-300' },
    { key: 'Esc', label: 'Close / Cancel', desc: 'Dismiss active modal or clear inputs', icon: X, color: 'text-rose-400' },
  ];

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-xl shadow-2xl overflow-hidden flex flex-col animate-in fade-in zoom-in-95 duration-150">
        {/* Header */}
        <div className="p-5 border-b border-slate-800 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-indigo-400">
              <Keyboard className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-base font-bold text-white">Cashier Keyboard Shortcuts</h3>
              <p className="text-xs text-slate-400 mt-0.5">High-speed keyboard navigation for checkout lanes</p>
            </div>
          </div>
          <button
            onClick={closeModal}
            className="p-1.5 text-slate-400 hover:text-white hover:bg-slate-800 rounded-lg transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-5 grid grid-cols-1 md:grid-cols-2 gap-3 max-h-[65vh] overflow-y-auto">
          {shortcuts.map((s) => {
            const Icon = s.icon;
            return (
              <div
                key={s.key}
                className="bg-slate-950/60 border border-slate-800/80 rounded-2xl p-3.5 flex items-start gap-3 hover:border-slate-700 transition-colors"
              >
                <div className="flex-shrink-0 w-8 h-8 rounded-xl bg-slate-800/80 border border-slate-700 flex items-center justify-center">
                  <Icon className={`w-4 h-4 ${s.color}`} />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between gap-2 mb-1">
                    <span className="text-xs font-bold text-white truncate">{s.label}</span>
                    <span className="font-mono text-[11px] font-bold text-indigo-300 bg-indigo-950/80 border border-indigo-800/60 px-2 py-0.5 rounded-lg flex-shrink-0">
                      {s.key}
                    </span>
                  </div>
                  <p className="text-[11px] text-slate-400 leading-tight">{s.desc}</p>
                </div>
              </div>
            );
          })}
        </div>

        {/* Footer */}
        <CustomerDisplayControl />
        <div className="p-4 bg-slate-950/80 border-t border-slate-800 flex items-center justify-between text-xs text-slate-400">
          <span className="flex items-center gap-1.5">
            <ShoppingBag className="w-4 h-4 text-emerald-400" />
            <span>Optimized for fast barcode scanning & wedge HID devices</span>
          </span>
          <button
            onClick={closeModal}
            className="px-4 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-semibold rounded-xl transition-colors cursor-pointer"
          >
            Got it
          </button>
        </div>
      </div>
    </div>
  );
};
