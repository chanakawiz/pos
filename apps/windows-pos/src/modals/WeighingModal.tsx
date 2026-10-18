import { useEffect, useRef, useState } from 'react';
import type { Product } from '../types/pos';
import type { ScaleStatus } from '../../electron/scale-types';
import { quantityFromWeight, weightUnit } from '../../electron/quantity';
import { useCartStore } from '../stores/useCartStore';
import { usePosStore } from '../stores/usePosStore';
import { useAuthStore } from '../stores/useAuthStore';

export function WeighingModal({ product }: { product: Product }) {
  const [status, setStatus] = useState<ScaleStatus | null>(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const locked = useRef(false);
  const alive = useRef(true);
  const unit = weightUnit(product.unit);
  useEffect(() => {
    alive.current = true;
    const bridge = window.posApi;
    let pending = false;
    const refresh = async () => {
      if (pending || !bridge?.getScaleStatus) return;
      pending = true;
      try { const next = await bridge.getScaleStatus(); if (alive.current) setStatus(next); }
      catch { if (alive.current) setError('Unable to read scale status.'); }
      finally { pending = false; }
    };
    void bridge?.connectScale().then(() => refresh()).catch(() => {
      if (alive.current) setError('Unable to connect to the scale.');
    });
    const timer = setInterval(() => void refresh(), 200);
    return () => { alive.current = false; clearInterval(timer); void bridge?.disconnectScale().catch(() => {}); };
  }, []);
  let quantity: number | null = null;
  if (unit && status?.state === 'stable' && status.reading) {
    try { quantity = quantityFromWeight(status.reading.value, status.reading.unit, unit); }
    catch { /* The product quantity cannot represent this resolution; capture stays disabled. */ }
  }
  const capture = async () => {
    if (locked.current || !unit || !status?.reading || quantity === null || !window.posApi) return;
    locked.current = true; setBusy(true); setError('');
    try {
      const captured = await window.posApi.captureScaleWeight(status.reading.revision, unit);
      const pos = usePosStore.getState();
      if (!alive.current || !useAuthStore.getState().token || pos.activeModal !== 'weighing' || pos.weighingProduct?.id !== product.id) return;
      if (pos.replaceWeight) useCartStore.getState().updateQuantity(product.id, captured);
      else useCartStore.getState().addItem(product, captured);
      pos.closeModal();
    } catch (error) {
      if (alive.current) setError(error instanceof Error ? error.message : 'Unable to capture weight.');
    } finally { locked.current = false; if (alive.current) setBusy(false); }
  };
  const reconnect = async () => {
    if (busy || !window.posApi) return;
    setBusy(true); setError('');
    try { await window.posApi.disconnectScale(); const next = await window.posApi.connectScale(); if (alive.current) setStatus(next); }
    catch { if (alive.current) setError('Unable to reconnect scale.'); }
    finally { if (alive.current) setBusy(false); }
  };
  return (
    <div className="fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4">
      <section role="dialog" aria-modal="true" aria-labelledby="weighing-title" className="w-full max-w-lg rounded-3xl border border-slate-700 bg-slate-900 p-6 shadow-2xl">
        <h2 id="weighing-title" className="text-xl font-bold text-white">Weigh product</h2>
        <p className="text-slate-300 mt-2">{product.name} · {Number(product.selling_price).toFixed(2)} / {unit}</p>
        <p className="text-sm text-slate-400 mt-3">Place the product on the scale. Check its unit and tare, then capture a stable weight.</p>
        <div className="my-5 rounded-2xl border border-slate-700 bg-slate-950 p-5">
          <p className="text-4xl text-emerald-400 font-mono font-bold" data-testid="scale-weight">{quantity === null ? '—' : quantity.toFixed(3)} {unit}</p>
          <p role="status" className="text-sm text-slate-300 mt-3">{status?.message || (window.posApi ? 'Connecting…' : 'Weighing requires the desktop terminal.')}</p>
          {status?.state === 'stable' && quantity === null && <p className="text-amber-300 text-sm mt-2">This weight cannot be represented to three decimal places in {unit}.</p>}
        </div>
        {error && <p role="alert" className="text-sm text-rose-300 mb-4">{error}</p>}
        <div className="flex justify-between gap-3">
          <button type="button" disabled={busy} onClick={() => usePosStore.getState().closeModal()} className="rounded-xl bg-slate-800 px-4 py-3 text-sm cursor-pointer">Cancel weighing</button>
          <button type="button" disabled={busy || !window.posApi} onClick={() => void reconnect()} className="rounded-xl bg-slate-800 px-4 py-3 text-sm cursor-pointer">Reconnect scale</button>
          <button type="button" disabled={busy || quantity === null} onClick={() => void capture()} className="rounded-xl bg-emerald-600 disabled:opacity-40 px-4 py-3 text-sm font-semibold cursor-pointer">{busy ? 'Capturing…' : 'Capture weight'}</button>
        </div>
      </section>
    </div>
  );
}
