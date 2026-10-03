import React, { useState, useEffect } from 'react';
import { useCartStore } from '../stores/useCartStore';
import { usePosStore } from '../stores/usePosStore';
import { api } from '../services/api';
import { X, Play, Clock, ShoppingBag, Trash2, RefreshCw, User, Cloud } from 'lucide-react';

interface CloudHeldBill {
  uuid: string;
  hold_reference: string;
  cashier_name: string;
  customer_name?: string | null;
  customer_phone?: string | null;
  items_count: number;
  subtotal: number;
  held_at: string;
  cart_items_json: any[];
}

export const HoldBillsModal: React.FC = () => {
  const { heldBills, restoreHeldBill, restoreCartItems, removeHeldBill } = useCartStore();
  const { closeModal } = usePosStore();

  const [cloudBills, setCloudBills] = useState<CloudHeldBill[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [resumingId, setResumingId] = useState<string | null>(null);

  const fetchCloudBills = async () => {
    setIsLoading(true);
    try {
      const res = await api.getHeldBills();
      if (res.status === 'success' && Array.isArray(res.data)) {
        setCloudBills(res.data);
      }
    } catch (err) {
      console.warn('Could not fetch cloud held bills:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchCloudBills();
  }, []);

  const handleResumeLocal = (id: string) => {
    restoreHeldBill(id);
    closeModal();
  };

  const handleResumeCloud = async (bill: CloudHeldBill) => {
    setResumingId(bill.uuid);
    try {
      // 1. Restore items to cart
      restoreCartItems(bill.cart_items_json || [], 0, null);

      // 2. Remove held bill from backend so another lane doesn't resume it
      await api.deleteHeldBill(bill.uuid);

      closeModal();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to resume cloud held bill');
    } finally {
      setResumingId(null);
    }
  };

  const handleDiscardCloud = async (uuid: string) => {
    if (!confirm('Discard this held bill?')) return;
    try {
      await api.deleteHeldBill(uuid);
      setCloudBills((prev) => prev.filter((b) => b.uuid !== uuid));
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to discard held bill');
    }
  };

  const totalHeldCount = cloudBills.length + heldBills.length;

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-2xl shadow-2xl overflow-hidden flex flex-col animate-in fade-in zoom-in-95 duration-150">
        {/* Header */}
        <div className="p-5 border-b border-slate-800 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center text-amber-400">
              <ShoppingBag className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-base font-bold text-white">Held Transactions</h3>
                <span className="text-xs px-2 py-0.5 rounded-full bg-slate-800 text-slate-300 font-mono font-medium">
                  {totalHeldCount} Active
                </span>
              </div>
              <p className="text-xs text-slate-400 mt-0.5">Resume customer carts across store checkout lanes</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={fetchCloudBills}
              disabled={isLoading}
              className="p-2 text-slate-400 hover:text-white hover:bg-slate-800 rounded-xl transition-colors cursor-pointer"
              title="Refresh held bills"
            >
              <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin text-indigo-400' : ''}`} />
            </button>
            <button
              onClick={closeModal}
              className="p-2 text-slate-400 hover:text-white hover:bg-slate-800 rounded-xl transition-colors cursor-pointer"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* List of Held Bills */}
        <div className="p-5 space-y-3 max-h-[60vh] overflow-y-auto">
          {totalHeldCount === 0 && !isLoading ? (
            <div className="py-16 text-center text-slate-500">
              <ShoppingBag className="w-12 h-12 mx-auto mb-3 opacity-30 text-slate-400" />
              <p className="text-sm font-medium text-slate-400">No bills currently on hold</p>
              <p className="text-xs text-slate-500 mt-1">Press Hold (F4) in cart to hold an active customer bill</p>
            </div>
          ) : (
            <>
              {/* Cloud-Synced Bills (Shared with other lanes) */}
              {cloudBills.map((bill) => (
                <div
                  key={bill.uuid}
                  className="bg-slate-950/70 border border-slate-800 hover:border-slate-700 rounded-2xl p-4 flex items-center justify-between gap-4 transition-all hover:shadow-lg"
                >
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2 mb-1.5 flex-wrap">
                      <span className="font-mono text-xs font-bold text-white bg-slate-800/80 px-2 py-0.5 rounded-lg border border-slate-700/60">
                        {bill.hold_reference}
                      </span>
                      <span className="flex items-center gap-1 text-[11px] text-indigo-300 bg-indigo-950/60 px-2 py-0.5 rounded-lg border border-indigo-900/50">
                        <Cloud className="w-3 h-3 text-indigo-400" />
                        Multi-Lane
                      </span>
                      <span className="flex items-center gap-1 text-[11px] text-slate-400">
                        <Clock className="w-3 h-3 text-slate-500" />
                        {new Date(bill.held_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </span>
                    </div>

                    <div className="text-xs text-slate-300 flex items-center gap-3">
                      <span className="flex items-center gap-1 text-slate-400">
                        <User className="w-3 h-3 text-slate-500" />
                        {bill.cashier_name}
                      </span>
                      <span>•</span>
                      <span>
                        {bill.items_count} {bill.items_count === 1 ? 'item' : 'items'}
                      </span>
                      {bill.customer_name && (
                        <>
                          <span>•</span>
                          <span className="text-emerald-400 font-medium">{bill.customer_name}</span>
                        </>
                      )}
                    </div>
                  </div>

                  <div className="text-right flex items-center gap-3">
                    <div className="font-mono font-bold text-emerald-400 text-base">
                      ${bill.subtotal.toFixed(2)}
                    </div>
                    <button
                      onClick={() => handleResumeCloud(bill)}
                      disabled={resumingId === bill.uuid}
                      className="flex items-center gap-1.5 px-3.5 py-2 bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 text-white text-xs font-bold rounded-xl shadow-md shadow-indigo-600/20 transition-all cursor-pointer"
                    >
                      <Play className="w-3.5 h-3.5 fill-current" />
                      <span>{resumingId === bill.uuid ? 'Resuming...' : 'Resume'}</span>
                    </button>
                    <button
                      onClick={() => handleDiscardCloud(bill.uuid)}
                      className="p-2 text-slate-500 hover:text-rose-400 hover:bg-slate-800/80 rounded-xl transition-colors cursor-pointer"
                      title="Discard held bill"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              ))}

              {/* Local In-Memory Bills */}
              {heldBills.map((bill) => (
                <div
                  key={bill.id}
                  className="bg-slate-950/60 border border-slate-800 hover:border-slate-700 rounded-2xl p-4 flex items-center justify-between gap-4 transition-all"
                >
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2 mb-1.5">
                      <span className="font-mono text-xs font-bold text-white bg-slate-800/80 px-2 py-0.5 rounded-lg border border-slate-700/60">
                        {bill.id}
                      </span>
                      <span className="text-[11px] text-amber-300 bg-amber-950/60 px-2 py-0.5 rounded-lg border border-amber-900/50">
                        Local
                      </span>
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
                    <div className="font-mono font-bold text-emerald-400 text-base">
                      ${bill.subtotal.toFixed(2)}
                    </div>
                    <button
                      onClick={() => handleResumeLocal(bill.id)}
                      className="flex items-center gap-1.5 px-3.5 py-2 bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold rounded-xl shadow-md transition-colors cursor-pointer"
                    >
                      <Play className="w-3.5 h-3.5 fill-current" />
                      <span>Resume</span>
                    </button>
                    <button
                      onClick={() => removeHeldBill(bill.id)}
                      className="p-2 text-slate-500 hover:text-rose-400 hover:bg-slate-800/80 rounded-xl transition-colors cursor-pointer"
                      title="Discard held bill"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              ))}
            </>
          )}
        </div>
      </div>
    </div>
  );
};
