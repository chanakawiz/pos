import React, { useState } from 'react';
import { useAuthStore } from '../stores/useAuthStore';
import { Store, KeyRound, Mail, Lock, ArrowRight, Loader2, Delete } from 'lucide-react';

export const LoginScreen: React.FC = () => {
  const { login, isLoading, error } = useAuthStore();
  const [mode, setMode] = useState<'pin' | 'password'>('pin');
  const [pin, setPin] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const handleNumpad = (digit: string) => {
    if (pin.length < 4 && !isLoading) {
      const next = pin + digit;
      setPin(next);
      if (next.length === 4) {
        // Automatic login trigger on 4 digits
        void login({ pin_code: next });
      }
    }
  };

  const handleBackspace = () => {
    if (!isLoading) {
      setPin(pin.slice(0, -1));
    }
  };

  const handleClear = () => {
    if (!isLoading) {
      setPin('');
    }
  };

  const handlePasswordSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!isLoading) {
      void login({ email, password });
    }
  };

  return (
    <div className="h-full w-full bg-slate-950 flex items-center justify-center p-6 select-none relative overflow-hidden font-sans">
      {/* Background radial glow */}
      <div className="absolute top-1/4 left-1/3 w-96 h-96 bg-indigo-600/10 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute bottom-1/4 right-1/3 w-96 h-96 bg-emerald-600/10 rounded-full blur-3xl pointer-events-none" />

      <div className="w-full max-w-md bg-slate-900/90 border border-slate-800 rounded-3xl p-8 shadow-2xl backdrop-blur-xl relative z-10">
        {/* Brand */}
        <div className="text-center mb-6">
          <div className="w-14 h-14 bg-indigo-600/20 text-indigo-400 border border-indigo-500/30 rounded-2xl flex items-center justify-center mx-auto mb-3 shadow-lg shadow-indigo-600/20">
            <Store className="w-8 h-8 text-indigo-400" />
          </div>
          <h1 className="text-2xl font-black text-white tracking-tight">SmartShop POS</h1>
          <p className="text-xs text-slate-400 mt-1">Cashier Station Terminal Login</p>
        </div>

        {/* Mode Selector */}
        <div className="flex bg-slate-950/80 p-1 rounded-xl border border-slate-800 mb-6">
          <button
            type="button"
            onClick={() => {
              setMode('pin');
              setPin('');
            }}
            className={`flex-1 flex items-center justify-center gap-2 py-2 rounded-lg text-xs font-bold transition-all cursor-pointer ${
              mode === 'pin'
                ? 'bg-indigo-600 text-white shadow-md'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <KeyRound className="w-3.5 h-3.5" />
            <span>Cashier PIN</span>
          </button>
          <button
            type="button"
            onClick={() => setMode('password')}
            className={`flex-1 flex items-center justify-center gap-2 py-2 rounded-lg text-xs font-bold transition-all cursor-pointer ${
              mode === 'password'
                ? 'bg-indigo-600 text-white shadow-md'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <Mail className="w-3.5 h-3.5" />
            <span>Email & Password</span>
          </button>
        </div>

        {error && (
          <div className="mb-4 p-3 bg-rose-950/60 border border-rose-900/70 text-rose-300 rounded-xl text-xs text-center font-medium">
            {error}
          </div>
        )}

        {/* PIN Pad Mode */}
        {mode === 'pin' ? (
          <div className="space-y-6">
            {/* PIN Display Dots */}
            <div className="flex justify-center items-center gap-4 py-3 bg-slate-950/60 rounded-2xl border border-slate-800">
              {[0, 1, 2, 3].map((idx) => (
                <div
                  key={idx}
                  className={`w-4 h-4 rounded-full transition-all duration-150 ${
                    pin.length > idx
                      ? 'bg-indigo-400 scale-110 shadow-lg shadow-indigo-500/50'
                      : 'bg-slate-800 border border-slate-700'
                  }`}
                />
              ))}
            </div>

            {/* Touch Numpad */}
            <div className="grid grid-cols-3 gap-3">
              {['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((num) => (
                <button
                  key={num}
                  type="button"
                  onClick={() => handleNumpad(num)}
                  disabled={isLoading}
                  className="h-14 bg-slate-800/60 hover:bg-slate-750 active:bg-indigo-600 active:text-white rounded-2xl text-xl font-bold text-slate-100 border border-slate-700/50 flex items-center justify-center transition-all cursor-pointer shadow-sm active:scale-95 disabled:opacity-50"
                >
                  {num}
                </button>
              ))}

              <button
                type="button"
                onClick={handleClear}
                disabled={isLoading}
                className="h-14 bg-slate-950 hover:bg-slate-850 text-slate-400 active:text-white rounded-2xl text-xs font-bold border border-slate-800 flex items-center justify-center transition-all cursor-pointer disabled:opacity-50"
              >
                CLEAR
              </button>

              <button
                type="button"
                onClick={() => handleNumpad('0')}
                disabled={isLoading}
                className="h-14 bg-slate-800/60 hover:bg-slate-750 active:bg-indigo-600 active:text-white rounded-2xl text-xl font-bold text-slate-100 border border-slate-700/50 flex items-center justify-center transition-all cursor-pointer shadow-sm active:scale-95 disabled:opacity-50"
              >
                0
              </button>

              <button
                type="button"
                onClick={handleBackspace}
                disabled={isLoading}
                className="h-14 bg-slate-950 hover:bg-slate-850 text-slate-400 active:text-white rounded-2xl text-xs font-bold border border-slate-800 flex items-center justify-center transition-all cursor-pointer disabled:opacity-50"
              >
                <Delete className="w-5 h-5" />
              </button>
            </div>

            <p className="text-center text-[11px] text-slate-500">
              Default seeded cashier PIN: <span className="font-mono text-indigo-400 font-bold">1234</span>
            </p>
          </div>
        ) : (
          /* Email / Password Form */
          <form onSubmit={handlePasswordSubmit} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5">
                Email Address
              </label>
              <div className="relative">
                <Mail className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  placeholder="cashier1@smartshop.com"
                  className="w-full bg-slate-950 border border-slate-700 rounded-xl pl-10 pr-4 py-3 text-sm text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5">
                Password
              </label>
              <div className="relative">
                <Lock className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  placeholder="••••••••"
                  className="w-full bg-slate-950 border border-slate-700 rounded-xl pl-10 pr-4 py-3 text-sm text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="w-full py-3.5 bg-indigo-600 hover:bg-indigo-500 active:scale-[0.99] text-white font-bold text-xs rounded-xl shadow-lg shadow-indigo-600/30 transition-all flex items-center justify-center gap-2 cursor-pointer mt-2 disabled:opacity-50"
            >
              {isLoading ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <>
                  <span>Sign In</span>
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </form>
        )}
      </div>
    </div>
  );
};

