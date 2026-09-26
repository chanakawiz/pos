import React, { useEffect, useState } from 'react';
import { Wifi, WifiOff, RefreshCw, LogOut, Store, User, Clock, CheckCircle2, RotateCcw } from 'lucide-react';
import { useAuthStore } from '../stores/useAuthStore';
import { usePosStore } from '../stores/usePosStore';

export const Header: React.FC = () => {
  const { user, logout } = useAuthStore();
  const { isOnline, syncStatus, pendingCount, triggerManualSync, openModal } = usePosStore();
  const [time, setTime] = useState(new Date().toLocaleTimeString());

  useEffect(() => {
    const timer = setInterval(() => setTime(new Date().toLocaleTimeString()), 1000);
    return () => clearInterval(timer);
  }, []);

  return (
    <header className="h-16 bg-slate-900/90 backdrop-blur-md border-b border-slate-800 px-6 flex items-center justify-between text-white select-none z-10">
      {/* Left: Brand & Store */}
      <div className="flex items-center gap-4">
        <div className="flex items-center gap-2 bg-indigo-600/20 text-indigo-400 px-3 py-1.5 rounded-lg border border-indigo-500/30">
          <Store className="w-5 h-5 text-indigo-400" />
          <span className="font-bold tracking-wide text-white">SmartShop POS</span>
        </div>
        <div className="hidden md:flex items-center gap-2 text-sm text-slate-400">
          <span className="text-slate-600">|</span>
          <span>{user?.store?.name || 'Main Downtown Store'}</span>
          <span className="bg-slate-800 text-xs px-2 py-0.5 rounded text-slate-300">
            {user?.store?.currency_symbol || '$'} USD
          </span>
        </div>
      </div>

      {/* Center: System Clock & Shift Register */}
      <div className="flex items-center gap-4">
        <div className="flex items-center gap-1.5 text-slate-400 text-sm font-mono bg-slate-950/60 px-3 py-1 rounded-md border border-slate-800">
          <Clock className="w-4 h-4 text-indigo-400" />
          <span>{time}</span>
        </div>
        <button
          onClick={() => openModal('cashSession')}
          className="flex items-center gap-1.5 text-xs font-semibold px-3 py-1.5 bg-emerald-500/10 text-emerald-400 hover:bg-emerald-500/20 border border-emerald-500/30 rounded-lg transition-colors cursor-pointer"
        >
          <CheckCircle2 className="w-4 h-4" />
          <span>Register</span>
        </button>

        <button
          onClick={() => openModal('refund')}
          title="Sales Returns & Refunds (F3)"
          className="flex items-center gap-1.5 text-xs font-semibold px-3 py-1.5 bg-amber-500/10 text-amber-400 hover:bg-amber-500/20 border border-amber-500/30 rounded-lg transition-colors cursor-pointer"
        >
          <RotateCcw className="w-4 h-4" />
          <span>Returns (F3)</span>
        </button>
      </div>

      {/* Right: Sync Status, Network & Cashier Profile */}
      <div className="flex items-center gap-4">
        {/* Network & Sync indicator */}
        <div
          onClick={() => openModal('syncStatus')}
          title="Click to view Offline & Sync Diagnostics"
          className="flex items-center gap-2 bg-slate-950/80 hover:bg-slate-800/80 cursor-pointer px-3 py-1.5 rounded-lg border border-slate-800 transition-colors"
        >
          {isOnline ? (
            <div className="flex items-center gap-1.5 text-xs text-emerald-400">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
              <Wifi className="w-4 h-4" />
              <span className="hidden sm:inline">Online</span>
            </div>
          ) : (
            <div className="flex items-center gap-1.5 text-xs text-rose-400">
              <span className="w-2 h-2 rounded-full bg-rose-500" />
              <WifiOff className="w-4 h-4" />
              <span className="hidden sm:inline">Offline</span>
            </div>
          )}

          <div className="h-4 w-px bg-slate-800" />

          {/* Sync status & Manual trigger */}
          <button
            onClick={(e) => {
              e.stopPropagation();
              triggerManualSync();
            }}
            disabled={syncStatus === 'syncing'}
            title="Trigger Immediate Sync"
            className="flex items-center gap-1.5 text-xs text-slate-300 hover:text-white transition-colors cursor-pointer"
          >
            <RefreshCw className={`w-3.5 h-3.5 text-indigo-400 ${syncStatus === 'syncing' ? 'animate-spin' : ''}`} />
            {pendingCount > 0 ? (
              <span className="bg-amber-500 text-slate-950 font-bold px-1.5 py-0.2 rounded-full text-[10px]">
                {pendingCount}
              </span>
            ) : (
              <span className="text-[11px] text-slate-400">Synced</span>
            )}
          </button>
        </div>

        {/* Cashier Info */}
        <div className="flex items-center gap-3 pl-2 border-l border-slate-800">
          <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-indigo-600 to-violet-500 flex items-center justify-center font-bold text-sm shadow-md">
            <User className="w-4 h-4 text-white" />
          </div>
          <div className="hidden lg:block text-left">
            <div className="text-xs font-semibold text-white leading-tight">{user?.name || 'Cashier'}</div>
            <div className="text-[10px] text-slate-400 uppercase tracking-wider">{user?.role || 'cashier'}</div>
          </div>
          <button
            onClick={logout}
            title="Logout Cashier"
            className="p-1.5 text-slate-400 hover:text-rose-400 hover:bg-slate-800/80 rounded-lg transition-colors ml-1"
          >
            <LogOut className="w-4 h-4" />
          </button>
        </div>
      </div>
    </header>
  );
};
