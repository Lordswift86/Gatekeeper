import React, { useState } from 'react';
import { MockService } from './services/mockData';
import { User } from './types';
import { ShieldCheck, User as UserIcon, Lock } from 'lucide-react';

interface Props {
  onLogin: (user: User) => void;
}

export const Auth: React.FC<Props> = ({ onLogin }) => {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const user = await MockService.login(email);
      if (user) {
        onLogin(user);
      } else {
        setError('User not found. Try one of the demo accounts below.');
      }
    } catch (err) {
      setError('An error occurred');
    } finally {
      setLoading(false);
    }
  };

  const handleQuickLogin = (email: string) => {
    setEmail(email);
  };

  return (
    <div className="min-h-screen bg-slate-100 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden">
        <div className="bg-indigo-600 p-8 text-center">
          <div className="bg-white/20 w-16 h-16 rounded-xl flex items-center justify-center mx-auto mb-4 backdrop-blur-sm">
            <ShieldCheck className="text-white w-10 h-10" />
          </div>
          <h1 className="text-2xl font-bold text-white">GateKeeper</h1>
          <p className="text-indigo-200 mt-2 text-sm">Secure Entry Management System</p>
        </div>

        <div className="p-8">
          <form onSubmit={handleLogin} className="space-y-5">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Email Address</label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <UserIcon className="h-5 w-5 text-slate-400" />
                </div>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="block w-full pl-10 pr-3 py-2 border border-slate-300 rounded-lg focus:ring-indigo-500 focus:border-indigo-500"
                  placeholder="name@example.com"
                  required
                />
              </div>
            </div>

            {error && (
              <div className="p-3 bg-red-50 text-red-600 text-sm rounded-lg flex items-center gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-red-500" /> {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-indigo-600 text-white py-2.5 rounded-lg font-medium hover:bg-indigo-700 transition-colors disabled:opacity-50"
            >
              {loading ? 'Signing In...' : 'Sign In'}
            </button>
          </form>

          <div className="mt-8">
            <p className="text-center text-xs text-slate-400 uppercase font-bold tracking-wider mb-4">Quick Demo Logins</p>
            <div className="space-y-2">
              <button onClick={() => handleQuickLogin('admin@gatekeeper.com')} className="w-full text-left px-4 py-2 text-sm text-slate-600 hover:bg-slate-50 rounded border border-slate-100 flex justify-between group">
                <span>Super Admin</span>
                <span className="text-indigo-600 opacity-0 group-hover:opacity-100 transition-opacity">Select</span>
              </button>
              <button onClick={() => handleQuickLogin('bob@sunset.com')} className="w-full text-left px-4 py-2 text-sm text-slate-600 hover:bg-slate-50 rounded border border-slate-100 flex justify-between group">
                <span>Resident (Free Estate)</span>
                <span className="text-indigo-600 opacity-0 group-hover:opacity-100 transition-opacity">Select</span>
              </button>
              <button onClick={() => handleQuickLogin('sam@sunset.com')} className="w-full text-left px-4 py-2 text-sm text-slate-600 hover:bg-slate-50 rounded border border-slate-100 flex justify-between group">
                <span>Security Guard</span>
                <span className="text-indigo-600 opacity-0 group-hover:opacity-100 transition-opacity">Select</span>
              </button>
              <button onClick={() => handleQuickLogin('alice@sunset.com')} className="w-full text-left px-4 py-2 text-sm text-slate-600 hover:bg-slate-50 rounded border border-slate-100 flex justify-between group">
                <span>Estate Admin</span>
                <span className="text-indigo-600 opacity-0 group-hover:opacity-100 transition-opacity">Select</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};