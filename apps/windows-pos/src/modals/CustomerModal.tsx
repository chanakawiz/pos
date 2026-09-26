import React, { useState, useEffect, useCallback } from 'react';
import { useCartStore } from '../stores/useCartStore';
import { usePosStore } from '../stores/usePosStore';
import { api } from '../services/api';
import type { Customer } from '../types/pos';
import { X, Search, UserPlus, Star, Phone, Mail, Check, UserCheck, Loader2 } from 'lucide-react';

export const CustomerModal: React.FC = () => {
  const { customer: selectedCustomer, setCustomer } = useCartStore();
  const { closeModal } = usePosStore();

  const [activeTab, setActiveTab] = useState<'search' | 'create'>('search');
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  // New Customer Form State
  const [name, setName] = useState<string>('');
  const [phone, setPhone] = useState<string>('');
  const [email, setEmail] = useState<string>('');
  const [address, setAddress] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

  // Search Customers
  const searchCustomers = useCallback(async (query: string) => {
    setIsLoading(true);
    setErrorMsg(null);
    try {
      const res = await api.getCustomers({ search: query || undefined, per_page: 20 });
      setCustomers(res.data || []);
    } catch (err: any) {
      setErrorMsg('Failed to load customers');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    const timer = setTimeout(() => {
      searchCustomers(searchTerm);
    }, 250);
    return () => clearTimeout(timer);
  }, [searchTerm, searchCustomers]);

  const handleSelectCustomer = (customer: Customer) => {
    setCustomer({
      id: customer.id,
      uuid: customer.uuid,
      name: customer.name,
      phone: customer.phone,
      email: customer.email,
      loyalty_points: customer.loyalty_points,
    });
    closeModal();
  };

  const handleCreateCustomer = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setErrorMsg('Customer name is required');
      return;
    }

    setIsSubmitting(true);
    setErrorMsg(null);
    try {
      const res = await api.createCustomer({
        name: name.trim(),
        phone: phone.trim() || undefined,
        email: email.trim() || undefined,
        address: address.trim() || undefined,
      });

      if (res.customer) {
        handleSelectCustomer(res.customer);
      }
    } catch (err: any) {
      setErrorMsg(err.response?.data?.message || 'Failed to create customer');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-xl shadow-2xl overflow-hidden flex flex-col animate-in fade-in zoom-in-95 duration-150">
        {/* Header */}
        <div className="p-5 border-b border-slate-800 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-indigo-600/20 text-indigo-400 flex items-center justify-center border border-indigo-500/30">
              <UserCheck className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-base font-bold text-white">Customer CRM & Loyalty</h3>
              <p className="text-xs text-slate-400 mt-0.5">Attach customer profile to checkout</p>
            </div>
          </div>
          <button
            onClick={closeModal}
            className="p-1.5 text-slate-400 hover:text-white hover:bg-slate-800 rounded-lg transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Tab Controls */}
        <div className="flex border-b border-slate-800 bg-slate-950/40 px-5 pt-3 gap-4">
          <button
            onClick={() => setActiveTab('search')}
            className={`pb-3 text-xs font-bold transition-all border-b-2 cursor-pointer ${
              activeTab === 'search'
                ? 'border-indigo-500 text-indigo-400'
                : 'border-transparent text-slate-400 hover:text-slate-200'
            }`}
          >
            Search Directory
          </button>
          <button
            onClick={() => setActiveTab('create')}
            className={`pb-3 text-xs font-bold transition-all border-b-2 flex items-center gap-1.5 cursor-pointer ${
              activeTab === 'create'
                ? 'border-indigo-500 text-indigo-400'
                : 'border-transparent text-slate-400 hover:text-slate-200'
            }`}
          >
            <UserPlus className="w-3.5 h-3.5" />
            <span>+ Quick Add Customer</span>
          </button>
        </div>

        {/* Content Area */}
        <div className="p-5 flex-1 min-h-[350px] max-h-[60vh] overflow-y-auto">
          {errorMsg && (
            <div className="mb-4 p-3 rounded-xl bg-rose-500/10 border border-rose-500/30 text-rose-400 text-xs">
              {errorMsg}
            </div>
          )}

          {activeTab === 'search' ? (
            <div className="space-y-4">
              {/* Search Bar */}
              <div className="relative">
                <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  placeholder="Search by customer name, phone number, or email..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  autoFocus
                  className="w-full bg-slate-950 border border-slate-800 focus:border-indigo-500 rounded-xl pl-10 pr-4 py-2.5 text-xs text-white placeholder-slate-500 outline-none transition-all"
                />
              </div>

              {/* Customer List */}
              {isLoading ? (
                <div className="py-16 text-center text-slate-400 flex flex-col items-center justify-center gap-2">
                  <Loader2 className="w-6 h-6 animate-spin text-indigo-500" />
                  <span className="text-xs">Searching customer records...</span>
                </div>
              ) : customers.length === 0 ? (
                <div className="py-14 text-center text-slate-500">
                  <UserPlus className="w-10 h-10 mx-auto mb-2 opacity-30" />
                  <p className="text-sm font-medium">No matching customers found</p>
                  <button
                    onClick={() => setActiveTab('create')}
                    className="mt-3 text-xs text-indigo-400 hover:text-indigo-300 font-semibold underline underline-offset-4 cursor-pointer"
                  >
                    Click here to register a new customer
                  </button>
                </div>
              ) : (
                <div className="space-y-2.5">
                  {customers.map((c) => {
                    const isCurrent = selectedCustomer?.uuid === c.uuid;
                    return (
                      <div
                        key={c.uuid}
                        className={`bg-slate-950/60 border rounded-2xl p-3.5 flex items-center justify-between gap-4 transition-all hover:border-slate-700 ${
                          isCurrent ? 'border-indigo-500/60 bg-indigo-950/20' : 'border-slate-800'
                        }`}
                      >
                        <div className="min-w-0 flex-1">
                          <div className="flex items-center gap-2">
                            <h4 className="text-xs font-bold text-white truncate">{c.name}</h4>
                            {c.loyalty_points > 0 && (
                              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-500/10 text-amber-400 border border-amber-500/20">
                                <Star className="w-3 h-3 fill-amber-400 text-amber-400" />
                                {c.loyalty_points} pts (${(c.loyalty_points * 0.1).toFixed(2)})
                              </span>
                            )}
                          </div>
                          <div className="flex items-center gap-3 mt-1 text-[11px] text-slate-400">
                            {c.phone && (
                              <span className="flex items-center gap-1">
                                <Phone className="w-3 h-3 text-slate-500" />
                                {c.phone}
                              </span>
                            )}
                            {c.email && (
                              <span className="flex items-center gap-1">
                                <Mail className="w-3 h-3 text-slate-500" />
                                {c.email}
                              </span>
                            )}
                          </div>
                        </div>

                        <div>
                          {isCurrent ? (
                            <span className="flex items-center gap-1 text-xs font-bold text-emerald-400 bg-emerald-500/10 border border-emerald-500/20 px-3 py-1.5 rounded-xl">
                              <Check className="w-3.5 h-3.5" />
                              <span>Attached</span>
                            </span>
                          ) : (
                            <button
                              onClick={() => handleSelectCustomer(c)}
                              className="px-3.5 py-1.5 bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold rounded-xl shadow-md transition-colors cursor-pointer"
                            >
                              Attach to Cart
                            </button>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          ) : (
            /* Quick Add Customer Form */
            <form onSubmit={handleCreateCustomer} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">
                  Full Name <span className="text-rose-400">*</span>
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. John Doe"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  autoFocus
                  className="w-full bg-slate-950 border border-slate-800 focus:border-indigo-500 rounded-xl px-3.5 py-2.5 text-xs text-white placeholder-slate-500 outline-none transition-all"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Phone Number</label>
                  <input
                    type="tel"
                    placeholder="e.g. +1 555-0192"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-800 focus:border-indigo-500 rounded-xl px-3.5 py-2.5 text-xs text-white placeholder-slate-500 outline-none transition-all"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Email Address</label>
                  <input
                    type="email"
                    placeholder="e.g. john@example.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-800 focus:border-indigo-500 rounded-xl px-3.5 py-2.5 text-xs text-white placeholder-slate-500 outline-none transition-all"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">Billing / Shipping Address</label>
                <textarea
                  rows={2}
                  placeholder="Street, City, Postal Code"
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-800 focus:border-indigo-500 rounded-xl px-3.5 py-2 text-xs text-white placeholder-slate-500 outline-none transition-all resize-none"
                />
              </div>

              <div className="pt-2 flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setActiveTab('search')}
                  className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-semibold rounded-xl transition-colors cursor-pointer"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting || !name.trim()}
                  className="px-5 py-2 bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 text-white text-xs font-bold rounded-xl shadow-md transition-all flex items-center gap-1.5 cursor-pointer"
                >
                  {isSubmitting ? (
                    <>
                      <Loader2 className="w-3.5 h-3.5 animate-spin" />
                      <span>Saving...</span>
                    </>
                  ) : (
                    <span>Save & Attach Customer</span>
                  )}
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  );
};
