import React, { useState, useEffect } from 'react';
import { User, Estate, SubscriptionTier } from '../types';
import { MockService } from '../services/mockData';
import { Card, CardHeader, CardBody } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Building2, Users, TrendingUp, DollarSign, BadgeCheck } from 'lucide-react';

interface Props {
  user: User;
}

export const SuperAdminDashboard: React.FC<Props> = ({ user }) => {
  const [estates, setEstates] = useState<Estate[]>([]);
  const [stats, setStats] = useState({ totalEstates: 0, totalUsers: 0, adImpressions: 0 });

  useEffect(() => {
    refreshData();
  }, []);

  const refreshData = () => {
    setEstates(MockService.getAllEstates());
    setStats(MockService.getGlobalStats());
  };

  const toggleTier = (id: string) => {
    MockService.toggleEstateTier(id);
    refreshData();
  };

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

      {/* Tenants Table */}
      <Card>
        <CardHeader title="Tenant Management" subtitle="Manage subscriptions and access" />
        <div className="overflow-x-auto">
          <table className="w-full text-sm text-left text-slate-500 dark:text-slate-400">
            <thead className="text-xs text-slate-700 dark:text-slate-300 uppercase bg-slate-50 dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700">
              <tr>
                <th className="px-6 py-4">Estate Name</th>
                <th className="px-6 py-4">Code</th>
                <th className="px-6 py-4">Status</th>
                <th className="px-6 py-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
              {estates.map((estate) => (
                <tr key={estate.id} className="bg-white dark:bg-slate-900 hover:bg-slate-50 dark:hover:bg-slate-800">
                  <td className="px-6 py-4 font-medium text-slate-900 dark:text-white">{estate.name}</td>
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
                  <td className="px-6 py-4 text-right">
                    <Button 
                        size="sm" 
                        variant={estate.subscriptionTier === SubscriptionTier.PREMIUM ? 'secondary' : 'primary'}
                        onClick={() => toggleTier(estate.id)}
                    >
                        {estate.subscriptionTier === SubscriptionTier.PREMIUM ? 'Downgrade' : 'Upgrade'}
                    </Button>
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