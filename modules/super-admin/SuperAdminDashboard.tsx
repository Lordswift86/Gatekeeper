import React, { useState, useEffect } from 'react';
import { User, Estate, SubscriptionTier, GlobalAd, SystemLog } from '../../types';
import { MockService } from '../../services/mockData';
import { Card, CardHeader, CardBody } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { Building2, Users, TrendingUp, DollarSign, BadgeCheck, Power, AlertCircle, Plus, Megaphone, Trash2, Activity, Search, RefreshCw, X, Edit } from 'lucide-react';

interface Props {
  user: User;
  currentView: string;
}

export const SuperAdminDashboard: React.FC<Props> = ({ user, currentView }) => {
  const [estates, setEstates] = useState<Estate[]>([]);
  const [allUsers, setAllUsers] = useState<User[]>([]);
  const [ads, setAds] = useState<GlobalAd[]>([]);
  const [logs, setLogs] = useState<SystemLog[]>([]);
  const [stats, setStats] = useState({ totalEstates: 0, totalUsers: 0, adImpressions: 0 });
  
  // Estate Creation
  const [isCreatingEstate, setIsCreatingEstate] = useState(false);
  const [newName, setNewName] = useState('');
  const [newCode, setNewCode] = useState('');
  const [newTier, setNewTier] = useState<SubscriptionTier>(SubscriptionTier.FREE);

  // User Management
  const [userSearch, setUserSearch] = useState('');

  // Ad Creation/Editing
  const [isCreatingAd, setIsCreatingAd] = useState(false);
  const [editingAdId, setEditingAdId] = useState<string | null>(null);
  const [adTitle, setAdTitle] = useState('');
  const [adContent, setAdContent] = useState('');
  const [adActive, setAdActive] = useState(true);

  useEffect(() => {
    refreshData();
  }, [currentView]);

  const refreshData = () => {
    setEstates(MockService.getAllEstates());
    setAllUsers(MockService.getAllUsers());
    setAds(MockService.getGlobalAds());
    setLogs(MockService.getSystemLogs());
    setStats(MockService.getGlobalStats());
  };

  // Estate Actions
  const toggleTier = (id: string) => { MockService.toggleEstateTier(id); refreshData(); };
  const toggleStatus = (id: string) => { MockService.toggleEstateStatus(id); refreshData(); };
  const handleCreateEstate = (e: React.FormEvent) => {
      e.preventDefault();
      MockService.createEstate(newName, newCode, newTier);
      setIsCreatingEstate(false);
      setNewName(''); setNewCode(''); setNewTier(SubscriptionTier.FREE);
      refreshData();
  };

  // User Actions
  const handleDeleteUser = (userId: string) => {
      if (window.confirm("Are you sure? This action cannot be undone.")) {
          MockService.deleteUser(userId);
          refreshData();
      }
  };

  // Ad Actions
  const handleSubmitAd = (e: React.FormEvent) => {
      e.preventDefault();
      if (editingAdId) {
          MockService.updateGlobalAd(editingAdId, adTitle, adContent, adActive);
      } else {
          MockService.createGlobalAd(adTitle, adContent);
      }
      resetAdForm();
      refreshData();
  };

  const handleEditClick = (ad: GlobalAd) => {
      setEditingAdId(ad.id);
      setAdTitle(ad.title);
      setAdContent(ad.content);
      setAdActive(ad.isActive);
      setIsCreatingAd(true);
  };

  const resetAdForm = () => {
      setIsCreatingAd(false);
      setEditingAdId(null);
      setAdTitle('');
      setAdContent('');
      setAdActive(true);
  };

  const handleDeleteAd = (adId: string) => {
      if (window.confirm("Delete this ad campaign?")) {
        MockService.deleteGlobalAd(adId);
        refreshData();
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
                <Button variant="secondary" className="gap-2" onClick={refreshData}>
                    <RefreshCw size={16} /> Refresh
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
          
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <Card>
                  <CardHeader title="Recent Activity" />
                  <div className="p-0">
                      <table className="w-full text-sm text-left">
                          <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                              {logs.slice(0, 5).map(log => (
                                  <tr key={log.id}>
                                      <td className="px-6 py-4">
                                          <p className="font-bold text-slate-800 dark:text-white">{log.action}</p>
                                          <p className="text-xs text-slate-500">{new Date(log.timestamp).toLocaleString()}</p>
                                      </td>
                                      <td className="px-6 py-4 text-slate-600 dark:text-slate-300 text-sm">
                                          {log.details}
                                      </td>
                                  </tr>
                              ))}
                          </tbody>
                      </table>
                  </div>
              </Card>
              
              <Card>
                  <CardHeader title="System Health" />
                  <CardBody>
                      <div className="space-y-4">
                          <div className="flex justify-between items-center">
                              <span className="text-sm font-medium text-slate-700 dark:text-slate-300">API Latency</span>
                              <span className="text-green-500 font-bold text-sm">24ms</span>
                          </div>
                          <div className="w-full bg-slate-200 dark:bg-slate-700 h-2 rounded-full overflow-hidden">
                              <div className="bg-green-500 h-full w-[10%]"></div>
                          </div>
                          
                          <div className="flex justify-between items-center">
                              <span className="text-sm font-medium text-slate-700 dark:text-slate-300">Database Load</span>
                              <span className="text-green-500 font-bold text-sm">12%</span>
                          </div>
                          <div className="w-full bg-slate-200 dark:bg-slate-700 h-2 rounded-full overflow-hidden">
                              <div className="bg-green-500 h-full w-[12%]"></div>
                          </div>

                          <div className="flex justify-between items-center">
                              <span className="text-sm font-medium text-slate-700 dark:text-slate-300">Storage Usage</span>
                              <span className="text-indigo-500 font-bold text-sm">45%</span>
                          </div>
                          <div className="w-full bg-slate-200 dark:bg-slate-700 h-2 rounded-full overflow-hidden">
                              <div className="bg-indigo-500 h-full w-[45%]"></div>
                          </div>
                      </div>
                  </CardBody>
              </Card>
          </div>
        </div>
      );
  }

  // --- USERS VIEW ---
  if (currentView === 'users') {
      const filteredUsers = allUsers.filter(u => u.name.toLowerCase().includes(userSearch.toLowerCase()) || u.email.includes(userSearch));
      
      return (
          <div className="space-y-6">
              <div className="flex justify-between items-center">
                <div>
                   <h2 className="text-2xl font-bold text-slate-900 dark:text-white">Global User Management</h2>
                   <p className="text-slate-500 dark:text-slate-400">Manage access across all tenants</p>
                </div>
              </div>
              
              <Card>
                  <CardHeader title="All Users" />
                  <div className="p-4 border-b border-slate-100 dark:border-slate-800 bg-slate-50 dark:bg-slate-900/50">
                      <div className="relative max-w-md">
                          <Search className="absolute left-3 top-2.5 text-slate-400" size={18} />
                          <input 
                              className="w-full pl-10 p-2 border rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white"
                              placeholder="Search by name or email..."
                              value={userSearch}
                              onChange={e => setUserSearch(e.target.value)}
                          />
                      </div>
                  </div>
                  <div className="overflow-x-auto">
                      <table className="w-full text-sm text-left">
                          <thead className="bg-slate-50 dark:bg-slate-800 text-slate-500 dark:text-slate-400">
                              <tr>
                                  <th className="px-6 py-3">Name</th>
                                  <th className="px-6 py-3">Role</th>
                                  <th className="px-6 py-3">Estate</th>
                                  <th className="px-6 py-3">Status</th>
                                  <th className="px-6 py-3 text-right">Actions</th>
                              </tr>
                          </thead>
                          <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                              {filteredUsers.map(u => {
                                  const userEstate = estates.find(e => e.id === u.estateId);
                                  return (
                                      <tr key={u.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                                          <td className="px-6 py-4">
                                              <p className="font-bold text-slate-900 dark:text-white">{u.name}</p>
                                              <p className="text-xs text-slate-500">{u.email}</p>
                                          </td>
                                          <td className="px-6 py-4">
                                              <span className="text-xs bg-slate-100 dark:bg-slate-800 px-2 py-1 rounded border border-slate-200 dark:border-slate-700">
                                                  {u.role.replace('_', ' ')}
                                              </span>
                                          </td>
                                          <td className="px-6 py-4 text-slate-600 dark:text-slate-300">
                                              {userEstate ? userEstate.name : (u.role === 'SUPER_ADMIN' ? 'Global' : 'N/A')}
                                          </td>
                                          <td className="px-6 py-4">
                                              {u.isApproved ? (
                                                  <span className="text-green-600 font-bold text-xs flex items-center gap-1"><BadgeCheck size={12}/> Approved</span>
                                              ) : (
                                                  <span className="text-orange-500 font-bold text-xs">Pending</span>
                                              )}
                                          </td>
                                          <td className="px-6 py-4 text-right">
                                              {u.role !== 'SUPER_ADMIN' && (
                                                  <Button size="sm" variant="danger" onClick={() => handleDeleteUser(u.id)}>
                                                      Ban User
                                                  </Button>
                                              )}
                                          </td>
                                      </tr>
                                  )
                              })}
                          </tbody>
                      </table>
                  </div>
              </Card>
          </div>
      );
  }

  // --- ADS VIEW ---
  if (currentView === 'ads') {
      return (
          <div className="space-y-6">
              <div className="flex justify-between items-center">
                <div>
                   <h2 className="text-2xl font-bold text-slate-900 dark:text-white">Ad Manager</h2>
                   <p className="text-slate-500 dark:text-slate-400">Monetization for Free Tier Estates</p>
                </div>
                <Button className="gap-2" onClick={() => { resetAdForm(); setIsCreatingAd(true); }}>
                    <Plus size={16} /> Create Ad
                </Button>
              </div>

              {isCreatingAd && (
                  <Card className="border-2 border-indigo-100 dark:border-indigo-900 animate-fade-in">
                      <CardHeader title={editingAdId ? "Edit Ad Campaign" : "New Global Ad Campaign"} />
                      <CardBody>
                          <form onSubmit={handleSubmitAd} className="space-y-4">
                              <div>
                                  <label className="block text-sm font-bold mb-1 dark:text-white">Headline</label>
                                  <input className="w-full border p-2 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white" value={adTitle} onChange={e => setAdTitle(e.target.value)} placeholder="e.g. Best Fiber Internet" required />
                              </div>
                              <div>
                                  <label className="block text-sm font-bold mb-1 dark:text-white">Ad Copy</label>
                                  <input className="w-full border p-2 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white" value={adContent} onChange={e => setAdContent(e.target.value)} placeholder="e.g. Sign up now for 50% off" required />
                              </div>
                              <div className="flex items-center gap-2">
                                  <input type="checkbox" id="adActive" checked={adActive} onChange={e => setAdActive(e.target.checked)} className="rounded border-slate-300 text-indigo-600 focus:ring-indigo-500" />
                                  <label htmlFor="adActive" className="text-sm text-slate-700 dark:text-slate-300">Campaign Active</label>
                              </div>
                              <div className="flex gap-2 justify-end">
                                  <Button type="button" variant="ghost" onClick={resetAdForm}>Cancel</Button>
                                  <Button type="submit">{editingAdId ? 'Update Campaign' : 'Launch Campaign'}</Button>
                              </div>
                          </form>
                      </CardBody>
                  </Card>
              )}

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {ads.map(ad => (
                      <Card key={ad.id}>
                          <CardBody className="flex justify-between items-start">
                              <div>
                                  <div className="flex items-center gap-2 mb-2">
                                      <span className={`px-2 py-0.5 text-[10px] font-bold uppercase rounded ${ad.isActive ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-500'}`}>
                                          {ad.isActive ? 'Active' : 'Paused'}
                                      </span>
                                      <span className="text-xs text-slate-400">{new Date(ad.createdAt).toLocaleDateString()}</span>
                                  </div>
                                  <h4 className="font-bold text-lg text-slate-900 dark:text-white">{ad.title}</h4>
                                  <p className="text-slate-600 dark:text-slate-300 text-sm mb-4">{ad.content}</p>
                                  <div className="flex items-center gap-2 text-sm text-slate-500">
                                      <Activity size={16} /> <strong>{ad.impressions.toLocaleString()}</strong> impressions
                                  </div>
                              </div>
                              <div className="flex gap-2">
                                <Button variant="ghost" className="text-indigo-600 hover:bg-indigo-50" onClick={() => handleEditClick(ad)}>
                                    <Edit size={18} />
                                </Button>
                                <Button variant="ghost" className="text-red-500 hover:text-red-700 hover:bg-red-50" onClick={() => handleDeleteAd(ad.id)}>
                                    <Trash2 size={18} />
                                </Button>
                              </div>
                          </CardBody>
                      </Card>
                  ))}
              </div>
          </div>
      );
  }

  // --- LOGS VIEW ---
  if (currentView === 'logs') {
      return (
          <div className="space-y-6">
              <h2 className="text-2xl font-bold text-slate-900 dark:text-white">System Audit Logs</h2>
              <Card className="bg-slate-900 text-slate-300 font-mono text-sm border-slate-700">
                  <div className="max-h-[600px] overflow-y-auto p-4 space-y-2">
                      {logs.map(log => (
                          <div key={log.id} className="flex gap-4 border-b border-slate-800 pb-2 mb-2 last:border-0 last:mb-0 last:pb-0">
                              <span className="text-slate-500 shrink-0 w-40">{new Date(log.timestamp).toLocaleString()}</span>
                              <span className={`font-bold shrink-0 w-24 ${
                                  log.severity === 'CRITICAL' ? 'text-red-500' : 
                                  log.severity === 'WARN' ? 'text-yellow-500' : 'text-blue-400'
                              }`}>{log.severity}</span>
                              <div className="flex-1">
                                  <span className="text-white font-bold mr-2">[{log.action}]</span>
                                  <span className="text-slate-400">{log.details}</span>
                                  <span className="text-slate-600 text-xs ml-2">by {log.actor}</span>
                              </div>
                          </div>
                      ))}
                  </div>
              </Card>
          </div>
      );
  }

  // --- TENANTS VIEW (Original) ---
  return (
    <div className="space-y-6">
        <div className="flex justify-between items-center">
            <div>
                <h2 className="text-2xl font-bold text-slate-900 dark:text-white">Tenant Management</h2>
                <p className="text-slate-500 dark:text-slate-400">Manage estate accounts and subscriptions</p>
            </div>
            <Button className="gap-2" onClick={() => setIsCreatingEstate(true)}>
                <Plus size={16} /> Add Estate
            </Button>
        </div>

        {isCreatingEstate && (
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
                             <Button type="button" variant="ghost" onClick={() => setIsCreatingEstate(false)}>Cancel</Button>
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
                        <span className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium ${
                            estate.subscriptionTier === SubscriptionTier.PREMIUM 
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
                            onClick={() => toggleTier(estate.id)}
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