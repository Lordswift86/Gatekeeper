import React, { useState, useEffect } from 'react';
import { User, Estate, SubscriptionTier, GlobalAd, SystemLog } from '../../types';
import api from '../../services/api';
import { Card, CardHeader, CardBody } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { Building2, Users, TrendingUp, BadgeCheck, AlertCircle, Plus, Trash2, Activity, Search, RefreshCw, Edit, X } from 'lucide-react';

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
    const [isLoading, setIsLoading] = useState(false);

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
    const [adTargetUrl, setAdTargetUrl] = useState('');
    const [adActive, setAdActive] = useState(true);

    // ... (keep previous code)

    // Ad Actions
    const handleSubmitAd = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            if (editingAdId) {
                await api.updateGlobalAd(editingAdId, { title: adTitle, content: adContent, targetUrl: adTargetUrl, isActive: adActive });
            } else {
                await api.createGlobalAd({ title: adTitle, content: adContent, targetUrl: adTargetUrl });
            }
            resetAdForm();
            await refreshData();
        } catch (error) {
            console.error('Failed to submit ad:', error);
        }
    };

    const handleEditClick = (ad: GlobalAd) => {
        setEditingAdId(ad.id);
        setAdTitle(ad.title);
        setAdContent(ad.content);
        setAdTargetUrl(ad.targetUrl || '');
        setAdActive(ad.isActive);
        setIsCreatingAd(true);
    };

    const resetAdForm = () => {
        setIsCreatingAd(false);
        setEditingAdId(null);
        setAdTitle('');
        setAdContent('');
        setAdTargetUrl('');
        setAdActive(true);
    };

    // ... (keep previous code)

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
                                    <input
                                        className="w-full border p-2 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white"
                                        value={adTitle}
                                        onChange={e => setAdTitle(e.target.value)}
                                        placeholder="e.g. Best Fiber Internet"
                                        required
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-bold mb-1 dark:text-white">Ad Copy</label>
                                    <input
                                        className="w-full border p-2 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white"
                                        value={adContent}
                                        onChange={e => setAdContent(e.target.value)}
                                        placeholder="e.g. Sign up now for 50% off"
                                        required
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-bold mb-1 dark:text-white">Target Link (Optional)</label>
                                    <input
                                        type="url"
                                        className="w-full border p-2 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white"
                                        value={adTargetUrl}
                                        onChange={e => setAdTargetUrl(e.target.value)}
                                        placeholder="e.g. https://example.com/promo"
                                    />
                                    <p className="text-xs text-slate-500 mt-1">Users will be directed here when they tap the ad.</p>
                                </div>
                                <div className="flex items-center gap-2">
                                    <input
                                        type="checkbox"
                                        id="adActive"
                                        checked={adActive}
                                        onChange={e => setAdActive(e.target.checked)}
                                        className="rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                                    />
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
                                    <p className="text-slate-600 dark:text-slate-300 text-sm mb-1">{ad.content}</p>
                                    {ad.targetUrl && (
                                        <p className="text-xs text-indigo-500 mb-4 flex items-center gap-1">
                                            <TrendingUp size={12} /> {ad.targetUrl}
                                        </p>
                                    )}
                                    <div className="flex items-center gap-2 text-sm text-slate-500">
                                        <Activity size={16} /> <strong>{ad.impressions?.toLocaleString() || 0}</strong> impressions
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
                                <span className={`font-bold shrink-0 w-24 ${log.severity === 'CRITICAL' ? 'text-red-500' :
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

    // --- TENANTS VIEW (Default) ---
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
                                        <button
                                            onClick={() => handleViewEstateResidents(estate.id)}
                                            className="hover:text-indigo-600 dark:hover:text-indigo-400 hover:underline cursor-pointer transition-colors"
                                        >
                                            {estate.name}
                                        </button>
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

            {/* Estate Residents Modal */}
            {selectedEstateId && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 backdrop-blur-sm animate-fade-in p-4">
                    <div className="bg-white dark:bg-slate-900 rounded-xl shadow-2xl w-full max-w-3xl max-h-[80vh] overflow-hidden border border-slate-200 dark:border-slate-800">
                        <div className="p-6 border-b border-slate-200 dark:border-slate-800 flex justify-between items-center">
                            <div>
                                <h3 className="text-xl font-bold text-slate-900 dark:text-white">Estate Residents</h3>
                                <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
                                    {estates.find(e => e.id === selectedEstateId)?.name}
                                </p>
                            </div>
                            <button
                                onClick={closeResidentsModal}
                                className="p-2 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-full transition-colors"
                            >
                                <X size={20} className="text-slate-400" />
                            </button>
                        </div>

                        <div className="overflow-y-auto max-h-[60vh] p-6">
                            {loadingResidents ? (
                                <div className="text-center py-12">
                                    <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
                                    <p className="mt-4 text-slate-500">Loading residents...</p>
                                </div>
                            ) : estateResidents.length === 0 ? (
                                <div className="text-center py-12">
                                    <Users size={48} className="mx-auto text-slate-300 dark:text-slate-700 mb-4" />
                                    <p className="text-slate-500 dark:text-slate-400">No residents found in this estate</p>
                                </div>
                            ) : (
                                <div className="space-y-3">
                                    {estateResidents.map(resident => (
                                        <div key={resident.id} className="flex items-center justify-between p-4 bg-slate-50 dark:bg-slate-800 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors">
                                            <div className="flex items-center gap-4">
                                                <div className="w-10 h-10 rounded-full bg-indigo-100 dark:bg-indigo-900/30 flex items-center justify-center">
                                                    <span className="text-indigo-600 dark:text-indigo-400 font-bold">
                                                        {resident.name.charAt(0)}
                                                    </span>
                                                </div>
                                                <div>
                                                    <p className="font-medium text-slate-900 dark:text-white">{resident.name}</p>
                                                    <p className="text-sm text-slate-500 dark:text-slate-400">{resident.email}</p>
                                                </div>
                                            </div>
                                            <div className="flex items-center gap-4">
                                                {resident.unitNumber && (
                                                    <span className="px-3 py-1 bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300 rounded text-sm font-mono">
                                                        Unit {resident.unitNumber}
                                                    </span>
                                                )}
                                                <span className={`px-2 py-1 rounded text-xs font-bold ${resident.role === 'RESIDENT' ? 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300' :
                                                    resident.role === 'ESTATE_ADMIN' ? 'bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300' :
                                                        'bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300'
                                                    }`}>
                                                    {resident.role.replace('_', ' ')}
                                                </span>
                                                <div title={resident.isApproved ? "Approved" : "Pending Approval"}>
                                                    {resident.isApproved ? (
                                                        <BadgeCheck size={18} className="text-green-500" />
                                                    ) : (
                                                        <AlertCircle size={18} className="text-orange-500" />
                                                    )}
                                                </div>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};