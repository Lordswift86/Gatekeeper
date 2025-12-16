import React, { useState, useEffect } from 'react';
import { User, Estate, SubscriptionTier } from '../types';
import { api } from '../services/api';
import { Card, CardHeader, CardBody } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Building2, Users, TrendingUp, DollarSign, BadgeCheck, Power, AlertCircle, Plus, Loader } from 'lucide-react';

interface Props {
  user: User;
  currentView: string;
}

export const SuperAdminDashboard: React.FC<Props> = ({ user, currentView }) => {
  const [estates, setEstates] = useState<Estate[]>([]);
  const [stats, setStats] = useState({ totalEstates: 0, totalUsers: 0, adImpressions: 0 });
  const [isLoading, setIsLoading] = useState(true);

  // Create Estate State
  const [isCreating, setIsCreating] = useState(false);
  const [newName, setNewName] = useState('');
  const [newCode, setNewCode] = useState('');
  const [newTier, setNewTier] = useState<SubscriptionTier>(SubscriptionTier.FREE);

  useEffect(() => {
    refreshData();
  }, []);

  const refreshData = async () => {
    setIsLoading(true);
    try {
      const [estateData, statsData] = await Promise.all([
        api.getAllEstates(),
        api.getPlatformStats()
      ]);
      setEstates(estateData);
      setStats(statsData);
    } catch (e) {
      console.error('Failed to load data:', e);
    } finally {
      setIsLoading(false);
    }
  };

  const toggleTier = async (id: string, currentTier: SubscriptionTier) => {
    try {
      const newTier = currentTier === SubscriptionTier.FREE ? SubscriptionTier.PREMIUM : SubscriptionTier.FREE;
      await api.updateEstate(id, { subscriptionTier: newTier });
      await refreshData();
    } catch (e) {
      console.error('Failed to update tier:', e);
      alert('Failed to update subscription tier');
    }
  };

  const toggleStatus = async (id: string) => {
    try {
      await api.toggleEstateStatus(id);
      refreshData();
    } catch (e) {
      console.error('Failed to toggle status:', e);
    }
  };

  const handleCreateEstate = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await api.createEstate({ name: newName, code: newCode, tier: newTier });
      setIsCreating(false);
      setNewName('');
      setNewCode('');
      setNewTier(SubscriptionTier.FREE);
      refreshData();
    } catch (e) {
      console.error('Failed to create estate:', e);
    }
  };

  // --- OVERVIEW VIEW ---
  if (currentView === 'overview') {
    return (
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <div>
            <h2 className="text-2xl font-bold text-slate-900 dark:text-white">Platform Overview</h2>
            <p className="text-slate-500 dark:text-slate-400">Super Admin Console</p>
          </div>
          <div className="flex gap-2">
            <Button variant="secondary" className="gap-2">
              <DollarSign size={16} /> Manage Ads
            </Button>
          </div>
        </div>

        {/* Global Stats */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <Card>
            <CardBody className="flex items-center gap-4">
              <div className="p-3 rounded-lg bg-indigo-500 text-white">
                <Building2 size={24} />
              </div>
              <div>
                <p className="text-sm text-slate-500 dark:text-slate-400 font-medium">Active Estates</p>
                <p className="text-2xl font-bold text-slate-900 dark:text-white">{stats.totalEstates}</p>
              </div>
            </CardBody>
          </Card>
          <Card>
            <CardBody className="flex items-center gap-4">
              <div className="p-3 rounded-lg bg-pink-500 text-white">
                <Users size={24} />
              </div>
              <div>
                <p className="text-sm text-slate-500 dark:text-slate-400 font-medium">Total Users</p>
                <p className="text-2xl font-bold text-slate-900 dark:text-white">{stats.totalUsers}</p>
              </div>
            </CardBody>
          </Card>
          <Card>
            <CardBody className="flex items-center gap-4">
              <div className="p-3 rounded-lg bg-orange-500 text-white">
                <TrendingUp size={24} />
              </div>
              <div>
                <p className="text-sm text-slate-500 dark:text-slate-400 font-medium">Ad Impressions</p>
                <p className="text-2xl font-bold text-slate-900 dark:text-white">{stats.adImpressions.toLocaleString()}</p>
              </div>
            </CardBody>
          </Card>
        </div>

        <div className="p-4 bg-slate-100 dark:bg-slate-900 rounded-lg text-center border border-slate-200 dark:border-slate-800">
          <p className="text-slate-500 dark:text-slate-400 text-sm">Use the <span className="font-bold">Tenants</span> tab to manage accounts and subscriptions.</p>
        </div>
      </div>
    );
  }

  // --- TENANTS VIEW ---
  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold text-slate-900 dark:text-white">Tenant Management</h2>
          <p className="text-slate-500 dark:text-slate-400">Manage estate accounts and subscriptions</p>
        </div>
        <Button className="gap-2" onClick={() => setIsCreating(true)}>
          <Plus size={16} /> Add Estate
        </Button>
      </div>

      {isCreating && (
        <Card className="animate-fade-in border-2 border-indigo-100 dark:border-indigo-900/30">
          <CardHeader title="Create New Tenant Estate" />
          <CardBody>
            <form onSubmit={handleCreateEstate} className="grid grid-cols-1 md:grid-cols-4 gap-4 items-end">
              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Estate Name</label>
                <input
                  className="w-full border p-2 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white"
                  placeholder="e.g. Sunnyvale"
                  value={newName}
                  onChange={e => setNewName(e.target.value)}
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Property Code</label>
                <input
                  className="w-full border p-2 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white uppercase"
                  placeholder="e.g. SVL01"
                  value={newCode}
                  onChange={e => setNewCode(e.target.value)}
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Subscription Plan</label>
                <select
                  className="w-full border p-2 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white"
                  value={newTier}
                  onChange={e => setNewTier(e.target.value as SubscriptionTier)}
                >
                  <option value={SubscriptionTier.FREE}>Free (Ad-Supported)</option>
                  <option value={SubscriptionTier.PREMIUM}>Premium (Ad-Free)</option>
                </select>
              </div>
              <div className="flex gap-2">
                <Button type="submit" fullWidth>Create</Button>
                <Button type="button" variant="ghost" onClick={() => setIsCreating(false)}>Cancel</Button>
              </div>
            </form>
          </CardBody>
        </Card>
      )}

      {/* Tenants Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="w-full text-sm text-left text-slate-500 dark:text-slate-400">
            <thead className="text-xs text-slate-700 dark:text-slate-300 uppercase bg-slate-50 dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700">
              <tr>
                <th className="px-6 py-4">Estate Name</th>
                <th className="px-6 py-4">Code</th>
                <th className="px-6 py-4">Plan</th>
                <th className="px-6 py-4">Status</th>
                <th className="px-6 py-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
              {estates.map((estate) => (
                <tr key={estate.id} className="bg-white dark:bg-slate-900 hover:bg-slate-50 dark:hover:bg-slate-800">
                  <td className="px-6 py-4 font-medium text-slate-900 dark:text-white flex items-center gap-2">
                    <Building2 size={16} className="text-slate-400" />
                    {estate.name}
                  </td>
                  <td className="px-6 py-4 font-mono">{estate.code}</td>
                  <td className="px-6 py-4">
                    <span className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium ${estate.subscriptionTier === SubscriptionTier.PREMIUM
                      ? 'bg-purple-100 dark:bg-purple-900/30 text-purple-800 dark:text-purple-300'
                      : 'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-300'
                      }`}>
                      {estate.subscriptionTier === SubscriptionTier.PREMIUM ? (
                        <><BadgeCheck size={12} /> PREMIUM</>
                      ) : (
                        'FREE TIER'
                      )}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    {estate.status === 'SUSPENDED' ? (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300 text-xs font-bold">
                        <AlertCircle size={12} /> SUSPENDED
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 text-xs font-bold">
                        ACTIVE
                      </span>
                    )}
                  </td>
                  <td className="px-6 py-4 text-right space-x-2">
                    <button
                      onClick={() => toggleTier(estate.id, estate.subscriptionTier)}
                      className="text-indigo-600 dark:text-indigo-400 hover:underline text-xs font-medium"
                    >
                      {estate.subscriptionTier === SubscriptionTier.PREMIUM ? 'Downgrade' : 'Upgrade'}
                    </button>
                    <span className="text-slate-300 dark:text-slate-700">|</span>
                    <button
                      onClick={() => toggleStatus(estate.id)}
                      className={`text-xs font-medium hover:underline ${estate.status === 'ACTIVE' ? 'text-red-600 dark:text-red-400' : 'text-green-600 dark:text-green-400'}`}
                    >
                      {estate.status === 'ACTIVE' ? 'Suspend' : 'Activate'}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
};