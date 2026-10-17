import React, { useState } from 'react';
import { usePosStore } from '../stores/usePosStore';
import { api } from '../services/api';
import type { RefundReceipt } from '../types/pos';
import { openCashDrawer } from '../services/hardware';
import { X, RotateCcw, Search, AlertCircle, CheckCircle2, Printer, Loader2, PackageCheck } from 'lucide-react';

interface SelectedRefundItem {
  id: number;
  uuid: string;
  name: string;
  maxQty: number;
  returnQty: number;
  unitPrice: number;
  lineTotal: number;
}

export const RefundModal: React.FC = () => {
  const { closeModal } = usePosStore();

  const [invoiceQuery, setInvoiceQuery] = useState<string>('');
  const [isSearching, setIsSearching] = useState<boolean>(false);
  const [saleData, setSaleData] = useState<any | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  // Refund configuration
  const [selectedItems, setSelectedItems] = useState<{ [id: number]: SelectedRefundItem }>({});
  const [reason, setReason] = useState<string>('Customer changed mind');
  const [restock, setRestock] = useState<boolean>(true);
  const [isProcessing, setIsProcessing] = useState<boolean>(false);
  const [isPrinting, setIsPrinting] = useState(false);
  const [completedRefund, setCompletedRefund] = useState<{ refund: any; receipt: RefundReceipt } | null>(null);

  const handleSearchSale = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!invoiceQuery.trim()) return;

    setIsSearching(true);
    setErrorMsg(null);
    setSaleData(null);
    setSelectedItems({});

    try {
      const res = await api.getSale(invoiceQuery.trim());
      const sale = res.sale || res.data;
      if (sale) {
        setSaleData({ ...sale, items: sale.items.map((item: any) => ({
          ...item, product_name: item.product_name || item.product?.name || 'Item',
        })) });
      } else {
        setErrorMsg('Sale invoice not found');
      }
    } catch (err: any) {
      setErrorMsg(err.response?.data?.message || 'Invoice not found. Please verify the invoice number.');
    } finally {
      setIsSearching(false);
    }
  };

  const toggleItemSelection = (item: any) => {
    const itemId = item.id;
    if (selectedItems[itemId]) {
      const next = { ...selectedItems };
      delete next[itemId];
      setSelectedItems(next);
    } else {
      const unitPrice = item.total / item.quantity;
      setSelectedItems({
        ...selectedItems,
        [itemId]: {
          id: item.id,
          uuid: item.uuid,
          name: item.product_name,
          maxQty: item.quantity,
          returnQty: 1,
          unitPrice,
          lineTotal: unitPrice,
        },
      });
    }
  };

  const updateItemQty = (itemId: number, newQty: number) => {
    const existing = selectedItems[itemId];
    if (!existing) return;

    const clampedQty = Math.max(1, Math.min(newQty, existing.maxQty));
    setSelectedItems({
      ...selectedItems,
      [itemId]: {
        ...existing,
        returnQty: clampedQty,
        lineTotal: clampedQty * existing.unitPrice,
      },
    });
  };

  const totalRefundAmount = Object.values(selectedItems).reduce((sum, item) => sum + item.lineTotal, 0);

  const handleProcessRefund = async () => {
    const itemsToRefund = Object.values(selectedItems).map((i) => ({
      sale_item_id: i.id,
      quantity: i.returnQty,
    }));

    if (itemsToRefund.length === 0) {
      setErrorMsg('Please select at least one item to return');
      return;
    }

    setIsProcessing(true);
    setErrorMsg(null);

    try {
      const res = await api.processRefund(saleData.uuid, {
        items: itemsToRefund,
        reason,
        restock,
      });

      setCompletedRefund(res);

      // Hardware kickout cash drawer
      if (window.posApi) void openCashDrawer();
    } catch (err: any) {
      setErrorMsg(err.response?.data?.message || 'Failed to process refund');
    } finally {
      setIsProcessing(false);
    }
  };

  const handlePrintReceipt = async () => {
    if (!completedRefund || isPrinting) return;
    setIsPrinting(true);
    try {
      if (!window.posApi) { setErrorMsg('Refund receipt printing requires the desktop app.'); return; }
      const result = await window.posApi.printReceipt({ kind: 'refund', receipt: completedRefund.receipt });
      if (!result.success) setErrorMsg(result.message);
      else setErrorMsg(null);
    } catch { setErrorMsg('Receipt printing was not confirmed. Check the printer before retrying.'); }
    finally { setIsPrinting(false); }
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-2xl shadow-2xl overflow-hidden flex flex-col animate-in fade-in zoom-in-95 duration-150">
        {/* Header */}
        <div className="p-5 border-b border-slate-800 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-amber-600/20 text-amber-400 flex items-center justify-center border border-amber-500/30">
              <RotateCcw className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-base font-bold text-white">Sales Returns & Refunds</h3>
              <p className="text-xs text-slate-400 mt-0.5">Return items, restock inventory, and issue customer refund</p>
            </div>
          </div>
          <button
            onClick={closeModal}
            className="p-1.5 text-slate-400 hover:text-white hover:bg-slate-800 rounded-lg transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content Area */}
        <div className="p-6 flex-1 max-h-[70vh] overflow-y-auto space-y-5">
          {errorMsg && (
            <div className="p-3.5 rounded-xl bg-rose-500/10 border border-rose-500/30 text-rose-400 text-xs flex items-center gap-2">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{errorMsg}</span>
            </div>
          )}

          {completedRefund ? (
            /* Refund Success Screen */
            <div className="text-center py-6 space-y-4">
              <div className="w-16 h-16 rounded-full bg-emerald-500/20 text-emerald-400 flex items-center justify-center mx-auto border border-emerald-500/30">
                <CheckCircle2 className="w-8 h-8" />
              </div>
              <div>
                <h4 className="text-lg font-bold text-white">Refund Completed Successfully</h4>
                <p className="text-xs text-slate-400 mt-1 font-mono">
                  Refund Ref: {completedRefund.receipt.refund_number}
                </p>
              </div>

              <div className="bg-slate-950/60 border border-slate-800 rounded-2xl p-4 max-w-sm mx-auto text-left space-y-2 text-xs">
                <div className="flex justify-between text-slate-400">
                  <span>Original Invoice:</span>
                  <span className="font-mono text-white">{completedRefund.receipt.invoice_number}</span>
                </div>
                <div className="flex justify-between text-slate-400">
                  <span>Amount Refunded:</span>
                  <span className="font-mono text-emerald-400 font-bold">
                    ${Number(completedRefund.receipt.total_refunded).toFixed(2)}
                  </span>
                </div>
                <div className="flex justify-between text-slate-400">
                  <span>Reason:</span>
                  <span className="text-white">{completedRefund.receipt.reason}</span>
                </div>
              </div>

              <div className="flex justify-center gap-3 pt-2">
                <button
                  onClick={handlePrintReceipt}
                  disabled={isPrinting}
                  className="px-5 py-2.5 bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold rounded-xl shadow-md transition-all flex items-center gap-2 cursor-pointer"
                >
                  <Printer className="w-4 h-4" />
                  <span>Print Refund Receipt</span>
                </button>
                <button
                  onClick={closeModal}
                  className="px-5 py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-semibold rounded-xl transition-colors cursor-pointer"
                >
                  Done
                </button>
              </div>
            </div>
          ) : (
            <>
              {/* Invoice Lookup Form */}
              <form onSubmit={handleSearchSale} className="flex gap-2">
                <div className="relative flex-1">
                  <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    placeholder="Enter or scan Invoice Number (e.g. INV-DWT-2026...)"
                    value={invoiceQuery}
                    onChange={(e) => setInvoiceQuery(e.target.value)}
                    autoFocus
                    className="w-full bg-slate-950 border border-slate-800 focus:border-indigo-500 rounded-xl pl-10 pr-4 py-2.5 text-xs text-white placeholder-slate-500 outline-none transition-all font-mono"
                  />
                </div>
                <button
                  type="submit"
                  disabled={isSearching || !invoiceQuery.trim()}
                  className="px-5 py-2.5 bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 text-white text-xs font-bold rounded-xl shadow-md transition-all flex items-center gap-1.5 cursor-pointer"
                >
                  {isSearching ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Find Invoice'}
                </button>
              </form>

              {/* Sale Details & Item Selection */}
              {saleData && (
                <div className="space-y-4 pt-2">
                  <div className="bg-slate-950/60 border border-slate-800 rounded-2xl p-4 flex items-center justify-between text-xs">
                    <div>
                      <span className="font-mono font-bold text-white text-sm">{saleData.invoice_number}</span>
                      <p className="text-[11px] text-slate-400 mt-0.5">
                        Sold on {new Date(saleData.sold_at).toLocaleString()} • Cashier: {saleData.cashier?.name}
                      </p>
                    </div>
                    <div className="text-right">
                      <span className="font-mono text-emerald-400 font-bold text-sm">
                        ${Number(saleData.total_amount).toFixed(2)}
                      </span>
                      <p className="text-[10px] text-slate-400 uppercase tracking-wider">
                        Status: {saleData.payment_status}
                      </p>
                    </div>
                  </div>

                  {/* Items List */}
                  <div>
                    <h4 className="text-xs font-semibold text-slate-300 mb-2">Select Items to Return</h4>
                    <div className="space-y-2">
                      {saleData.items.map((item: any) => {
                        const isSelected = !!selectedItems[item.id];
                        const current = selectedItems[item.id];
                        return (
                          <div
                            key={item.id}
                            onClick={() => toggleItemSelection(item)}
                            className={`p-3.5 rounded-2xl border transition-all cursor-pointer flex items-center justify-between gap-4 ${
                              isSelected
                                ? 'bg-amber-950/20 border-amber-500/50'
                                : 'bg-slate-950/40 border-slate-800 hover:border-slate-700'
                            }`}
                          >
                            <div className="flex items-center gap-3">
                              <input
                                type="checkbox"
                                checked={isSelected}
                                onChange={() => {}}
                                className="w-4 h-4 accent-amber-500 rounded cursor-pointer"
                              />
                              <div>
                                <h5 className="text-xs font-bold text-white">{item.product_name}</h5>
                                <p className="text-[11px] text-slate-400 font-mono">
                                  ${(item.total / item.quantity).toFixed(2)} ea • Purchased: {item.quantity}
                                </p>
                              </div>
                            </div>

                            {isSelected && (
                              <div
                                onClick={(e) => e.stopPropagation()}
                                className="flex items-center gap-3"
                              >
                                <div className="flex items-center gap-2 bg-slate-900 px-2 py-1 rounded-lg border border-slate-800">
                                  <span className="text-[10px] text-slate-400">Qty:</span>
                                  <input
                                    type="number"
                                    min={1}
                                    max={current.maxQty}
                                    value={current.returnQty}
                                    onChange={(e) => updateItemQty(item.id, parseInt(e.target.value, 10) || 1)}
                                    className="w-12 bg-slate-950 border border-slate-700 rounded px-1.5 py-0.5 text-xs text-white text-center font-mono outline-none"
                                  />
                                </div>
                                <span className="font-mono font-bold text-amber-400 text-xs w-16 text-right">
                                  ${current.lineTotal.toFixed(2)}
                                </span>
                              </div>
                            )}
                          </div>
                        );
                      })}
                    </div>
                  </div>

                  {/* Return Reasons & Restock */}
                  <div className="grid grid-cols-2 gap-4 pt-2">
                    <div>
                      <label className="block text-xs font-semibold text-slate-300 mb-1">Return Reason</label>
                      <select
                        value={reason}
                        onChange={(e) => setReason(e.target.value)}
                        className="w-full bg-slate-950 border border-slate-800 focus:border-indigo-500 rounded-xl px-3 py-2 text-xs text-white outline-none"
                      >
                        <option value="Customer changed mind">Customer changed mind</option>
                        <option value="Defective / Damaged product">Defective / Damaged product</option>
                        <option value="Incorrect item purchased">Incorrect item purchased</option>
                        <option value="Expired date">Expired date</option>
                        <option value="Exchange for alternative">Exchange for alternative</option>
                      </select>
                    </div>

                    <div className="flex items-end pb-1">
                      <label className="flex items-center gap-2 text-xs text-slate-300 cursor-pointer select-none">
                        <input
                          type="checkbox"
                          checked={restock}
                          onChange={(e) => setRestock(e.target.checked)}
                          className="w-4 h-4 accent-indigo-500 rounded cursor-pointer"
                        />
                        <span className="flex items-center gap-1.5">
                          <PackageCheck className="w-4 h-4 text-emerald-400" />
                          Restock items to store inventory
                        </span>
                      </label>
                    </div>
                  </div>

                  {/* Summary & Process Button */}
                  <div className="pt-4 border-t border-slate-800 flex items-center justify-between">
                    <div>
                      <span className="text-xs text-slate-400">Total Refund Amount:</span>
                      <div className="text-2xl font-black font-mono text-amber-400">
                        ${totalRefundAmount.toFixed(2)}
                      </div>
                    </div>

                    <button
                      onClick={handleProcessRefund}
                      disabled={isProcessing || totalRefundAmount <= 0}
                      className="px-6 py-3 bg-gradient-to-r from-amber-600 to-orange-500 hover:from-amber-500 hover:to-orange-400 disabled:opacity-50 text-white font-bold text-xs rounded-xl shadow-lg shadow-amber-600/30 flex items-center gap-2 transition-all cursor-pointer"
                    >
                      {isProcessing ? (
                        <>
                          <Loader2 className="w-4 h-4 animate-spin" />
                          <span>Processing...</span>
                        </>
                      ) : (
                        <>
                          <RotateCcw className="w-4 h-4" />
                          <span>Confirm & Process Refund</span>
                        </>
                      )}
                    </button>
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
};
