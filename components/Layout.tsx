import React, { useState, useEffect } from 'react';
import { User, UserRole, Estate, SubscriptionTier, CallStatus } from '../types';
import { LogOut, ShieldCheck, Home, User as UserIcon, Settings, Menu, Megaphone, Building2, Globe, Sun, Moon, Truck, CreditCard, PhoneCall, Phone, Mic, MicOff, Video, PhoneOff, Gamepad2, Activity, Search } from 'lucide-react';
import { AdBanner } from './AdBanner';
import { MockService } from '../services/mockData';

interface LayoutProps {
  user: User;
  estate?: Estate;
  children: React.ReactNode;
  onLogout: () => void;
  currentView: string;
  onViewChange: (view: string) => void;
  theme: 'light' | 'dark';
  onThemeToggle: () => void;
}

export const Layout: React.FC<LayoutProps> = ({ user, estate, children, onLogout, currentView, onViewChange, theme, onThemeToggle }) => {
  const isFreeTier = estate?.subscriptionTier === SubscriptionTier.FREE;
  const showAds = isFreeTier && user.role === UserRole.RESIDENT; // Only residents see ads in free tier
  const [mobileMenuOpen, setMobileMenuOpen] = React.useState(false);
  const [incomingCall, setIncomingCall] = useState<any>(null);
  const [callMuted, setCallMuted] = useState(false);

  // Poll for incoming calls if resident
  useEffect(() => {
    if (user.role === UserRole.RESIDENT) {
      const interval = setInterval(() => {
        const call = MockService.getIncomingCall(user.id);
        setIncomingCall(call);
      }, 3000);
      return () => clearInterval(interval);
    }
  }, [user.id, user.role]);

  const handleAnswerCall = () => {
    if (incomingCall) MockService.answerCall(incomingCall.id);
  };

  const handleEndCall = () => {
    if (incomingCall) MockService.endCall(incomingCall.id);
    setIncomingCall(null);
  };

  const NavItem = ({ view, icon: Icon, label }: { view: string; icon: any; label: string }) => (
    <button
      onClick={() => { onViewChange(view); setMobileMenuOpen(false); }}
      className={`flex items-center gap-3 px-4 py-3 rounded-lg w-full transition-colors ${currentView === view
        ? 'bg-indigo-50 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-400 font-medium'
        : 'text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800'
        }`}
    >
      <Icon size={20} />
      <span>{label}</span>
    </button>
  );

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 flex flex-col transition-colors duration-200">
      {/* Header */}
      <header className="bg-white dark:bg-slate-900 border-b border-slate-200 dark:border-slate-800 sticky top-0 z-30 transition-colors">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="bg-indigo-600 p-2 rounded-lg">
              <ShieldCheck className="text-white h-6 w-6" />
            </div>
            <div>
              <h1 className="font-bold text-slate-900 dark:text-white leading-none">GateKeeper</h1>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">{estate?.name || (user.role === UserRole.SUPER_ADMIN ? 'SaaS Master Console' : 'SaaS Platform')}</p>
            </div>
          </div>

          {/* Desktop User Menu */}
          <div className="hidden md:flex items-center gap-4">
            <button
              onClick={onThemeToggle}
              className="p-2 text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 dark:hover:bg-slate-800 rounded-full transition-colors"
              title="Toggle Theme"
            >
              {theme === 'dark' ? <Sun size={20} /> : <Moon size={20} />}
            </button>
            <div className="text-right">
              <p className="text-sm font-medium text-slate-900 dark:text-white">{user.name}</p>
              <span className="text-xs bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 px-2 py-0.5 rounded-full">{user.role.replace('_', ' ')}</span>
            </div>
            <button
              onClick={onLogout}
              className="p-2 text-slate-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-full transition-colors"
              title="Logout"
            >
              <LogOut size={20} />
            </button>
          </div>

          {/* Mobile Menu Toggle */}
          <button className="md:hidden p-2 text-slate-600 dark:text-slate-400" onClick={() => setMobileMenuOpen(!mobileMenuOpen)}>
            <Menu size={24} />
          </button>
        </div>
      </header>

      {/* Mobile Menu */}
      {mobileMenuOpen && (
        <div className="md:hidden bg-white dark:bg-slate-900 border-b border-slate-200 dark:border-slate-800 p-4 absolute top-16 left-0 right-0 z-20 shadow-lg">
          <div className="flex flex-col gap-2">
            <div className="pb-4 border-b border-slate-100 dark:border-slate-800 mb-2">
              <p className="font-medium text-slate-900 dark:text-white">{user.name}</p>
              <p className="text-sm text-slate-500 dark:text-slate-400">{user.email}</p>
            </div>
            <button onClick={onThemeToggle} className="flex items-center gap-3 px-4 py-3 text-slate-600 dark:text-slate-300">
              {theme === 'dark' ? <Sun size={20} /> : <Moon size={20} />} {theme === 'dark' ? 'Light Mode' : 'Dark Mode'}
            </button>
            <button onClick={onLogout} className="flex items-center gap-3 px-4 py-3 text-red-600 dark:text-red-400">
              <LogOut size={20} /> Logout
            </button>
          </div>
        </div>
      )}

      <main className="flex-1 max-w-7xl mx-auto w-full px-4 sm:px-6 lg:px-8 py-8 pb-24">
        <div className="grid grid-cols-1 md:grid-cols-12 gap-8">
          {/* Sidebar Navigation */}
          <nav className="hidden md:block md:col-span-3 lg:col-span-2 space-y-2">
            {user.role === UserRole.RESIDENT && (
              <>
                <NavItem view="dashboard" icon={Home} label="My Passes" />
                <NavItem view="history" icon={UserIcon} label="History" />
                <NavItem view="payments" icon={CreditCard} label="Payments" />
                <NavItem view="game" icon={Gamepad2} label="Relax Zone" />
                <NavItem view="settings" icon={Settings} label="Settings" />
              </>
            )}
            {user.role === UserRole.SECURITY && (
              <>
                <NavItem view="scanner" icon={ShieldCheck} label="Scanner" />
                <NavItem view="deliveries" icon={Truck} label="Deliveries" />
                <NavItem view="intercom" icon={PhoneCall} label="Intercom" />
                <NavItem view="logbook" icon={Menu} label="Logbook" />
              </>
            )}
            {user.role === UserRole.ESTATE_ADMIN && (
              <>
                <NavItem view="overview" icon={Home} label="Overview" />
                <NavItem view="approvals" icon={UserIcon} label="Approvals" />
                <NavItem view="announcements" icon={Megaphone} label="Announcements" />
                <NavItem view="billing" icon={CreditCard} label="Billing" />
                <NavItem view="settings" icon={Settings} label="Settings" />
              </>
            )}
            {user.role === UserRole.SUPER_ADMIN && (
              <>
                <NavItem view="overview" icon={Globe} label="Platform" />
                <NavItem view="tenants" icon={Building2} label="Tenants" />
                <NavItem view="users" icon={UserIcon} label="Users" />
                <NavItem view="ads" icon={Megaphone} label="Ad Manager" />
                <NavItem view="logs" icon={Activity} label="Audit Logs" />
              </>
            )}
          </nav>

          {/* Main Content Area */}
          <div className="md:col-span-9 lg:col-span-10">
            {children}
          </div>
        </div>
      </main>

      {/* Conditional Ad Banner */}
      {showAds && <AdBanner position="footer" />}

      {/* Incoming Call Overlay */}
      {incomingCall && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/80 backdrop-blur-sm animate-fade-in">
          <div className="bg-white dark:bg-slate-900 rounded-2xl shadow-2xl w-full max-w-sm overflow-hidden border border-slate-200 dark:border-slate-800">
            <div className="p-8 text-center">
              <div className="w-24 h-24 bg-indigo-100 dark:bg-indigo-900/30 rounded-full flex items-center justify-center mx-auto mb-6 animate-pulse">
                <Video className="w-10 h-10 text-indigo-600 dark:text-indigo-400" />
              </div>
              <h3 className="text-xl font-bold text-slate-900 dark:text-white">Main Gate Security</h3>
              <p className="text-slate-500 dark:text-slate-400 mb-8">{incomingCall.status === CallStatus.CONNECTED ? 'Audio Connected' : 'Incoming Call...'}</p>

              {incomingCall.status === CallStatus.RINGING ? (
                <div className="flex justify-center gap-6">
                  <button onClick={handleEndCall} className="w-16 h-16 rounded-full bg-red-500 hover:bg-red-600 text-white flex items-center justify-center transition-transform hover:scale-105">
                    <PhoneOff size={28} />
                  </button>
                  <button onClick={handleAnswerCall} className="w-16 h-16 rounded-full bg-green-500 hover:bg-green-600 text-white flex items-center justify-center transition-transform hover:scale-105 animate-bounce">
                    <Phone size={28} />
                  </button>
                </div>
              ) : (
                <div className="space-y-6">
                  <div className="flex justify-center gap-4">
                    <button onClick={() => setCallMuted(!callMuted)} className={`p-3 rounded-full ${callMuted ? 'bg-slate-200 dark:bg-slate-700 text-slate-900 dark:text-white' : 'bg-slate-100 dark:bg-slate-800 text-slate-500 dark:text-slate-400'}`}>
                      {callMuted ? <MicOff /> : <Mic />}
                    </button>
                  </div>
                  <button onClick={handleEndCall} className="w-full py-3 rounded-xl bg-red-500 hover:bg-red-600 text-white font-bold flex items-center justify-center gap-2">
                    <PhoneOff size={20} /> End Call
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};