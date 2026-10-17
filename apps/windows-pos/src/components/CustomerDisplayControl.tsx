import { useEffect, useState } from 'react';
import type { CustomerDisplayStatus } from '../../electron/customer-display-types';

export function CustomerDisplayControl() {
  const [status, setStatus] = useState<CustomerDisplayStatus | null>(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  useEffect(() => {
    const bridge = window.posApi;
    if (!bridge?.getCustomerDisplayStatus) return;
    let disposed = false;
    const refresh = () => {
      void bridge.getCustomerDisplayStatus().then((value) => {
        if (!disposed) setStatus(value);
      }).catch(() => { if (!disposed) setError('Unable to read customer display status.'); });
    };
    refresh();
    const timer = setInterval(refresh, 3000);
    return () => { disposed = true; clearInterval(timer); };
  }, []);
  if (!window.posApi?.getCustomerDisplayStatus) return null;
  const toggle = async () => {
    if (!status || busy) return;
    setBusy(true); setError('');
    try { setStatus(await window.posApi!.setCustomerDisplayEnabled(!status.enabled)); }
    catch { setError('Unable to save customer display preference.'); }
    finally { setBusy(false); }
  };
  return (
    <section className="border-t border-slate-800 p-4 flex items-center justify-between gap-4">
      <div><h4 className="text-sm font-semibold text-white">Customer display</h4>
        <p className="text-xs text-slate-400 mt-1" role="status">{error || status?.message || 'Checking monitors…'}</p></div>
      <button type="button" disabled={!status || busy} onClick={() => void toggle()}
        className="shrink-0 rounded-lg bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 px-3 py-2 text-xs font-semibold cursor-pointer">
        {busy ? 'Saving…' : status?.enabled ? 'Pause display' : 'Enable display'}
      </button>
    </section>
  );
}
