import { useEffect, useState } from 'react';
import { ArrowUpRight, Diamond, LogOut, PauseCircle, RefreshCw, RotateCcw, ShoppingBag, Wallet, Wifi, WifiOff } from 'lucide-react';
import { useAuthStore } from '../stores/useAuthStore';
import { usePosStore } from '../stores/usePosStore';

export function Header() {
  const { user, logout } = useAuthStore();
  const { activeModal, closeModal, openModal, isOnline, syncStatus, pendingCount, triggerManualSync } = usePosStore();
  const [time, setTime] = useState(() => new Date());
  useEffect(() => { const timer = setInterval(() => setTime(new Date()), 30000); return () => clearInterval(timer); }, []);
  return (
    <header className="station-header">
      <div className="station-brand"><Diamond aria-hidden="true" /><div><strong>SmartShop<span> Retail</span></strong><small>{user?.store?.name || 'Retail station'}</small></div></div>
      <nav className="station-nav" aria-label="Register navigation">
        <button type="button" className={!activeModal || ['payment', 'receipt', 'weighing', 'customer'].includes(activeModal) ? 'is-active' : ''} onClick={closeModal}><ShoppingBag />Sell</button>
        <button type="button" className={activeModal === 'hold' ? 'is-active' : ''} onClick={() => openModal('hold')}><PauseCircle />Held bills</button>
        <button type="button" className={activeModal === 'cashSession' ? 'is-active' : ''} onClick={() => openModal('cashSession')}><Wallet />Register</button>
        <button type="button" title="Sales Returns & Refunds (F3)" className={activeModal === 'refund' ? 'is-active' : ''} onClick={() => openModal('refund')}><RotateCcw />Returns</button>
      </nav>
      <div className="station-tools">
        <time className="station-clock">{time.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</time>
        <div className="connection-tools">
          <button type="button" className={`connection-state ${isOnline ? 'online' : 'offline'}`} onClick={() => openModal('syncStatus')} title="Offline & Sync Diagnostics">{isOnline ? <Wifi /> : <WifiOff />}<span>{isOnline ? 'Online' : 'Offline'}</span></button>
          <button type="button" className="sync-trigger" title="Trigger Immediate Sync" aria-label={`Sync now${pendingCount ? `, ${pendingCount} pending` : ''}`} disabled={syncStatus === 'syncing'} onClick={() => void triggerManualSync()}><RefreshCw className={syncStatus === 'syncing' ? 'animate-spin' : ''} />{pendingCount > 0 && <span>{pendingCount}</span>}</button>
        </div>
        <div className="cashier-profile"><span className="cashier-avatar">{user?.name?.charAt(0) || 'S'}</span><div><strong>{user?.name || 'Cashier'}</strong><small>{user?.role?.replaceAll('_', ' ') || 'Cashier'}</small></div></div>
        <button type="button" className="icon-button logout-button" onClick={() => void logout()} title="Logout Cashier" aria-label="Sign out"><LogOut /></button>
      </div>
      <ArrowUpRight className="hidden" aria-hidden="true" />
    </header>
  );
}
