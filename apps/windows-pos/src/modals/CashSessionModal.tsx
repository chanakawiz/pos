import React, { useState, useEffect } from 'react';
import { usePosStore } from '../stores/usePosStore';
import { api } from '../services/api';
import {
  X,
  DollarSign,
  Lock,
  AlertTriangle,
  CheckCircle,
  Loader2,
  Printer,
  Receipt,
  RotateCcw,
  CreditCard,
  Banknote,
} from 'lucide-react';

export const CashSessionModal: React.FC = () => {
  const { closeModal, setCashSession } = usePosStore();

  const [activeSession, setActiveSession] = useState<any | null>(null);
  const [openingFloat, setOpeningFloat] = useState<string>('150.00');
  const [closingCounted, setClosingCounted] = useState<string>('');
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [isPrintingX, setIsPrintingX] = useState<boolean>(false);
  const [notes, setNotes] = useState<string>('');

  const loadSession = async () => {
    setIsLoading(true);
    try {
      const res = await api.getCurrentCashSession();
      if (res.status === 'open') {
        setActiveSession(res);
        setCashSession(res.session);
        setClosingCounted(res.summary?.expected_cash?.toFixed(2) || '');
      } else {
        setActiveSession(null);
        setCashSession(null);
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

  const handlePrintXReport = async () => {
    setIsPrintingX(true);
    try {
      const res = await api.getXReport();
      if (window.posApi?.printReceipt) {
        window.posApi.printReceipt(res.report);
      } else {
        alert(
          `=== X-REPORT (MID-SHIFT AUDIT) ===\nStore: ${res.report.store_name}\nCashier: ${res.report.cashier_name}\nOpening Float: $${res.report.opening_float}\nCash Sales: $${res.report.cash_sales}\nCard Sales: $${res.report.card_sales}\nRefunds: -$${res.report.refund_total}\nExpected Cash: $${res.report.expected_cash_in_drawer}`
        );
      }
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to generate X-Report');
    } finally {
      setIsPrintingX(false);
    }
  };

  const handleCloseShift = async () => {
    setIsSubmitting(true);
    try {
      const res = await api.closeCashSession({
        closing_balance: parseFloat(closingCounted) || 0,
        notes,
      });

      // Kick drawer for cash counting & print Z-Report
      if (window.posApi?.openCashDrawer) {
        window.posApi.openCashDrawer();
      }
      if (window.posApi?.printReceipt) {
        window.posApi.printReceipt(res.report);
      }

      setCashSession(null);
      alert(`Shift Closed Successfully!\nZ-Report generated with discrepancy: $${res.report.discrepancy}`);
      closeModal();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to close register.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const summary = activeSession?.summary || {};
  const expected = summary.expected_cash ?? 0;
  const counted = parseFloat(closingCounted) || 0;
  const discrepancy = Math.round((counted - expected) * 100) / 100;

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-lg shadow-2xl overflow-hidden flex flex-col animate-in fade-in zoom-in-95 duration-150">
        {/* Header */}
        <div className="p-5 border-b border-slate-800 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-emerald-600/20 text-emerald-400 flex items-center justify-center border border-emerald-500/30">
              <DollarSign className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-base font-bold text-white">Cash Register Audit</h3>
              <p className="text-xs text-slate-400 mt-0.5">Shift reconciliation, X/Z-Reports & drawer controls</p>
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
        <div className="p-6 space-y-5 flex-1 max-h-[75vh] overflow-y-auto">
          {isLoading ? (
            <div className="py-16 flex flex-col items-center justify-center text-slate-400 gap-2">
              <Loader2 className="w-6 h-6 animate-spin text-indigo-500" />
              <span className="text-xs">Loading shift records...</span>
            </div>
          ) : activeSession ? (
            /* Active Shift View with X/Z Reports */
            <div className="space-y-4">
              {/* Financial Metrics Grid */}
              <div className="grid grid-cols-2 gap-2.5">
                <div className="bg-slate-950/60 border border-slate-800 rounded-xl p-3">
                  <span className="text-[11px] text-slate-400">Opening Float</span>
                  <div className="text-base font-bold font-mono text-white mt-0.5">
                    ${Number(summary.opening_float || 0).toFixed(2)}
                  </div>
                </div>

                <div className="bg-slate-950/60 border border-slate-800 rounded-xl p-3">
                  <span className="text-[11px] text-slate-400">Total Transactions</span>
                  <div className="text-base font-bold font-mono text-white mt-0.5">
                    {summary.transaction_count || 0} sales
                  </div>
                </div>

                <div className="bg-slate-950/60 border border-slate-800 rounded-xl p-3">
                  <div className="flex items-center gap-1.5 text-[11px] text-emerald-400">
                    <Banknote className="w-3.5 h-3.5" />
                    <span>Cash Sales</span>
                  </div>
                  <div className="text-base font-bold font-mono text-emerald-400 mt-0.5">
                    +${Number(summary.cash_sales || 0).toFixed(2)}
                  </div>
                </div>

                <div className="bg-slate-950/60 border border-slate-800 rounded-xl p-3">
                  <div className="flex items-center gap-1.5 text-[11px] text-indigo-400">
                    <CreditCard className="w-3.5 h-3.5" />
                    <span>Card Sales</span>
                  </div>
                  <div className="text-base font-bold font-mono text-indigo-300 mt-0.5">
                    +${Number(summary.card_sales || 0).toFixed(2)}
                  </div>
                </div>

                {Number(summary.total_refunds || 0) > 0 && (
                  <div className="bg-slate-950/60 border border-slate-800 rounded-xl p-3 col-span-2">
                    <div className="flex items-center gap-1.5 text-[11px] text-amber-400">
                      <RotateCcw className="w-3.5 h-3.5" />
                      <span>Returns & Refunds</span>
                    </div>
                    <div className="text-base font-bold font-mono text-amber-400 mt-0.5">
                      -${Number(summary.total_refunds).toFixed(2)} ({summary.refund_count || 0} returned)
                    </div>
                  </div>
                )}
              </div>

              {/* Expected Drawer Total */}
              <div className="bg-indigo-950/30 border border-indigo-900/50 rounded-2xl p-4 flex items-center justify-between">
                <div>
                  <span className="text-xs text-indigo-300 font-semibold">Expected Cash in Drawer</span>
                  <p className="text-[10px] text-slate-400 mt-0.5">(Float + Cash Sales - Cash Refunds)</p>
                </div>
                <div className="text-2xl font-black font-mono text-indigo-400">
                  ${Number(expected).toFixed(2)}
                </div>
              </div>

              {/* Mid-Shift Audit Action: Print X-Report */}
              <div className="flex justify-between items-center py-1">
                <span className="text-xs text-slate-400">Mid-Shift Inspection:</span>
                <button
                  onClick={handlePrintXReport}
                  disabled={isPrintingX}
                  className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-semibold rounded-xl border border-slate-700 flex items-center gap-1.5 transition-colors cursor-pointer"
                >
                  {isPrintingX ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Printer className="w-3.5 h-3.5 text-indigo-400" />}
                  <span>Print X-Report (Audit)</span>
                </button>
              </div>

              <div className="pt-2 border-t border-slate-800">
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                  Actual Counted Cash at Closing ($)
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
                className={`p-3.5 rounded-xl border text-xs flex items-center justify-between font-bold ${
                  discrepancy === 0
                    ? 'bg-emerald-950/40 border-emerald-900/50 text-emerald-300'
                    : discrepancy > 0
                    ? 'bg-indigo-950/40 border-indigo-900/50 text-indigo-300'
                    : 'bg-rose-950/40 border-rose-900/50 text-rose-300'
                }`}
              >
                <span>Register Variance:</span>
                <span className="font-mono text-sm">
                  {discrepancy > 0
                    ? `+$${discrepancy.toFixed(2)} (Cash Overage)`
                    : discrepancy < 0
                    ? `-$${Math.abs(discrepancy).toFixed(2)} (Cash Shortage)`
                    : '$0.00 (Perfect Match)'}
                </span>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">Shift Closing Notes</label>
                <input
                  type="text"
                  placeholder="Optional shift comments or variance reason"
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-800 focus:border-indigo-500 rounded-xl px-3.5 py-2 text-xs text-white placeholder-slate-500 outline-none"
                />
              </div>

              <button
                type="button"
                onClick={handleCloseShift}
                disabled={isSubmitting}
                className="w-full py-3.5 bg-gradient-to-r from-rose-600 to-red-600 hover:from-rose-500 hover:to-red-500 active:scale-[0.99] text-white font-bold text-xs rounded-xl shadow-lg transition-all flex items-center justify-center gap-2 cursor-pointer"
              >
                {isSubmitting ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    <span>Closing Shift & Printing Z-Report...</span>
                  </>
                ) : (
                  <>
                    <Lock className="w-4 h-4" />
                    <Receipt className="w-4 h-4" />
                    <span>Close Register & Print Z-Report</span>
                  </>
                )}
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

              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">Shift Opening Notes</label>
                <input
                  type="text"
                  placeholder="e.g. Morning float verified"
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-800 focus:border-indigo-500 rounded-xl px-3.5 py-2 text-xs text-white placeholder-slate-500 outline-none"
                />
              </div>

              <button
                type="button"
                onClick={handleOpenShift}
                disabled={isSubmitting}
                className="w-full py-3.5 bg-emerald-600 hover:bg-emerald-500 active:scale-[0.99] text-white font-bold text-xs rounded-xl shadow-lg shadow-emerald-600/30 transition-all flex items-center justify-center gap-2 cursor-pointer"
              >
                {isSubmitting ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    <span>Opening Register...</span>
                  </>
                ) : (
                  <>
                    <CheckCircle className="w-4 h-4" />
                    <span>Open Register Shift</span>
                  </>
                )}
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
