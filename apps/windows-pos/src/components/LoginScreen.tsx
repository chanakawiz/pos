import { useRef, useState } from 'react';
import { ArrowRight, Check, Delete, Diamond, Eye, EyeOff, Loader2, LockKeyhole } from 'lucide-react';
import { useAuthStore } from '../stores/useAuthStore';

export function LoginScreen() {
  const { login, isLoading, error } = useAuthStore();
  const [mode, setMode] = useState<'pin' | 'password'>('pin');
  const [pin, setPin] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const submitting = useRef(false);
  const submitPin = async (value: string) => {
    if (submitting.current || isLoading) return;
    const next = value.replace(/\D/g, '').slice(0, 4);
    setPin(next);
    if (next.length !== 4) return;
    submitting.current = true;
    try { if (!(await login({ pin_code: next }))) setPin(''); }
    finally { submitting.current = false; }
  };
  return (
    <main className="login-layout">
      <section className="login-story"><div className="login-brand"><Diamond /><strong>OmniLuxe Store</strong></div><div className="login-editorial"><span className="eyebrow"><span className="live-dot" />THE CONSIDERED WORKSPACE</span><h1>A good day.<br /><span>Starts here.</span></h1><p>Less friction at the counter.<br />More room for the people in front of you.</p><div className="login-story-rule" /><div className="login-promise"><span><Check />Thoughtfully organized</span><span><Check />Built for your store</span></div></div><div className="login-story-bottom"><span>OMNILUXE / FLAGSHIP STATION</span><span>Made for the everyday.</span></div></section>
      <section className="login-access"><div className="login-form-wrap"><span className="eyebrow">YOUR STORE. YOUR SPACE.</span><div className="login-title"><h2>Welcome back.</h2><p>Sign in to open your retail workspace.</p></div><div className="login-mode" aria-label="Sign-in method"><button type="button" aria-pressed={mode === 'pin'} className={mode === 'pin' ? 'is-active' : ''} onClick={() => { setMode('pin'); setPin(''); }}>Cashier PIN</button><button type="button" aria-pressed={mode === 'password'} className={mode === 'password' ? 'is-active' : ''} onClick={() => setMode('password')}>Email & password</button></div>
        {error && <div role="alert" className="login-error">{error}</div>}
        {mode === 'pin' ? <div><label className="field-label" htmlFor="cashier-pin">Enter your 4-digit PIN</label><input id="cashier-pin" className="pin-input" type="password" inputMode="numeric" autoComplete="off" aria-label="Cashier PIN" placeholder="••••" maxLength={4} value={pin} disabled={isLoading} onChange={(event) => void submitPin(event.target.value)} autoFocus /><div className="pin-keypad">{['1','2','3','4','5','6','7','8','9'].map((digit) => <button type="button" disabled={isLoading} key={digit} onClick={() => void submitPin(pin + digit)}>{digit}</button>)}<button type="button" className="pin-clear" disabled={isLoading} onClick={() => setPin('')}>Clear</button><button type="button" disabled={isLoading} onClick={() => void submitPin(pin + '0')}>0</button><button type="button" disabled={isLoading} aria-label="Delete last PIN digit" onClick={() => setPin(pin.slice(0, -1))}><Delete /></button></div><p className="pin-hint">{isLoading ? <><Loader2 className="animate-spin" />Signing you in…</> : <><LockKeyhole />Your workspace opens after the fourth digit.</>}</p></div> :
          <form className="login-password" onSubmit={(event) => { event.preventDefault(); if (!isLoading) void login({ email, password }); }}><label className="field-label" htmlFor="login-email">Email address</label><input id="login-email" type="email" autoComplete="username" placeholder="you@yourstore.com" value={email} onChange={(event) => setEmail(event.target.value)} required disabled={isLoading} autoFocus /><label className="field-label" htmlFor="login-password">Password</label><div className="password-field"><input id="login-password" type={showPassword ? 'text' : 'password'} autoComplete="current-password" placeholder="Enter your password" value={password} onChange={(event) => setPassword(event.target.value)} required disabled={isLoading} /><button type="button" aria-label={showPassword ? 'Hide password' : 'Show password'} onClick={() => setShowPassword(!showPassword)}>{showPassword ? <EyeOff /> : <Eye />}</button></div><button type="submit" className="checkout-button" disabled={isLoading}><span>{isLoading ? 'Signing in…' : 'Sign in'}</span>{isLoading ? <Loader2 className="animate-spin" /> : <ArrowRight />}</button></form>}
        <div className="login-secure-note"><span className="live-dot" />A dedicated space for your store team.</div>
      </div><footer className="login-access-footer">OmniLuxe Store POS<span>Retail, thoughtfully connected.</span></footer></section>
    </main>
  );
}
