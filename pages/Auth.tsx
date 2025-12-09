import React, { useState } from 'react';
import { MockService } from '../services/mockData';
import { User, UserRole } from '../types';
import { ShieldCheck, User as UserIcon, Lock, Building2 } from 'lucide-react';

interface Props {
  onLogin: (user: User) => void;
}

export const Auth: React.FC<Props> = ({ onLogin }) => {
  const [isLogin, setIsLogin] = useState(true);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  // Form State
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [estateCode, setEstateCode] = useState('');
  const [unitNumber, setUnitNumber] = useState('');
  const [role, setRole] = useState<UserRole>(UserRole.RESIDENT);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    setSuccessMsg('');

    try {
      if (isLogin) {
        const user = await MockService.login(email);
        if (user) {
          if (!user.isApproved && user.role !== UserRole.SUPER_ADMIN) {
             setError('Account pending approval by Estate Admin.');
          } else {
             onLogin(user);
          }
        } else {
          setError('User not found. Try demo accounts.');
        }
      } else {
        // Registration
        const res = await MockService.register(name, email, role, estateCode, unitNumber);
        if (res.success) {
          setSuccessMsg('Registration successful! Please wait for Admin approval before logging in.');
          setIsLogin(true); // Switch to login
        } else {
          setError(res.message || 'Registration failed');
        }
      }
    } catch (err) {
      setError('An error occurred');
    } finally {
      setLoading(false);
    }
  };

  const handleQuickLogin = (email: string) => {
      setEmail(email);
      setPassword('dummy');
      setIsLogin(true);
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4 relative">
      {/* Background Image & Overlay */}
      <div 
        className="absolute inset-0 z-0"
        style={{
          backgroundImage: 'url("https://images.unsplash.com/photo-1558036117-15d82a90b9b1?q=80&w=2940&auto=format&fit=crop")',
          backgroundSize: 'cover',
          backgroundPosition: 'center',
        }}
      >
        <div className="absolute inset-0 bg-slate-900/50 backdrop-blur-[2px]"></div>
      </div>

      <div className="bg-white dark:bg-slate-900 rounded-2xl shadow-2xl w-full max-w-md overflow-hidden relative z-10 transition-colors">
        <div className="bg-indigo-600 pt-8 pb-6 px-8 text-center">
          <div className="bg-white/20 w-16 h-16 rounded-2xl flex items-center justify-center mx-auto mb-4 backdrop-blur-sm shadow-lg">
            <ShieldCheck className="text-white w-9 h-9" />
          </div>
          <h1 className="text-2xl font-bold text-white tracking-tight">GateKeeper</h1>
          <p className="text-indigo-100 mt-1 text-sm font-medium opacity-90">Secure Entry Management System</p>
        </div>
        
        {/* Tabs */}
        <div className="flex border-b border-slate-200 dark:border-slate-800">
            <button 
              className={`flex-1 py-4 text-sm font-semibold transition-colors relative ${isLogin ? 'text-indigo-600 dark:text-indigo-400' : 'text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200'}`}
              onClick={() => { setIsLogin(true); setError(''); }}
            >
              Sign In
              {isLogin && <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-indigo-600 dark:bg-indigo-400 rounded-t-full mx-8"></div>}
            </button>
            <button 
              className={`flex-1 py-4 text-sm font-semibold transition-colors relative ${!isLogin ? 'text-indigo-600 dark:text-indigo-400' : 'text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200'}`}
              onClick={() => { setIsLogin(false); setError(''); }}
            >
              Create Account
              {!isLogin && <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-indigo-600 dark:bg-indigo-400 rounded-t-full mx-8"></div>}
            </button>
        </div>

        <div className="p-8 pt-6">
          {successMsg && (
            <div className="mb-4 p-3 bg-green-50 dark:bg-green-900/30 text-green-700 dark:text-green-300 text-sm rounded-lg border border-green-200 dark:border-green-800 text-center">
              {successMsg}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            {!isLogin && (
              <div className="animate-fade-in space-y-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5 uppercase tracking-wide">Full Name</label>
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    className="block w-full px-4 py-3 bg-slate-800 text-white border-transparent rounded-xl focus:ring-2 focus:ring-indigo-500 focus:bg-slate-700 placeholder-slate-400 transition-all text-sm"
                    placeholder="John Doe"
                    required={!isLogin}
                  />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5 uppercase tracking-wide">Role</label>
                    <select 
                      value={role} 
                      onChange={(e) => setRole(e.target.value as UserRole)}
                      className="block w-full px-4 py-3 bg-slate-800 text-white border-transparent rounded-xl focus:ring-2 focus:ring-indigo-500 focus:bg-slate-700 text-sm appearance-none"
                    >
                      <option value={UserRole.RESIDENT}>Resident</option>
                      <option value={UserRole.SECURITY}>Security</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5 uppercase tracking-wide">Estate Code</label>
                    <input
                      type="text"
                      value={estateCode}
                      onChange={(e) => setEstateCode(e.target.value)}
                      placeholder="SUN01"
                      className="block w-full px-4 py-3 bg-slate-800 text-white border-transparent rounded-xl focus:ring-2 focus:ring-indigo-500 focus:bg-slate-700 placeholder-slate-400 transition-all text-sm uppercase"
                      required={!isLogin}
                    />
                  </div>
                </div>
                {role === UserRole.RESIDENT && (
                  <div>
                    <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5 uppercase tracking-wide">Unit Number</label>
                    <input
                      type="text"
                      value={unitNumber}
                      onChange={(e) => setUnitNumber(e.target.value)}
                      placeholder="e.g. 101"
                      className="block w-full px-4 py-3 bg-slate-800 text-white border-transparent rounded-xl focus:ring-2 focus:ring-indigo-500 focus:bg-slate-700 placeholder-slate-400 transition-all text-sm"
                      required={!isLogin && role === UserRole.RESIDENT}
                    />
                  </div>
                )}
              </div>
            )}

            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5 uppercase tracking-wide">Email Address</label>
              <div className="relative group">
                <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                  <UserIcon className="h-5 w-5 text-slate-400 group-focus-within:text-indigo-400 transition-colors" />
                </div>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="block w-full pl-12 pr-4 py-3 bg-slate-800 text-white border-transparent rounded-xl focus:ring-2 focus:ring-indigo-500 focus:bg-slate-700 placeholder-slate-500 transition-all text-sm font-medium"
                  placeholder="name@example.com"
                  required
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5 uppercase tracking-wide">Password</label>
              <div className="relative group">
                <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                  <Lock className="h-5 w-5 text-slate-400 group-focus-within:text-indigo-400 transition-colors" />
                </div>
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="block w-full pl-12 pr-4 py-3 bg-slate-800 text-white border-transparent rounded-xl focus:ring-2 focus:ring-indigo-500 focus:bg-slate-700 placeholder-slate-500 transition-all text-sm font-medium"
                  placeholder="••••••••"
                  required
                />
              </div>
            </div>
            
            {error && (
              <div className="p-3 bg-red-50 dark:bg-red-900/30 text-red-600 dark:text-red-400 text-xs font-medium rounded-lg flex items-center gap-2 animate-pulse">
                 <span className="w-1.5 h-1.5 rounded-full bg-red-500" /> {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-indigo-600 text-white py-3.5 rounded-xl font-bold hover:bg-indigo-700 active:bg-indigo-800 transition-colors disabled:opacity-50 shadow-lg shadow-indigo-200 dark:shadow-none mt-2"
            >
              {loading ? 'Processing...' : (isLogin ? 'Sign In' : 'Create Account')}
            </button>
          </form>

          {isLogin && (
            <div className="mt-8">
              <p className="text-center text-[10px] text-slate-400 uppercase font-bold tracking-widest mb-4">Quick Demo Logins</p>
              <div className="grid grid-cols-2 gap-3">
                <button onClick={() => handleQuickLogin('admin@gatekeeper.com')} className="px-3 py-2 text-xs font-medium text-slate-600 dark:text-slate-300 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-indigo-50 dark:hover:bg-indigo-900/30 hover:border-indigo-100 dark:hover:border-indigo-800 rounded-lg border border-slate-200 dark:border-slate-700 transition-all text-center">
                  Super Admin
                </button>
                <button onClick={() => handleQuickLogin('alice@sunset.com')} className="px-3 py-2 text-xs font-medium text-slate-600 dark:text-slate-300 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-indigo-50 dark:hover:bg-indigo-900/30 hover:border-indigo-100 dark:hover:border-indigo-800 rounded-lg border border-slate-200 dark:border-slate-700 transition-all text-center">
                  Estate Admin
                </button>
                <button onClick={() => handleQuickLogin('bob@sunset.com')} className="px-3 py-2 text-xs font-medium text-slate-600 dark:text-slate-300 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-indigo-50 dark:hover:bg-indigo-900/30 hover:border-indigo-100 dark:hover:border-indigo-800 rounded-lg border border-slate-200 dark:border-slate-700 transition-all text-center">
                  Resident (Free)
                </button>
                <button onClick={() => handleQuickLogin('richie@royal.com')} className="px-3 py-2 text-xs font-medium text-slate-600 dark:text-slate-300 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-indigo-50 dark:hover:bg-indigo-900/30 hover:border-indigo-100 dark:hover:border-indigo-800 rounded-lg border border-slate-200 dark:border-slate-700 transition-all text-center">
                  Resident (Premium)
                </button>
                <button onClick={() => handleQuickLogin('sam@sunset.com')} className="col-span-2 px-3 py-2 text-xs font-medium text-slate-600 dark:text-slate-300 hover:text-indigo-600 dark:hover:text-indigo-400 hover:bg-indigo-50 dark:hover:bg-indigo-900/30 hover:border-indigo-100 dark:hover:border-indigo-800 rounded-lg border border-slate-200 dark:border-slate-700 transition-all text-center">
                  Security Guard
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};