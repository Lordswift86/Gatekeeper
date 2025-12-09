import React, { useState, useEffect } from 'react';
import { User, GuestPass, PassStatus, PassType, Bill, BillStatus } from '../types';
import { MockService } from '../services/mockData';
import { Card, CardHeader, CardBody } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Plus, Clock, Share2, Trash2, UserCheck, Truck, AlertOctagon, CheckCircle, Wallet, AlertCircle } from 'lucide-react';
import { AdBanner } from '../components/AdBanner';

interface Props {
  user: User;
  showAds: boolean;
}

export const ResidentDashboard: React.FC<Props> = ({ user, showAds }) => {
  // Navigation State (internal to dashboard to swap between passes and payments if passed from parent)
  const [view, setView] = useState<'passes' | 'payments'>('passes');

  const [passes, setPasses] = useState<GuestPass[]>([]);
  const [bills, setBills] = useState<Bill[]>([]);
  const [isAccessRestricted, setIsAccessRestricted] = useState(false);

  // Form State
  const [isCreating, setIsCreating] = useState(false);
  const [createType, setCreateType] = useState<PassType>(PassType.ONE_TIME);
  const [guestName, setGuestName] = useState('');
  const [exitInstruction, setExitInstruction] = useState('');
  
  // Recurring Form State
  const [recurringStart, setRecurringStart] = useState('08:00');
  const [recurringEnd, setRecurringEnd] = useState('18:00');
  const [selectedDays, setSelectedDays] = useState<string[]>(['Mon', 'Tue', 'Wed', 'Thu', 'Fri']);
  
  // Delivery State
  const [deliveryCompany, setDeliveryCompany] = useState('');

  const DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  useEffect(() => {
    loadData();
    // Check for payments passed via props/route in a real app, here we rely on parent prop triggering re-render if needed or internal state
    const restricted = MockService.checkAccessRestricted(user.id);
    setIsAccessRestricted(restricted);
  }, [user.id]);

  // Hack to listen to parent view changes if passed (App.tsx passes view via logic, but here we can manage sub-view)
  // For simplicity, we are rendering everything in one component or switching based on internal state. 
  // Let's assume parent passes "payments" view via a prop if we were fully routing, 
  // but since App.tsx handles "dashboard", "history", "payments" as strings passed to Layout, 
  // we actually need to handle the "payments" view in App.tsx routing logic. 
  // However, App.tsx renders ResidentDashboard for all resident views. So we need to look at a prop.
  // We'll assume the Layout passes the `view` prop down if we update App.tsx, but currently it doesn't.
  // Instead, let's just add tabs here or check if we can infer.
  // Actually, let's assume the user clicks "Payments" in the sidebar, App.tsx sets currentView='payments',
  // and renders ResidentDashboard? No, App.tsx renders ResidentDashboard only for "dashboard".
  // Let's Fix App.tsx to pass the view prop. *Wait*, I cannot edit App.tsx in this turn unless I included it.
  // I did not include App.tsx in the file list above.
  // *Self-correction*: I can change the logic inside ResidentDashboard to handle the "Payments" view 
  // by checking a prop, but if I can't change App.tsx to pass that prop, I'm stuck.
  // Actually, I can rely on the fact that I can add a Tab switcher inside ResidentDashboard 
  // and user can click "Payments" in the sidebar which *should* set currentView. 
  // To make it work seamlessly without editing App.tsx (if I missed it), I will add a local tab.
  // BUT: The PRD and my plan said "Add 'Payments' navigation item". This implies App.tsx *should* route it.
  // I will check if I can edit App.tsx. Yes, I can add it to the changeset.

  const loadData = () => {
    setPasses(MockService.getUserPasses(user.id));
    setBills(MockService.getUserBills(user.id));
  };

  const toggleDay = (day: string) => {
    if (selectedDays.includes(day)) {
      setSelectedDays(selectedDays.filter(d => d !== day));
    } else {
      setSelectedDays([...selectedDays, day]);
    }
  };

  const handleCreatePass = (e: React.FormEvent) => {
    e.preventDefault();
    if (createType !== PassType.DELIVERY && !guestName) return;
    if (createType === PassType.DELIVERY && !deliveryCompany) return;
    
    MockService.generatePass(
      user.id, 
      guestName, 
      exitInstruction,
      createType,
      createType === PassType.RECURRING ? { days: selectedDays, start: recurringStart, end: recurringEnd } : undefined,
      deliveryCompany
    );

    setIsCreating(false);
    setGuestName('');
    setExitInstruction('');
    setDeliveryCompany('');
    setCreateType(PassType.ONE_TIME);
    loadData();
  };

  const handleCancelPass = (id: string) => {
    MockService.cancelPass(id);
    loadData();
  };

  const handlePayBill = async (billId: string) => {
    await MockService.payBill(billId);
    loadData();
    // Re-check restriction
    setIsAccessRestricted(MockService.checkAccessRestricted(user.id));
  };

  // Filter passes
  const activePasses = passes.filter(p => (p.status === PassStatus.ACTIVE || p.status === PassStatus.CHECKED_IN) && p.type === PassType.ONE_TIME);
  const activeDeliveries = passes.filter(p => (p.status === PassStatus.ACTIVE || p.status === PassStatus.CHECKED_IN) && p.type === PassType.DELIVERY);
  const recurringPasses = passes.filter(p => (p.status === PassStatus.ACTIVE || p.status === PassStatus.CHECKED_IN) && p.type === PassType.RECURRING);
  const pastPasses = passes.filter(p => p.status !== PassStatus.ACTIVE && p.status !== PassStatus.CHECKED_IN);

  // Helper to open specific create modal
  const openCreate = (type: PassType) => {
    setCreateType(type);
    setIsCreating(true);
  };

  // Render Logic
  // We'll render a simple tab switcher at the top for now since we can't easily change App.tsx routing prop passing without modifying App.tsx.
  // Wait, I *can* modify App.tsx. I will add it to the XML.

  return (
    <div className="space-y-6">
      {isAccessRestricted && (
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 p-4 rounded-xl flex items-start gap-4 animate-bounce-in">
           <AlertOctagon className="text-red-600 dark:text-red-400 w-6 h-6 shrink-0 mt-0.5" />
           <div>
             <h3 className="font-bold text-red-700 dark:text-red-400">Service Restricted</h3>
             <p className="text-sm text-red-600 dark:text-red-300 mt-1">You have unpaid bills overdue by more than 30 days. Guest code generation is disabled until payment is made.</p>
           </div>
        </div>
      )}

      {/* Internal Tabs if not using global routing yet */}
      <div className="flex gap-4 border-b border-slate-200 dark:border-slate-800">
        <button 
            onClick={() => setView('passes')} 
            className={`pb-3 px-1 font-medium text-sm transition-colors border-b-2 ${view === 'passes' ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400 dark:border-indigo-400' : 'border-transparent text-slate-500 dark:text-slate-400'}`}
        >
            My Passes
        </button>
        <button 
            onClick={() => setView('payments')} 
            className={`pb-3 px-1 font-medium text-sm transition-colors border-b-2 ${view === 'payments' ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400 dark:border-indigo-400' : 'border-transparent text-slate-500 dark:text-slate-400'}`}
        >
            Payments & Bills
        </button>
      </div>

      {view === 'payments' ? (
          <div className="space-y-4">
              <h3 className="text-lg font-bold text-slate-900 dark:text-white">Outstanding Bills</h3>
              {bills.length === 0 ? (
                  <div className="text-center py-10 bg-white dark:bg-slate-900 rounded-xl border border-dashed border-slate-300 dark:border-slate-700">
                     <CheckCircle className="mx-auto h-10 w-10 text-green-500 mb-3" />
                     <p className="text-slate-500 dark:text-slate-400">All caught up! No bills due.</p>
                  </div>
              ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {bills.map(bill => (
                          <Card key={bill.id} className={bill.status === BillStatus.PAID ? 'opacity-75' : ''}>
                              <CardBody>
                                  <div className="flex justify-between items-start mb-4">
                                      <div className={`p-2 rounded-lg ${bill.status === BillStatus.PAID ? 'bg-green-100 dark:bg-green-900/30 text-green-600' : 'bg-orange-100 dark:bg-orange-900/30 text-orange-600'}`}>
                                          <Wallet size={20} />
                                      </div>
                                      <span className={`px-2 py-1 text-xs font-bold rounded uppercase ${bill.status === BillStatus.PAID ? 'bg-green-100 dark:bg-green-900/30 text-green-700' : 'bg-red-100 dark:bg-red-900/30 text-red-700'}`}>
                                          {bill.status}
                                      </span>
                                  </div>
                                  <h4 className="font-bold text-slate-900 dark:text-white text-lg">${bill.amount.toFixed(2)}</h4>
                                  <p className="text-sm font-medium text-slate-700 dark:text-slate-300">{bill.description}</p>
                                  <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">Due: {new Date(bill.dueDate).toLocaleDateString()}</p>
                                  
                                  {bill.status === BillStatus.UNPAID && (
                                      <Button fullWidth className="mt-4" onClick={() => handlePayBill(bill.id)}>
                                          Pay Now
                                      </Button>
                                  )}
                              </CardBody>
                          </Card>
                      ))}
                  </div>
              )}
          </div>
      ) : (
        <>
            {/* PASSES VIEW */}
            <div className="flex justify-between items-center">
                <h2 className="text-xl font-bold text-slate-900 dark:text-white">Quick Actions</h2>
            </div>
            
            <div className="grid grid-cols-2 gap-4">
                <button 
                    onClick={() => openCreate(PassType.ONE_TIME)} 
                    disabled={isAccessRestricted}
                    className="flex flex-col items-center justify-center p-6 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl shadow-lg shadow-indigo-200 dark:shadow-none transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                >
                    <Plus size={24} className="mb-2" />
                    <span className="font-bold">New Guest</span>
                </button>
                <button 
                    onClick={() => openCreate(PassType.DELIVERY)} 
                    disabled={isAccessRestricted}
                    className="flex flex-col items-center justify-center p-6 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white hover:border-indigo-500 hover:text-indigo-600 dark:hover:text-indigo-400 rounded-xl transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                >
                    <Truck size={24} className="mb-2" />
                    <span className="font-bold">Expect Delivery</span>
                </button>
            </div>

            {/* Creation Modal */}
            {isCreating && (
                <Card className="border-indigo-100 ring-2 ring-indigo-50 dark:ring-indigo-900/30 animate-fade-in">
                <CardHeader title={createType === PassType.DELIVERY ? "Expected Delivery" : "Create Guest Pass"} />
                <CardBody>
                    {!isAccessRestricted ? (
                        <form onSubmit={handleCreatePass} className="space-y-4">
                            {/* Toggle Types if not Delivery */}
                            {createType !== PassType.DELIVERY && (
                                <div className="flex gap-4 mb-4 border-b border-slate-100 dark:border-slate-800 pb-2">
                                <button 
                                    type="button"
                                    onClick={() => setCreateType(PassType.ONE_TIME)}
                                    className={`pb-2 text-sm font-medium transition-colors ${createType === PassType.ONE_TIME ? 'text-indigo-600 dark:text-indigo-400 border-b-2 border-indigo-600 dark:border-indigo-400' : 'text-slate-500 dark:text-slate-400'}`}
                                >
                                    One-Time Visitor
                                </button>
                                <button 
                                    type="button"
                                    onClick={() => setCreateType(PassType.RECURRING)}
                                    className={`pb-2 text-sm font-medium transition-colors ${createType === PassType.RECURRING ? 'text-indigo-600 dark:text-indigo-400 border-b-2 border-indigo-600 dark:border-indigo-400' : 'text-slate-500 dark:text-slate-400'}`}
                                >
                                    Recurring Staff
                                </button>
                                </div>
                            )}

                            {createType === PassType.DELIVERY ? (
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Delivery Company</label>
                                    <div className="grid grid-cols-3 gap-2 mb-2">
                                        {['UberEats', 'Amazon', 'FedEx'].map(c => (
                                            <button 
                                                key={c} type="button" 
                                                onClick={() => setDeliveryCompany(c)}
                                                className={`text-xs py-2 rounded border ${deliveryCompany === c ? 'bg-indigo-600 text-white border-indigo-600' : 'bg-white dark:bg-slate-800 border-slate-300 dark:border-slate-600 text-slate-600 dark:text-slate-300'}`}
                                            >
                                                {c}
                                            </button>
                                        ))}
                                    </div>
                                    <input 
                                        type="text" 
                                        value={deliveryCompany}
                                        onChange={(e) => setDeliveryCompany(e.target.value)}
                                        className="w-full border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white rounded-lg px-3 py-2 text-sm"
                                        placeholder="Other Provider Name"
                                        required
                                    />
                                    <p className="text-xs text-orange-600 dark:text-orange-400 mt-2 flex items-center gap-1">
                                        <Clock size={12} /> Valid for 30 minutes only.
                                    </p>
                                </div>
                            ) : (
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                                    {createType === PassType.ONE_TIME ? 'Guest Name' : 'Staff Name'}
                                    </label>
                                    <input 
                                    type="text" 
                                    value={guestName}
                                    onChange={(e) => setGuestName(e.target.value)}
                                    className="w-full border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white rounded-lg px-3 py-2 focus:ring-indigo-500 focus:border-indigo-500"
                                    placeholder={createType === PassType.ONE_TIME ? "e.g. John Doe" : "e.g. Maria (Maid)"}
                                    required
                                    />
                                </div>
                            )}

                            {createType === PassType.RECURRING && (
                                <div className="p-4 bg-slate-50 dark:bg-slate-800/50 rounded-lg border border-slate-200 dark:border-slate-700 space-y-3">
                                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300">Schedule</label>
                                <div className="flex flex-wrap gap-2">
                                    {DAYS.map(day => (
                                    <button
                                        key={day}
                                        type="button"
                                        onClick={() => toggleDay(day)}
                                        className={`text-xs px-2 py-1 rounded border transition-colors ${
                                        selectedDays.includes(day) 
                                        ? 'bg-indigo-100 border-indigo-200 text-indigo-700 dark:bg-indigo-900/40 dark:border-indigo-700 dark:text-indigo-300 font-bold' 
                                        : 'bg-white dark:bg-slate-800 border-slate-200 dark:border-slate-700 text-slate-500 dark:text-slate-400'
                                        }`}
                                    >
                                        {day}
                                    </button>
                                    ))}
                                </div>
                                <div className="flex gap-4">
                                    <div>
                                    <label className="text-xs text-slate-500 dark:text-slate-400 block mb-1">Start Time</label>
                                    <input 
                                        type="time" 
                                        value={recurringStart} 
                                        onChange={e => setRecurringStart(e.target.value)}
                                        className="text-sm border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white rounded px-2 py-1"
                                    />
                                    </div>
                                    <div>
                                    <label className="text-xs text-slate-500 dark:text-slate-400 block mb-1">End Time</label>
                                    <input 
                                        type="time" 
                                        value={recurringEnd} 
                                        onChange={e => setRecurringEnd(e.target.value)}
                                        className="text-sm border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white rounded px-2 py-1"
                                    />
                                    </div>
                                </div>
                                </div>
                            )}
                            
                            {createType !== PassType.DELIVERY && (
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Exit Instruction (Optional)</label>
                                    <input 
                                        type="text" 
                                        value={exitInstruction}
                                        onChange={(e) => setExitInstruction(e.target.value)}
                                        className="w-full border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white rounded-lg px-3 py-2 focus:ring-indigo-500 focus:border-indigo-500"
                                        placeholder="e.g. Taking the TV, Driving Blue Toyota"
                                    />
                                </div>
                            )}

                            <div className="flex gap-3 pt-2">
                                <Button type="submit" fullWidth>
                                    {createType === PassType.DELIVERY ? 'Authorize Delivery' : 'Generate Code'}
                                </Button>
                                <Button type="button" variant="ghost" onClick={() => setIsCreating(false)}>Cancel</Button>
                            </div>
                        </form>
                    ) : (
                        <div className="text-center text-slate-500 py-4">
                            Please clear outstanding bills to resume.
                            <Button className="mt-4" onClick={() => { setIsCreating(false); setView('payments'); }}>Go to Payments</Button>
                        </div>
                    )}
                </CardBody>
                </Card>
            )}

            {/* Active Deliveries */}
            {activeDeliveries.length > 0 && (
                <div className="mb-6">
                    <h3 className="font-semibold text-slate-800 dark:text-slate-200 flex items-center gap-2 mb-3">
                        <Truck size={18} className="text-blue-600 dark:text-blue-400" /> Expected Deliveries
                    </h3>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {activeDeliveries.map(pass => (
                            <Card key={pass.id} className="bg-blue-50 dark:bg-blue-900/20 border-blue-100 dark:border-blue-900/50">
                                <CardBody className="flex justify-between items-center">
                                    <div>
                                        <h4 className="font-bold text-slate-900 dark:text-white">{pass.guestName}</h4>
                                        <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
                                            Code: <span className="font-mono">{pass.code}</span>
                                        </p>
                                    </div>
                                    <div className="text-right">
                                        <span className="text-xs font-bold text-orange-600 dark:text-orange-400 block">
                                            {pass.status === PassStatus.CHECKED_IN ? 'ARRIVED' : 'WAITING'}
                                        </span>
                                        <Button size="sm" variant="danger" className="mt-2 text-xs h-7 px-2" onClick={() => handleCancelPass(pass.id)}>Cancel</Button>
                                    </div>
                                </CardBody>
                            </Card>
                        ))}
                    </div>
                </div>
            )}
            
            {/* Recurring & Active Sections (Simplified reuse of existing) */}
            {recurringPasses.length > 0 && (
                <div className="mb-6">
                <h3 className="font-semibold text-slate-800 dark:text-slate-200 flex items-center gap-2 mb-3">
                    <UserCheck size={18} className="text-purple-600 dark:text-purple-400" /> My Staff
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {recurringPasses.map(pass => (
                    <Card key={pass.id} className="bg-purple-50 dark:bg-purple-900/20 border-purple-100 dark:border-purple-900/50">
                        <CardBody>
                        <div className="flex justify-between items-start">
                            <div>
                            <h4 className="font-bold text-slate-900 dark:text-white">{pass.guestName}</h4>
                            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1 font-mono">{pass.code}</p>
                            </div>
                            <span className="px-2 py-1 bg-white dark:bg-purple-900/40 rounded border border-purple-200 dark:border-purple-800 text-purple-700 dark:text-purple-300 text-xs font-bold">
                            STAFF
                            </span>
                        </div>
                        <div className="mt-4 flex gap-2">
                            <Button size="sm" variant="secondary" className="bg-white dark:bg-slate-800 text-xs h-8" onClick={() => alert(`Shared code ${pass.code} for ${pass.guestName}`)}>Share</Button>
                            <Button size="sm" variant="danger" className="text-xs h-8" onClick={() => handleCancelPass(pass.id)}>Revoke</Button>
                        </div>
                        </CardBody>
                    </Card>
                    ))}
                </div>
                </div>
            )}

            <h3 className="font-semibold text-slate-800 dark:text-slate-200 flex items-center gap-2">
                <Clock size={18} className="text-indigo-600 dark:text-indigo-400" /> Active Visitor Passes
            </h3>
            
            {activePasses.length === 0 ? (
                <div className="text-center py-6 bg-white dark:bg-slate-900 rounded-xl border border-dashed border-slate-300 dark:border-slate-700">
                <p className="text-slate-500 dark:text-slate-400 text-sm">No active visitor passes.</p>
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {activePasses.map(pass => (
                    <Card key={pass.id}>
                    <CardBody>
                        <div className="flex flex-col items-center text-center">
                        <div className="text-3xl font-mono font-bold tracking-widest text-slate-900 dark:text-white my-2">
                            {pass.code}
                        </div>
                        <h4 className="font-semibold text-slate-900 dark:text-white">{pass.guestName}</h4>
                        <p className="text-xs text-slate-500 dark:text-slate-400 mb-4">Valid until {new Date(pass.validUntil).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</p>
                        
                        <div className="flex gap-2 w-full">
                            <Button variant="secondary" fullWidth className="gap-2 text-xs" onClick={() => alert(`Shared code ${pass.code} for ${pass.guestName}`)}>
                            <Share2 size={14} /> Share
                            </Button>
                            <Button variant="danger" className="px-3" onClick={() => handleCancelPass(pass.id)}>
                            <Trash2 size={14} />
                            </Button>
                        </div>
                        </div>
                    </CardBody>
                    </Card>
                ))}
                </div>
            )}

            {showAds && <AdBanner position="inline" />}
            
        </>
      )}
    </div>
  );
};
