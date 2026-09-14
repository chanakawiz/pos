import React from 'react';
import { useCartStore } from '../stores/useCartStore';
import { usePosStore } from '../stores/usePosStore';
import { X, Play, Clock, ShoppingBag } from 'lucide-react';

export const HoldBillsModal: React.FC = () => {
  const { heldBills, restoreHeldBill } = useCartStore();
  const { closeModal } = usePosStore();

  const handleResume = (id: string) => {
    restoreHeldBill(id);
    closeModal();
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-lg shadow-2xl overflow-hidden flex flex-col animate-in fade-in zoom-in-95 duration-150">
        {/* Header */}
        <div className="p-5 border-b border-slate-800 flex items-center justify-between">
          <div>
            <h3 className="text-base font-bold text-white">Held Transactions</h3>
            <p className="text-xs text-slate-400 mt-0.5">Resume customer carts on hold</p>
          </div>
          <button
            onClick={closeModal}
            className="p-1.5 text-slate-400 hover:text-white hover:bg-slate-800 rounded-lg transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* List */}
        <div className="p-5 space-y-3 max-h-[60vh] overflow-y-auto">
          {heldBills.length === 0 ? (
            <div className="py-12 text-center text-slate-500">
              <ShoppingBag className="w-10 h-10 mx-auto mb-2 opacity-40" />
              <p className="text-sm">No bills are currently on hold</p>
            </div>
          ) : (
            heldBills.map((bill) => (
              <div
                key={bill.id}
                className="bg-slate-950/60 border border-slate-800 hover:border-slate-700 rounded-2xl p-4 flex items-center justify-between gap-4 transition-all"
              >
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="font-mono text-xs font-bold text-white">{bill.id}</span>
                    <span className="flex items-center gap-1 text-[11px] text-slate-400">
                      <Clock className="w-3 h-3 text-slate-500" />
                      {bill.timestamp}
                    </span>
                  </div>
                  <div className="text-xs text-slate-400">
                    {bill.items.length} {bill.items.length === 1 ? 'item' : 'items'} • Note: {bill.note}
                  </div>
                </div>

                <div className="text-right flex items-center gap-3">
                  <div className="font-mono font-bold text-emerald-400 text-sm">
                    ${bill.subtotal.toFixed(2)}
                  </div>
                  <button
                    onClick={() => handleResume(bill.id)}
                    className="flex items-center gap-1.5 px-3 py-2 bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold rounded-xl shadow-md transition-colors cursor-pointer"
                  >
                    <Play className="w-3.5 h-3.5 fill-current" />
                    <span>Resume</span>
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
};
