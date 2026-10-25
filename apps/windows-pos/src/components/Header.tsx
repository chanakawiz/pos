import React, { useEffect, useState } from 'react';
import { Wifi, WifiOff, RefreshCw, LogOut, Store, User, Clock, CheckCircle2, RotateCcw, Keyboard } from 'lucide-react';
import { useAuthStore } from '../stores/useAuthStore';
import { usePosStore } from '../stores/usePosStore';

export const Header: React.FC = () => {
  const { user, logout } = useAuthStore();
  const { isOnline, syncStatus, pendingCount, triggerManualSync, openModal, language, setLanguage } = usePosStore();
  const [time, setTime] = useState(new Date().toLocaleTimeString());

  useEffect(() => {
    const timer = setInterval(() => setTime(new Date().toLocaleTimeString()), 1000);
    return () => clearInterval(timer);
  }, []);

  return (
    <header className="h-16 bg-slate-900/95 backdrop-blur-md border-b border-slate-800 px-5 flex items-center justify-between text-white select-none z-10 shrink-0">
      {/* Left: Brand & Store Station */}
      <div className="flex items-center gap-3">
        <div className="flex items-center gap-2.5 bg-gradient-to-r from-indigo-600/30 to-violet-600/20 text-indigo-400 px-3.5 py-1.5 rounded-xl border border-indigo-500/30 shadow-sm">
          <Store className="w-5 h-5 text-indigo-400 shrink-0" />
          <div className="flex flex-col">
            <span className="font-extrabold tracking-tight text-white text-sm leading-tight">SmartShop POS</span>
            <span className="text-[10px] text-indigo-300/80 font-medium leading-none">Counter Lane 01</span>
          </div>
        </div>
        <div className="hidden md:flex items-center gap-2 text-xs text-slate-400">
          <span className="text-slate-700">|</span>
          <span className="font-medium text-slate-300">{user?.store?.name || 'OmniLuxe Store Flagship'}</span>
          <span className="bg-slate-800 text-[10px] px-2 py-0.5 rounded-full font-mono text-slate-300 border border-slate-700">
            {user?.store?.currency_symbol || '$'} {user?.store?.currency_code || 'USD'}
          </span>
        </div>
      </div>

      {/* Center: System Clock & Shift / Hardware Quick Tools */}
      <div className="flex items-center gap-2.5">
        <div className="flex items-center gap-1.5 text-slate-300 text-xs font-mono bg-slate-950/80 px-3 py-1.5 rounded-xl border border-slate-800/80 shadow-inner">
          <Clock className="w-3.5 h-3.5 text-indigo-400" />
          <span>{time}</span>
        </div>

        <button
          type="button"
          onClick={() => openModal('cashSession')}
          className="flex items-center gap-1.5 text-xs font-semibold px-3 py-1.5 bg-emerald-500/10 text-emerald-400 hover:bg-emerald-500/20 border border-emerald-500/30 rounded-xl transition-all cursor-pointer shadow-sm active:scale-95"
          title="Register & Cash Drawer Session"
        >
          <CheckCircle2 className="w-3.5 h-3.5" />
          <span>Register</span>
        </button>

        <button
          type="button"
          onClick={() => openModal('refund')}
          title="Sales Returns & Refunds (F3)"
          className="flex items-center gap-1.5 text-xs font-semibold px-3 py-1.5 bg-amber-500/10 text-amber-400 hover:bg-amber-500/20 border border-amber-500/30 rounded-xl transition-all cursor-pointer shadow-sm active:scale-95"
        >
          <RotateCcw className="w-3.5 h-3.5" />
          <span>Returns (F3)</span>
        </button>

        <button
          type="button"
          onClick={() => openModal('help')}
          title="Help (F1)"
          className="flex items-center gap-1.5 text-xs font-semibold px-3 py-1.5 bg-indigo-500/10 text-indigo-400 hover:bg-indigo-500/20 border border-indigo-500/30 rounded-xl transition-all cursor-pointer shadow-sm active:scale-95"
        >
          <Keyboard className="w-3.5 h-3.5" />
          <span>Help (F1)</span>
        </button>

        {/* Language Switcher */}
        <div className="hidden lg:flex items-center bg-slate-950/80 p-0.5 rounded-xl border border-slate-800 text-[11px]">
          <button
            type="button"
            onClick={() => setLanguage('en')}
            className={`px-2.5 py-1 rounded-lg font-bold transition-all cursor-pointer ${
              language === 'en' ? 'bg-indigo-600 text-white shadow-md' : 'text-slate-400 hover:text-white'
            }`}
            title="Language: English"
          >
            EN
          </button>
          <button
            type="button"
            onClick={() => setLanguage('bilingual')}
            className={`px-2.5 py-1 rounded-lg font-bold transition-all cursor-pointer ${
              language === 'bilingual' ? 'bg-indigo-600 text-white shadow-md' : 'text-slate-400 hover:text-white'
            }`}
            title="Language: Dual (EN+සිං)"
          >
            Dual
          </button>
          <button
            type="button"
            onClick={() => setLanguage('si')}
            className={`px-2.5 py-1 rounded-lg font-bold transition-all cursor-pointer ${
              language === 'si' ? 'bg-indigo-600 text-white shadow-md' : 'text-slate-400 hover:text-white'
            }`}
            title="Language: Sinhala (සිංහල)"
          >
            සිං
          </button>
        </div>
      </div>

      {/* Right: Network Sync & Cashier Profile */}
      <div className="flex items-center gap-3">
        {/* Network & Diagnostics */}
        <div
          onClick={() => openModal('syncStatus')}
          title="Offline & Sync Diagnostics"
          className="flex items-center gap-2 bg-slate-950/80 hover:bg-slate-800/80 cursor-pointer px-3 py-1.5 rounded-xl border border-slate-800 transition-all shadow-sm"
        >
          {isOnline ? (
            <div className="flex items-center gap-1.5 text-xs text-emerald-400">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
              <Wifi className="w-3.5 h-3.5" />
              <span className="hidden sm:inline font-semibold">Online</span>
            </div>
          ) : (
            <div className="flex items-center gap-1.5 text-xs text-rose-400">
              <span className="w-2 h-2 rounded-full bg-rose-500" />
              <WifiOff className="w-3.5 h-3.5" />
              <span className="hidden sm:inline font-semibold">Offline</span>
            </div>
          )}

          <div className="h-3.5 w-px bg-slate-800" />

          {/* Manual sync trigger */}
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              void triggerManualSync();
            }}
            disabled={syncStatus === 'syncing'}
            title="Trigger Immediate Sync"
            className="flex items-center gap-1.5 text-xs text-slate-300 hover:text-white transition-colors cursor-pointer"
          >
            <RefreshCw className={`w-3.5 h-3.5 text-indigo-400 ${syncStatus === 'syncing' ? 'animate-spin' : ''}`} />
            {pendingCount > 0 ? (
              <span className="bg-amber-500 text-slate-950 font-bold px-1.5 py-0.5 rounded-full text-[10px]">
                {pendingCount}
              </span>
            ) : (
              <span className="text-[11px] text-slate-400">Synced</span>
            )}
          </button>
        </div>

        {/* Cashier Info */}
        <div className="flex items-center gap-2.5 pl-2 border-l border-slate-800">
          <div className="w-8 h-8 rounded-xl bg-gradient-to-tr from-indigo-600 to-violet-500 flex items-center justify-center font-bold text-xs shadow-md text-white">
            <User className="w-4 h-4" />
          </div>
          <div className="hidden xl:block text-left">
            <div className="text-xs font-bold text-white leading-tight">{user?.name || 'Cashier'}</div>
            <div className="text-[10px] text-slate-400 uppercase tracking-wider font-semibold">{user?.role?.replaceAll('_', ' ') || 'cashier'}</div>
          </div>
          <button
            type="button"
            onClick={() => void logout()}
            title="Logout Cashier"
            className="p-1.5 text-slate-400 hover:text-rose-400 hover:bg-slate-800/80 rounded-xl transition-colors ml-1 cursor-pointer"
          >
            <LogOut className="w-4 h-4" />
          </button>
        </div>
      </div>
    </header>
  );
};

