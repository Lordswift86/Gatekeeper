import React, { useState, useEffect } from 'react';
import { User, Announcement, BillType, BillStatus, Bill } from '../../types';
import api from '../../services/api';
import { Card, CardBody, CardHeader } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts';
import { Users, Shield, Calendar, Check, X, Megaphone, Plus, CreditCard, DollarSign, Wallet, AlertCircle, FileText, UploadCloud, Phone } from 'lucide-react';

interface Props {
  user: User;
  currentView?: string;
}

export const EstateAdminDashboard: React.FC<Props> = ({ user, currentView = 'overview' }) => {
  const [stats, setStats] = useState({ totalResidents: 0, pendingResidents: 0, activePasses: 0, unpaidBills: 0 });
  const [pendingUsers, setPendingUsers] = useState<User[]>([]);
  const [announcements, setAnnouncements] = useState<Announcement[]>([]);
  const [residents, setResidents] = useState<User[]>([]);
  const [bills, setBills] = useState<Bill[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  // Announcement Form
  const [isPosting, setIsPosting] = useState(false);
  const [annoTitle, setAnnoTitle] = useState('');
  const [annoContent, setAnnoContent] = useState('');

  // Billing Form
  const [isBilling, setIsBilling] = useState(false);
  const [selectedResident, setSelectedResident] = useState('');
  const [billAmount, setBillAmount] = useState('');
  const [billType, setBillType] = useState<BillType>(BillType.SERVICE_CHARGE);
  const [billDesc, setBillDesc] = useState('');

  useEffect(() => {
    refreshData();
  }, [user.estateId, currentView]);

  const refreshData = async () => {
    setIsLoading(true);
    try {
      const [statsData, pending, annoData, residentsData, billsData] = await Promise.all([
        api.getEstateStats(),
        api.getPendingUsers(),
        api.getAnnouncements(),
        api.getAllResidents(),
        api.getEstateBills()
      ]);

      setStats(statsData);
      setPendingUsers(pending);
      setAnnouncements(annoData);
      setResidents(residentsData);
      setBills(billsData);
    } catch (error) {
      console.error('Failed to load data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleApprove = async (userId: string) => {
    try {
      await api.approveUser(userId);
      await refreshData();
    } catch (error) {
      console.error('Failed to approve user:', error);
    }
  };

  const handleReject = async (userId: string) => {
    if (window.confirm('Are you sure you want to reject this user?')) {
      try {
        await api.deleteUser(userId);
        await refreshData();
      } catch (error) {
        console.error('Failed to reject user:', error);
      }
    }
  };

  const handlePostAnnouncement = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!annoTitle || !annoContent) return;

    try {
      await api.createAnnouncement({ title: annoTitle, content: annoContent });
      setAnnoTitle('');
      setAnnoContent('');
      setIsPosting(false);
      await refreshData();
    } catch (error) {
      console.error('Failed to post announcement:', error);
    }
  };

  const handleIssueBill = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedResident) return;

    try {
      await api.createBill({
        userId: selectedResident,
        type: billType,
        amount: parseFloat(billAmount),
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
        description: billDesc
      });

      setIsBilling(false);
      setBillAmount('');
      setBillDesc('');
      setSelectedResident('');
      await refreshData();
    } catch (error) {
      console.error('Failed to create bill:', error);
    }
  };

  // Sample traffic data for chart
  const trafficData = [
    { day: 'Mon', entries: 120, exits: 115 },
    { day: 'Tue', entries: 140, exits: 138 },
    { day: 'Wed', entries: 160, exits: 155 },
    { day: 'Thu', entries: 145, exits: 142 },
    { day: 'Fri', entries: 175, exits: 170 },
    { day: 'Sat', entries: 95, exits: 90 },
    { day: 'Sun', entries: 85, exits: 82 },
  ];

  if (currentView === 'overview') {
    return (
      <div className="space-y-6">
        <div>
          <h2 className="text-2xl font-bold text-slate-900 dark:text-white mb-2">Estate Overview</h2>
          <p className="text-slate-500 dark:text-slate-400">Monitor your estate's activity</p>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <Card>
            <CardBody>
              <div className="flex items-center gap-4">
                <div className="p-3 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                  <Users className="w-6 h-6 text-blue-600 dark:text-blue-400" />
                </div>
                <div>
                  <p className="text-sm text-slate-500 dark:text-slate-400">Total Residents</p>
                  <p className="text-2xl font-bold text-slate-900 dark:text-white">{stats.totalResidents}</p>
                </div>
              </div>
            </CardBody>
          </Card>

          <Card>
            <CardBody>
              <div className="flex items-center gap-4">
                <div className="p-3 bg-orange-100 dark:bg-orange-900/30 rounded-lg">
                  <AlertCircle className="w-6 h-6 text-orange-600 dark:text-orange-400" />
                </div>
                <div>
                  <p className="text-sm text-slate-500 dark:text-slate-400">Pending Approvals</p>
                  <p className="text-2xl font-bold text-slate-900 dark:text-white">{stats.pendingResidents}</p>
                </div>
              </div>
            </CardBody>
          </Card>

          <Card>
            <CardBody>
              <div className="flex items-center gap-4">
                <div className="p-3 bg-green-100 dark:bg-green-900/30 rounded-lg">
                  <Shield className="w-6 h-6 text-green-600 dark:text-green-400" />
                </div>
                <div>
                  <p className="text-sm text-slate-500 dark:text-slate-400">Active Passes</p>
                  <p className="text-2xl font-bold text-slate-900 dark:text-white">{stats.activePasses}</p>
                </div>
              </div>
            </CardBody>
          </Card>

          <Card>
            <CardBody>
              <div className="flex items-center gap-4">
                <div className="p-3 bg-red-100 dark:bg-red-900/30 rounded-lg">
                  <DollarSign className="w-6 h-6 text-red-600 dark:text-red-400" />
                </div>
                <div>
                  <p className="text-sm text-slate-500 dark:text-slate-400">Unpaid Bills</p>
                  <p className="text-2xl font-bold text-slate-900 dark:text-white">{stats.unpaidBills}</p>
                </div>
              </div>
            </CardBody>
          </Card>
        </div>

        {/* Traffic Chart */}
        <Card>
          <CardHeader title="Gate Traffic (Last 7 Days)" />
          <CardBody>
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={trafficData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                <XAxis dataKey="day" stroke="#64748b" />
                <YAxis stroke="#64748b" />
                <Tooltip />
                <Bar dataKey="entries" fill="#3b82f6" name="Entries" radius={[4, 4, 0, 0]} />
                <Bar dataKey="exits" fill="#10b981" name="Exits" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardBody>
        </Card>
      </div>
    );
  }

  if (currentView === 'approvals') {
    return (
      <div className="space-y-6">
        <div>
          <h2 className="text-2xl font-bold text-slate-900 dark:text-white mb-2">Pending Approvals</h2>
          <p className="text-slate-500 dark:text-slate-400">Review and approve new residents</p>
        </div>

        {isLoading ? (
          <div className="text-center py-12">
            <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
          </div>
        ) : pendingUsers.length === 0 ? (
          <Card>
            <CardBody>
              <div className="text-center py-12">
                <Check className="w-16 h-16 mx-auto text-green-500 mb-4" />
                <p className="text-slate-500 dark:text-slate-400">All caught up! No pending approvals.</p>
              </div>
            </CardBody>
          </Card>
        ) : (
          <div className="grid gap-4">
            {pendingUsers.map(pending => (
              <Card key={pending.id}>
                <CardBody>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                      <div className="w-12 h-12 rounded-full bg-indigo-100 dark:bg-indigo-900/30 flex items-center justify-center">
                        <span className="text-indigo-600 dark:text-indigo-400 font-bold text-lg">
                          {pending.name.charAt(0)}
                        </span>
                      </div>
                      <div>
                        <p className="font-medium text-slate-900 dark:text-white">{pending.name}</p>
                        <p className="text-sm text-slate-500 dark:text-slate-400">{pending.email}</p>
                        <p className="text-xs text-slate-400 dark:text-slate-500">Unit {pending.unitNumber}</p>
                      </div>
                    </div>
                    <div className="flex gap-2">
                      <Button onClick={() => handleApprove(pending.id)} size="sm">
                        <Check size={16} className="mr-1" /> Approve
                      </Button>
                      <Button onClick={() => handleReject(pending.id)} variant="ghost" size="sm">
                        <X size={16} className="mr-1" /> Reject
                      </Button>
                    </div>
                  </div>
                </CardBody>
              </Card>
            ))}
          </div>
        )}
      </div>
    );
  }

  if (currentView === 'announcements') {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold text-slate-900 dark:text-white mb-2">Announcements</h2>
            <p className="text-slate-500 dark:text-slate-400">Communicate with residents</p>
          </div>
          <Button onClick={() => setIsPosting(true)}>
            <Plus size={16} className="mr-2" /> New Announcement
          </Button>
        </div>

        {isPosting && (
          <Card>
            <CardHeader title="Create Announcement" />
            <CardBody>
              <form onSubmit={handlePostAnnouncement} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Title</label>
                  <input
                    className="w-full border p-2 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white"
                    placeholder="e.g. Scheduled Maintenance"
                    value={annoTitle}
                    onChange={e => setAnnoTitle(e.target.value)}
                    required
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Content</label>
                  <textarea
                    className="w-full border p-2 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white"
                    rows={4}
                    placeholder="Enter announcement details..."
                    value={annoContent}
                    onChange={e => setAnnoContent(e.target.value)}
                    required
                  />
                </div>
                <div className="flex gap-2">
                  <Button type="submit">Post</Button>
                  <Button type="button" variant="ghost" onClick={() => setIsPosting(false)}>Cancel</Button>
                </div>
              </form>
            </CardBody>
          </Card>
        )}

        <div className="space-y-4">
          {announcements.map(anno => (
            <Card key={anno.id}>
              <CardBody>
                <div className="flex items-start gap-3">
                  <div className="p-2 bg-indigo-100 dark:bg-indigo-900/30 rounded">
                    <Megaphone className="w-5 h-5 text-indigo-600 dark:text-indigo-400" />
                  </div>
                  <div className="flex-1">
                    <h3 className="font-semibold text-slate-900 dark:text-white">{anno.title}</h3>
                    <p className="text-sm text-slate-600 dark:text-slate-400 mt-1">{anno.content}</p>
                    <p className="text-xs text-slate-400 dark:text-slate-500 mt-2">
                      {new Date(anno.createdAt).toLocaleDateString()}
                    </p>
                  </div>
                </div>
              </CardBody>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  if (currentView === 'settings') {
    const [securityPhone, setSecurityPhone] = useState(user.estate?.securityPhone || '');
    const [isSaving, setIsSaving] = useState(false);

    const handleSaveSettings = async (e: React.FormEvent) => {
      e.preventDefault();
      setIsSaving(true);
      try {
        if (user.estateId) {
          await api.updateEstate(user.estateId, { securityPhone });
          // Ideally refresh user profile or notify success
          alert('Settings saved successfully');
        }
      } catch (error) {
        console.error('Failed to update settings:', error);
        alert('Failed to save settings');
      } finally {
        setIsSaving(false);
      }
    };

    return (
      <div className="space-y-6">
        <div>
          <h2 className="text-2xl font-bold text-slate-900 dark:text-white mb-2">Estate Settings</h2>
          <p className="text-slate-500 dark:text-slate-400">Manage estate configuration</p>
        </div>

        <Card>
          <CardHeader title="General Configuration" />
          <CardBody>
            <form onSubmit={handleSaveSettings} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                  Security Contact Number
                </label>
                <p className="text-xs text-slate-500 mb-2">
                  This number will be dialed when residents press "Call Gate" in the app.
                  Format: +234...
                </p>
                <div className="flex gap-2">
                  <div className="relative flex-1">
                    <Phone className="absolute left-3 top-2.5 h-5 w-5 text-slate-400" />
                    <input
                      type="tel"
                      className="w-full border p-2 pl-10 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white"
                      placeholder="+2348012345678"
                      value={securityPhone}
                      onChange={e => setSecurityPhone(e.target.value)}
                    />
                  </div>
                </div>
              </div>

              <div className="pt-4 border-t border-slate-100 dark:border-slate-800">
                <Button type="submit" disabled={isSaving}>
                  {isSaving ? 'Saving...' : 'Save Changes'}
                </Button>
              </div>
            </form>
          </CardBody>
        </Card>
      </div>
    );
  }

  if (currentView === 'billing') {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold text-slate-900 dark:text-white mb-2">Billing & Collections</h2>
            <p className="text-slate-500 dark:text-slate-400">Manage resident bills</p>
          </div>
          <Button onClick={() => setIsBilling(true)}>
            <Plus size={16} className="mr-2" /> Issue Bill
          </Button>
        </div>

        {isBilling && (
          <Card>
            <CardHeader title="Issue New Bill" />
            <CardBody>
              <form onSubmit={handleIssueBill} className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Resident</label>
                  <select
                    className="w-full border p-2 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white"
                    value={selectedResident}
                    onChange={e => setSelectedResident(e.target.value)}
                    required
                  >
                    <option value="">Select Resident</option>
                    {residents.map(r => (
                      <option key={r.id} value={r.id}>{r.name} - Unit {r.unitNumber}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Type</label>
                  <select
                    className="w-full border p-2 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white"
                    value={billType}
                    onChange={e => setBillType(e.target.value as BillType)}
                  >
                    <option value={BillType.SERVICE_CHARGE}>Service Charge</option>
                    <option value={BillType.SECURITY_LEVY}>Security Levy</option>
                    <option value={BillType.MAINTENANCE}>Maintenance</option>
                    <option value={BillType.UTILITY}>Utility</option>
                    <option value={BillType.OTHER}>Other</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Amount</label>
                  <input
                    type="number"
                    step="0.01"
                    className="w-full border p-2 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white"
                    placeholder="0.00"
                    value={billAmount}
                    onChange={e => setBillAmount(e.target.value)}
                    required
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Description</label>
                  <input
                    className="w-full border p-2 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white"
                    placeholder="Bill description"
                    value={billDesc}
                    onChange={e => setBillDesc(e.target.value)}
                    required
                  />
                </div>
                <div className="md:col-span-2 flex gap-2">
                  <Button type="submit">Issue Bill</Button>
                  <Button type="button" variant="ghost" onClick={() => setIsBilling(false)}>Cancel</Button>
                </div>
              </form>
            </CardBody>
          </Card>
        )}

        <Card>
          <div className="overflow-x-auto">
            <table className="w-full text-sm text-left">
              <thead className="text-xs text-slate-700 dark:text-slate-300 uppercase bg-slate-50 dark:bg-slate-800 border-b">
                <tr>
                  <th className="px-6 py-4">Resident</th>
                  <th className="px-6 py-4">Type</th>
                  <th className="px-6 py-4">Amount</th>
                  <th className="px-6 py-4">Status</th>
                  <th className="px-6 py-4">Due Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                {bills.map(bill => (
                  <tr key={bill.id} className="bg-white dark:bg-slate-900 hover:bg-slate-50 dark:hover:bg-slate-800">
                    <td className="px-6 py-4 font-medium text-slate-900 dark:text-white">
                      {residents.find(r => r.id === bill.userId)?.name || 'Unknown'}
                    </td>
                    <td className="px-6 py-4 text-slate-600 dark:text-slate-400">{bill.type.replace('_', ' ')}</td>
                    <td className="px-6 py-4 font-semibold text-slate-900 dark:text-white">${bill.amount.toFixed(2)}</td>
                    <td className="px-6 py-4">
                      <span className={`px-2 py-1 rounded text-xs font-bold ${bill.status === BillStatus.PAID
                        ? 'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300'
                        : 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300'
                        }`}>
                        {bill.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-slate-600 dark:text-slate-400">
                      {new Date(bill.dueDate).toLocaleDateString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      </div>
    );
  }

  return null;
};
