import React, { useState, useEffect } from 'react';
import { User, Announcement, BillType, BillStatus, Bill } from '../types';
import { api } from '../services/api';
import { Card, CardBody, CardHeader } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts';
import { Users, Shield, Calendar, Check, X, Megaphone, Plus, CreditCard, DollarSign, Wallet, AlertCircle, FileText, UploadCloud, Loader } from 'lucide-react';

interface Props {
  user: User;
  currentView?: string;
}

export const AdminDashboard: React.FC<Props> = ({ user, currentView = 'overview' }) => {
  const [stats, setStats] = useState<any>({});
  const [estate, setEstate] = useState<any>(null);
  const [pendingUsers, setPendingUsers] = useState<User[]>([]);
  const [announcements, setAnnouncements] = useState<Announcement[]>([]);
  const [residents, setResidents] = useState<User[]>([]);
  const [bills, setBills] = useState<Bill[]>([]);
  const [isLoading, setIsLoading] = useState(true);

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
      const [statsData, pendingData, annoData, billsData] = await Promise.all([
        api.getEstateStats(),
        api.getPendingUsers(),
        api.getAnnouncements(),
        api.getEstateBills()
      ]);
      setStats(statsData);
      setPendingUsers(pendingData);
      setAnnouncements(annoData);
      setBills(billsData);
      // Residents from bills for now
      setResidents(pendingData);
    } catch (e) {
      console.error('Failed to load data:', e);
    } finally {
      setIsLoading(false);
    }
  };

  const handleApprove = async (userId: string) => {
    try {
      await api.approveUser(userId);
      refreshData();
    } catch (e) { console.error('Failed to approve:', e); }
  };

  const handleReject = async (userId: string) => {
    // Backend needs reject endpoint
    alert('User rejection feature not yet implemented in backend');
    refreshData();
  };

  const handlePostAnnouncement = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!annoTitle || !annoContent) return;
    try {
      await api.createAnnouncement({ title: annoTitle, content: annoContent });
      setAnnoTitle(''); setAnnoContent(''); setIsPosting(false);
      refreshData();
    } catch (e) { console.error('Failed to post:', e); }
  };

  const handleIssueBill = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedResident) return;

    try {
      await api.createBill({
        userId: selectedResident,
        type: billType,
        amount: parseFloat(billAmount),
        dueDate: new Date(Date.now() + 86400000 * 7).toISOString(),
        description: billDesc
      });

      setIsBilling(false);
      setBillAmount('');
      setBillDesc('');
      setSelectedResident('');
      refreshData();
      alert(`Bill issued successfully`);
    } catch (e: any) {
      alert(e.response?.data?.message || 'Failed to issue bill');
    }
  };

  const handleBulkUpload = async () => {
    const confirm = window.confirm("Simulate uploading bills for all residents?");
    if (confirm) {
      try {
        // For now just a simulation - would need batch endpoint
        alert("Bulk upload feature is not yet linked to the backend.");
        refreshData();
      } catch (e) {
        console.error('Bulk upload failed:', e);
      }
    }
  };

  // Chart Data (To be connected to API)
  const chartData: any[] = [];

  const StatCard = ({ title, value, icon: Icon, color }: any) => (
    <Card>
      <CardBody className="flex items-center gap-4">
        <div className={`p-3 rounded-lg ${color}`}><Icon className="w-6 h-6 text-white" /></div>
        <div><p className="text-sm text-slate-500 dark:text-slate-400 font-medium">{title}</p><p className="text-2xl font-bold text-slate-900 dark:text-white">{value}</p></div>
      </CardBody>
    </Card>
  );

  // --- APPROVALS VIEW ---
  if (currentView === 'approvals') {
    return (
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <div>
            <h2 className="text-2xl font-bold text-slate-900 dark:text-white">Pending Approvals</h2>
            <p className="text-slate-500 dark:text-slate-400">Review and verify new resident registrations</p>
          </div>
        </div>

        <Card>
          <CardBody>
            {pendingUsers.length === 0 ? (
              <div className="text-center py-12 text-slate-500 dark:text-slate-400">
                <Users className="mx-auto h-12 w-12 text-slate-300 dark:text-slate-600 mb-3" />
                <p>No new resident signups pending at this time.</p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="min-w-full text-left text-sm whitespace-nowrap">
                  <thead className="uppercase tracking-wider border-b-2 border-slate-100 dark:border-slate-800 font-medium text-slate-500 dark:text-slate-400">
                    <tr>
                      <th scope="col" className="px-6 py-4">Name</th>
                      <th scope="col" className="px-6 py-4">Email</th>
                      <th scope="col" className="px-6 py-4">Unit</th>
                      <th scope="col" className="px-6 py-4 text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                    {pendingUsers.map(u => (
                      <tr key={u.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                        <td className="px-6 py-4 font-medium text-slate-900 dark:text-white">{u.name}</td>
                        <td className="px-6 py-4 text-slate-500 dark:text-slate-400">{u.email}</td>
                        <td className="px-6 py-4 text-slate-500 dark:text-slate-400"><span className="bg-slate-100 dark:bg-slate-800 px-2 py-1 rounded text-xs font-bold">{u.unitNumber}</span></td>
                        <td className="px-6 py-4 text-right">
                          <div className="flex items-center justify-end gap-2">
                            <button onClick={() => handleApprove(u.id)} className="flex items-center gap-1 px-3 py-1.5 bg-green-100 hover:bg-green-200 dark:bg-green-900/30 dark:hover:bg-green-900/50 text-green-700 dark:text-green-300 rounded-lg text-xs font-bold transition-colors">
                              <Check size={14} /> Approve
                            </button>
                            <button onClick={() => handleReject(u.id)} className="flex items-center gap-1 px-3 py-1.5 bg-red-100 hover:bg-red-200 dark:bg-red-900/30 dark:hover:bg-red-900/50 text-red-700 dark:text-red-300 rounded-lg text-xs font-bold transition-colors">
                              <X size={14} /> Reject
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </CardBody>
        </Card>
      </div>
    );
  }

  // --- ANNOUNCEMENTS VIEW ---
  if (currentView === 'announcements') {
    return (
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <div>
            <h2 className="text-2xl font-bold text-slate-900 dark:text-white">Announcements</h2>
            <p className="text-slate-500 dark:text-slate-400">Broadcast messages to all residents</p>
          </div>
          <Button className="gap-2" onClick={() => setIsPosting(!isPosting)}>
            {isPosting ? <X size={16} /> : <Plus size={16} />} {isPosting ? 'Cancel' : 'New Post'}
          </Button>
        </div>

        {isPosting && (
          <Card className="animate-fade-in border-2 border-indigo-100 dark:border-indigo-900/30">
            <CardHeader title="Create Announcement" />
            <CardBody>
              <form onSubmit={handlePostAnnouncement} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Title</label>
                  <input className="w-full p-2 border dark:bg-slate-900 dark:border-slate-600 dark:text-white rounded text-sm" placeholder="e.g. Scheduled Power Outage" value={annoTitle} onChange={e => setAnnoTitle(e.target.value)} required />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Content</label>
                  <textarea className="w-full p-2 border dark:bg-slate-900 dark:border-slate-600 dark:text-white rounded text-sm min-h-[100px]" placeholder="Write your message here..." value={annoContent} onChange={e => setAnnoContent(e.target.value)} required />
                </div>
                <div className="flex justify-end gap-2">
                  <Button type="submit">Post Announcement</Button>
                </div>
              </form>
            </CardBody>
          </Card>
        )}

        <div className="grid gap-4">
          {announcements.length === 0 ? (
            <div className="text-center py-12 bg-white dark:bg-slate-900 rounded-xl border border-dashed border-slate-300 dark:border-slate-700">
              <Megaphone className="mx-auto h-10 w-10 text-slate-300 dark:text-slate-600 mb-3" />
              <p className="text-slate-500 dark:text-slate-400">No announcements posted yet.</p>
            </div>
          ) : (
            announcements.map(a => (
              <Card key={a.id}>
                <CardBody className="flex gap-4">
                  <div className="p-3 bg-yellow-100 dark:bg-yellow-900/30 rounded-xl h-fit shrink-0">
                    <Megaphone size={20} className="text-yellow-700 dark:text-yellow-500" />
                  </div>
                  <div className="space-y-1">
                    <div className="flex items-center gap-2 mb-1">
                      <h5 className="font-bold text-slate-900 dark:text-white">{a.title}</h5>
                      <span className="text-xs text-slate-400 bg-slate-100 dark:bg-slate-800 px-2 py-0.5 rounded-full">{a.date}</span>
                    </div>
                    <p className="text-slate-600 dark:text-slate-300 text-sm leading-relaxed">{a.content}</p>
                  </div>
                </CardBody>
              </Card>
            ))
          )}
        </div>
      </div>
    );
  }

  // --- BILLING VIEW ---
  if (currentView === 'billing') {
    const totalCollected = bills.filter(b => b.status === BillStatus.PAID).reduce((acc, curr) => acc + curr.amount, 0);
    const totalPending = bills.filter(b => b.status === BillStatus.UNPAID).reduce((acc, curr) => acc + curr.amount, 0);

    return (
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <div>
            <h2 className="text-2xl font-bold text-slate-900 dark:text-white">Billing & Collections</h2>
            <p className="text-slate-500 dark:text-slate-400">Manage estate finances and issue resident bills</p>
          </div>
          <div className="flex gap-2">
            <Button variant="secondary" className="gap-2" onClick={handleBulkUpload}>
              <UploadCloud size={16} /> Upload CSV
            </Button>
            <Button className="gap-2" onClick={() => setIsBilling(!isBilling)}>
              {isBilling ? <X size={16} /> : <DollarSign size={16} />} {isBilling ? 'Cancel' : 'Issue Bill'}
            </Button>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Card className="bg-green-50 dark:bg-green-900/10 border-green-200 dark:border-green-900/30">
            <CardBody className="flex items-center gap-4">
              <div className="p-3 bg-green-200 dark:bg-green-900/50 rounded-full text-green-700 dark:text-green-300"><DollarSign /></div>
              <div>
                <p className="text-xs font-bold text-green-600 dark:text-green-400 uppercase tracking-wide">Total Collected</p>
                <h3 className="text-2xl font-bold text-slate-900 dark:text-white">${totalCollected.toFixed(2)}</h3>
              </div>
            </CardBody>
          </Card>
          <Card className="bg-orange-50 dark:bg-orange-900/10 border-orange-200 dark:border-orange-900/30">
            <CardBody className="flex items-center gap-4">
              <div className="p-3 bg-orange-200 dark:bg-orange-900/50 rounded-full text-orange-700 dark:text-orange-300"><Wallet /></div>
              <div>
                <p className="text-xs font-bold text-orange-600 dark:text-orange-400 uppercase tracking-wide">Pending Payments</p>
                <h3 className="text-2xl font-bold text-slate-900 dark:text-white">${totalPending.toFixed(2)}</h3>
              </div>
            </CardBody>
          </Card>
        </div>

        {isBilling && (
          <Card className="animate-fade-in border-2 border-indigo-100 dark:border-indigo-900/30">
            <CardHeader title="Issue New Bill" />
            <CardBody>
              <form onSubmit={handleIssueBill} className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Select Resident</label>
                  <select
                    className="w-full p-2 rounded border dark:bg-slate-800 dark:border-slate-700 dark:text-white"
                    value={selectedResident}
                    onChange={e => setSelectedResident(e.target.value)}
                    required
                  >
                    <option value="">-- Select Resident --</option>
                    {residents.map(r => (
                      <option key={r.id} value={r.id}>{r.name} (Unit {r.unitNumber})</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Bill Type</label>
                  <select className="w-full p-2 rounded border dark:bg-slate-800 dark:border-slate-700 dark:text-white" value={billType} onChange={e => setBillType(e.target.value as BillType)}>
                    <option value={BillType.SERVICE_CHARGE}>Service Charge</option>
                    <option value={BillType.POWER}>Power</option>
                    <option value={BillType.WATER}>Water</option>
                    <option value={BillType.WASTE}>Waste</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Amount ($)</label>
                  <input className="w-full p-2 rounded border dark:bg-slate-800 dark:border-slate-700 dark:text-white" placeholder="0.00" type="number" step="0.01" value={billAmount} onChange={e => setBillAmount(e.target.value)} required />
                </div>
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Description</label>
                  <input className="w-full p-2 rounded border dark:bg-slate-800 dark:border-slate-700 dark:text-white" placeholder="e.g. October 2023 Service Charge" value={billDesc} onChange={e => setBillDesc(e.target.value)} required />
                </div>
                <div className="md:col-span-2 flex justify-end gap-2 mt-2">
                  <Button size="sm" type="submit" fullWidth>Issue Bill</Button>
                </div>
              </form>
            </CardBody>
          </Card>
        )}

        <Card>
          <CardHeader title="Transaction History" />
          <div className="overflow-x-auto">
            <table className="w-full text-sm text-left">
              <thead className="bg-slate-50 dark:bg-slate-800/50 text-slate-500 dark:text-slate-400 border-b border-slate-200 dark:border-slate-700">
                <tr>
                  <th className="px-6 py-3">Due Date</th>
                  <th className="px-6 py-3">Resident</th>
                  <th className="px-6 py-3">Description</th>
                  <th className="px-6 py-3">Type</th>
                  <th className="px-6 py-3">Amount</th>
                  <th className="px-6 py-3 text-right">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                {bills.map(bill => {
                  const residentName = residents.find(r => r.id === bill.userId)?.name || 'Unknown';
                  return (
                    <tr key={bill.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                      <td className="px-6 py-3 font-mono text-slate-500 dark:text-slate-400">{new Date(bill.dueDate).toLocaleDateString()}</td>
                      <td className="px-6 py-3 font-medium text-slate-900 dark:text-white">{residentName}</td>
                      <td className="px-6 py-3 text-slate-600 dark:text-slate-300">{bill.description}</td>
                      <td className="px-6 py-3"><span className="text-xs bg-slate-100 dark:bg-slate-800 px-2 py-1 rounded text-slate-500">{bill.type.replace('_', ' ')}</span></td>
                      <td className="px-6 py-3 font-bold">${bill.amount.toFixed(2)}</td>
                      <td className="px-6 py-3 text-right">
                        <span className={`px-2 py-1 rounded-full text-xs font-bold ${bill.status === BillStatus.PAID ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300' : 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300'}`}>
                          {bill.status}
                        </span>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </Card>
      </div>
    );
  }

  // --- OVERVIEW VIEW (DEFAULT) ---
  return (
    <div className="space-y-6">
      <div className="flex justify-between items-end">
        <div>
          <h2 className="text-2xl font-bold text-slate-900 dark:text-white">Estate Overview</h2>
          <p className="text-slate-500 dark:text-slate-400">{estate?.name} - {estate?.subscriptionTier} Plan</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <StatCard title="Total Passes" value={stats.totalPasses} icon={Calendar} color="bg-indigo-500" />
        <StatCard title="On Site Now" value={stats.activeVisitors} icon={Users} color="bg-green-500" />
        <StatCard title="Entries Today" value={stats.entriesToday} icon={Shield} color="bg-blue-500" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
          <Card className="h-96">
            <CardHeader title="Weekly Traffic" />
            <CardBody className="h-80">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={chartData}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" />
                  <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fill: '#94a3b8' }} />
                  <YAxis axisLine={false} tickLine={false} tick={{ fill: '#94a3b8' }} />
                  <Tooltip
                    cursor={{ fill: 'rgba(241, 245, 249, 0.5)' }}
                    contentStyle={{ backgroundColor: '#1e293b', borderColor: '#334155', color: '#fff' }}
                  />
                  <Bar dataKey="visitors" fill="#4f46e5" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </CardBody>
          </Card>
        </div>

        <div className="space-y-6">
          <Card>
            <CardHeader title="Quick Actions" />
            <CardBody className="space-y-3">
              <div className="flex items-center justify-between p-3 bg-slate-50 dark:bg-slate-800 rounded-lg">
                <div className="flex items-center gap-3">
                  <Users className="text-slate-400" size={20} />
                  <div>
                    <p className="font-bold text-slate-900 dark:text-white">{pendingUsers.length}</p>
                    <p className="text-xs text-slate-500">Pending Approvals</p>
                  </div>
                </div>
                {pendingUsers.length > 0 && <span className="h-2 w-2 rounded-full bg-red-500 animate-pulse"></span>}
              </div>

              <div className="p-4 bg-slate-900 dark:bg-slate-800 rounded-xl text-white">
                <h4 className="font-bold text-sm mb-1 flex items-center gap-2">
                  <AlertCircle size={14} className="text-yellow-400" /> Premium Feature
                </h4>
                <p className="text-xs text-slate-300 mb-3">Upgrade to remove ads for residents and export data logs.</p>
                <button className="w-full bg-white text-slate-900 text-xs font-bold py-2 rounded hover:bg-slate-100 transition-colors">
                  Upgrade Now
                </button>
              </div>
            </CardBody>
          </Card>
        </div>
      </div>
    </div>
  );
};