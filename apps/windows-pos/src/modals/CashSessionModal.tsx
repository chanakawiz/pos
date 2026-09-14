import React, { useState, useEffect } from 'react';
import { usePosStore } from '../stores/usePosStore';
import { api } from '../services/api';
import { X, DollarSign, Lock, AlertTriangle, CheckCircle, Loader2 } from 'lucide-react';

export const CashSessionModal: React.FC = () => {
  const { closeModal } = usePosStore();

  const [activeSession, setActiveSession] = useState<any | null>(null);
  const [openingFloat, setOpeningFloat] = useState<string>('150.00');
  const [closingCounted, setClosingCounted] = useState<string>('');
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [notes] = useState<string>('');

  const loadSession = async () => {
    setIsLoading(true);
    try {
      const res = await api.getCurrentCashSession();
      if (res.status === 'open') {
        setActiveSession(res);
        setClosingCounted(res.expected_balance?.toFixed(2) || '');
      } else {
        setActiveSession(null);
      }
    } catch {
      setActiveSession(null);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadSession();
  }, []);

  const handleOpenShift = async () => {
    setIsSubmitting(true);
    try {
      await api.openCashSession({
        opening_balance: parseFloat(openingFloat) || 0,
        notes,
      });
      await loadSession();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to open register.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleCloseShift = async () => {
    setIsSubmitting(true);
    try {
      await api.closeCashSession({
        closing_balance: parseFloat(closingCounted) || 0,
        notes,
      });
      closeModal();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to close register.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const expected = activeSession ? activeSession.expected_balance : 0;
  const counted = parseFloat(closingCounted) || 0;
  const discrepancy = counted - expected;

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-md shadow-2xl overflow-hidden flex flex-col animate-in fade-in zoom-in-95 duration-150">
        {/* Header */}
        <div className="p-5 border-b border-slate-800 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <DollarSign className="w-5 h-5 text-indigo-400" />
            <h3 className="text-base font-bold text-white">Cash Register Shift</h3>
          </div>
          <button
            onClick={closeModal}
            className="p-1.5 text-slate-400 hover:text-white hover:bg-slate-800 rounded-lg transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-5">
          {isLoading ? (
            <div className="py-12 flex justify-center text-slate-500">
              <Loader2 className="w-6 h-6 animate-spin" />
            </div>
          ) : activeSession ? (
            /* Close Shift View */
            <div className="space-y-4">
              <div className="bg-slate-950/60 border border-slate-800 rounded-2xl p-4 space-y-2 text-xs">
                <div className="flex justify-between text-slate-400">
                  <span>Shift Opened:</span>
                  <span className="text-white">{new Date(activeSession.session.opened_at).toLocaleTimeString()}</span>
                </div>
                <div className="flex justify-between text-slate-400">
                  <span>Opening Float:</span>
                  <span className="font-mono text-white">${Number(activeSession.session.opening_balance).toFixed(2)}</span>
                </div>
                <div className="flex justify-between text-slate-400">
                  <span>Cash Sales This Shift:</span>
                  <span className="font-mono text-emerald-400">+${Number(activeSession.current_cash_sales).toFixed(2)}</span>
                </div>
                <div className="pt-2 border-t border-slate-800 flex justify-between font-bold text-sm text-white">
                  <span>Expected in Drawer:</span>
                  <span className="font-mono text-indigo-400">${expected.toFixed(2)}</span>
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                  Counted Cash at Closing ($)
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={closingCounted}
                  onChange={(e) => setClosingCounted(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-700 rounded-2xl px-4 py-3 text-xl font-bold font-mono text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              {/* Discrepancy indicator */}
              <div
                className={`p-3 rounded-xl border text-xs flex items-center justify-between font-bold ${
                  discrepancy === 0
                    ? 'bg-emerald-950/40 border-emerald-900/50 text-emerald-300'
                    : discrepancy > 0
                    ? 'bg-indigo-950/40 border-indigo-900/50 text-indigo-300'
                    : 'bg-rose-950/40 border-rose-900/50 text-rose-300'
                }`}
              >
                <span>Discrepancy:</span>
                <span className="font-mono text-sm">
                  {discrepancy > 0 ? `+$${discrepancy.toFixed(2)} (Overage)` : discrepancy < 0 ? `-$${Math.abs(discrepancy).toFixed(2)} (Shortage)` : '$0.00 (Balanced)'}
                </span>
              </div>

              <button
                type="button"
                onClick={handleCloseShift}
                disabled={isSubmitting}
                className="w-full py-3.5 bg-rose-600 hover:bg-rose-500 active:scale-[0.99] text-white font-bold text-xs rounded-xl shadow-lg transition-all flex items-center justify-center gap-2 cursor-pointer"
              >
                <Lock className="w-4 h-4" />
                <span>Close Cash Register & Finalize Shift</span>
              </button>
            </div>
          ) : (
            /* Open Shift View */
            <div className="space-y-4">
              <div className="p-4 bg-indigo-950/30 border border-indigo-900/40 rounded-2xl text-xs text-indigo-300 flex items-start gap-3">
                <AlertTriangle className="w-5 h-5 text-indigo-400 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="font-semibold text-white">No register session is currently open.</p>
                  <p className="mt-1">Count and enter the initial cash float to begin cashiering.</p>
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                  Opening Cash Float ($)
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={openingFloat}
                  onChange={(e) => setOpeningFloat(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-700 rounded-2xl px-4 py-3 text-xl font-bold font-mono text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              <button
                type="button"
                onClick={handleOpenShift}
                disabled={isSubmitting}
                className="w-full py-3.5 bg-emerald-600 hover:bg-emerald-500 active:scale-[0.99] text-white font-bold text-xs rounded-xl shadow-lg shadow-emerald-600/30 transition-all flex items-center justify-center gap-2 cursor-pointer"
              >
                <CheckCircle className="w-4 h-4" />
                <span>Open Register Shift</span>
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
