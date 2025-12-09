import React, { useState, useEffect } from 'react';
import { User, Announcement, BillType } from '../types';
import { MockService } from '../services/mockData';
import { Card, CardBody, CardHeader } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts';
import { Users, Shield, Calendar, Check, X, Megaphone, Plus, CreditCard, DollarSign } from 'lucide-react';

interface Props {
  user: User;
}

export const AdminDashboard: React.FC<Props> = ({ user }) => {
  const [stats, setStats] = useState(MockService.getEstateStats(user.estateId));
  const [estate, setEstate] = useState(MockService.getEstate(user.estateId));
  const [pendingUsers, setPendingUsers] = useState<User[]>([]);
  const [announcements, setAnnouncements] = useState<Announcement[]>([]);
  
  // Announcement Form
  const [isPosting, setIsPosting] = useState(false);
  const [annoTitle, setAnnoTitle] = useState('');
  const [annoContent, setAnnoContent] = useState('');

  // Billing Form
  const [isBilling, setIsBilling] = useState(false);
  const [billUserEmail, setBillUserEmail] = useState('');
  const [billAmount, setBillAmount] = useState('');
  const [billType, setBillType] = useState<BillType>(BillType.SERVICE_CHARGE);
  const [billDesc, setBillDesc] = useState('');

  useEffect(() => {
    refreshData();
  }, [user.estateId]);

  const refreshData = () => {
    setStats(MockService.getEstateStats(user.estateId));
    setEstate(MockService.getEstate(user.estateId));
    setPendingUsers(MockService.getPendingUsers(user.estateId));
    setAnnouncements(MockService.getAnnouncements(user.estateId));
  };

  const handleApprove = (userId: string) => {
    MockService.approveUser(userId);
    refreshData();
  };

  const handlePostAnnouncement = (e: React.FormEvent) => {
    e.preventDefault();
    if (!annoTitle || !annoContent) return;
    MockService.createAnnouncement(user.estateId, annoTitle, annoContent);
    setAnnoTitle(''); setAnnoContent(''); setIsPosting(false);
    refreshData();
  };

  const handleIssueBill = async (e: React.FormEvent) => {
    e.preventDefault();
    // Simulate finding user
    // In a real app we would select from a dropdown list of users
    // Here we blindly assume valid email or fail silently for mock
    // In MockService we don't have getByEmail exposed easily, let's just create for "u_2" (Bob) if email matches 'bob' for demo or loop users
    // For demo simplicity, we will assume we issue to the first resident found or "u_2"
    
    // Simplification for prototype:
    const targetUserId = 'u_2'; // Hardcoded to Bob for demo flow
    
    MockService.createBill(
        user.estateId,
        targetUserId,
        billType,
        parseFloat(billAmount),
        Date.now() + 86400000 * 7, // Due in 7 days
        billDesc
    );
    
    setIsBilling(false);
    setBillAmount('');
    setBillDesc('');
    alert(`Bill issued to resident (Demo: Bob Resident)`);
  };

  // Mock Chart Data
  const chartData = [
    { name: 'Mon', visitors: 12 }, { name: 'Tue', visitors: 19 },
    { name: 'Wed', visitors: 15 }, { name: 'Thu', visitors: 22 },
    { name: 'Fri', visitors: 30 }, { name: 'Sat', visitors: 45 }, { name: 'Sun', visitors: 38 },
  ];

  const StatCard = ({ title, value, icon: Icon, color }: any) => (
    <Card>
      <CardBody className="flex items-center gap-4">
        <div className={`p-3 rounded-lg ${color}`}><Icon className="w-6 h-6 text-white" /></div>
        <div><p className="text-sm text-slate-500 dark:text-slate-400 font-medium">{title}</p><p className="text-2xl font-bold text-slate-900 dark:text-white">{value}</p></div>
      </CardBody>
    </Card>
  );

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
            {/* Billing Section */}
            <Card>
                <CardHeader title="Financial Management" action={<Button size="sm" onClick={() => setIsBilling(!isBilling)}><DollarSign size={16} className="mr-1"/> Issue Bill</Button>} />
                <CardBody>
                    {isBilling && (
                        <form onSubmit={handleIssueBill} className="bg-slate-50 dark:bg-slate-800 p-4 rounded-lg mb-4 space-y-3">
                             <div className="grid grid-cols-2 gap-3">
                                <select className="p-2 rounded border dark:bg-slate-700 dark:text-white" value={billType} onChange={e => setBillType(e.target.value as BillType)}>
                                    <option value={BillType.SERVICE_CHARGE}>Service Charge</option>
                                    <option value={BillType.POWER}>Power</option>
                                    <option value={BillType.WATER}>Water</option>
                                </select>
                                <input className="p-2 rounded border dark:bg-slate-700 dark:text-white" placeholder="Amount" type="number" value={billAmount} onChange={e => setBillAmount(e.target.value)} required />
                             </div>
                             <input className="w-full p-2 rounded border dark:bg-slate-700 dark:text-white" placeholder="Description (e.g. Oct 2023)" value={billDesc} onChange={e => setBillDesc(e.target.value)} required />
                             <div className="flex justify-end gap-2">
                                 <Button size="sm" variant="ghost" type="button" onClick={() => setIsBilling(false)}>Cancel</Button>
                                 <Button size="sm" type="submit">Issue</Button>
                             </div>
                        </form>
                    )}
                    <div className="flex items-center gap-4 text-slate-500 dark:text-slate-400 text-sm">
                        <CreditCard />
                        <p>Manage resident utility bills and service charges. Unpaid bills over 30 days automatically restrict gate access.</p>
                    </div>
                </CardBody>
            </Card>

          <Card className="h-96">
            <CardHeader title="Weekly Traffic" />
            <CardBody className="h-80">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={chartData}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" />
                  <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill: '#94a3b8'}} />
                  <YAxis axisLine={false} tickLine={false} tick={{fill: '#94a3b8'}} />
                  <Tooltip cursor={{fill: 'rgba(241, 245, 249, 0.5)'}} />
                  <Bar dataKey="visitors" fill="#4f46e5" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </CardBody>
          </Card>

            <Card>
                <CardHeader title="Announcements" action={<Button size="sm" variant="ghost" onClick={() => setIsPosting(!isPosting)}><Plus size={16} /> Post New</Button>} />
                <CardBody>
                    {isPosting && (
                        <form onSubmit={handlePostAnnouncement} className="mb-6 p-4 bg-slate-50 dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700">
                            <input className="w-full mb-2 p-2 border dark:bg-slate-900 dark:border-slate-600 dark:text-white rounded text-sm" placeholder="Title" value={annoTitle} onChange={e => setAnnoTitle(e.target.value)} required />
                            <textarea className="w-full mb-2 p-2 border dark:bg-slate-900 dark:border-slate-600 dark:text-white rounded text-sm" placeholder="Message content..." rows={2} value={annoContent} onChange={e => setAnnoContent(e.target.value)} required />
                            <div className="flex justify-end gap-2">
                                <Button type="button" size="sm" variant="ghost" onClick={() => setIsPosting(false)}>Cancel</Button>
                                <Button type="submit" size="sm">Post</Button>
                            </div>
                        </form>
                    )}
                    <div className="space-y-4">
                        {announcements.map(a => (
                            <div key={a.id} className="flex gap-3">
                                <div className="p-2 bg-yellow-100 dark:bg-yellow-900/30 rounded-lg h-fit"><Megaphone size={16} className="text-yellow-700 dark:text-yellow-500" /></div>
                                <div><h5 className="font-semibold text-sm text-slate-900 dark:text-white">{a.title}</h5><p className="text-sm text-slate-700 dark:text-slate-300">{a.content}</p></div>
                            </div>
                        ))}
                    </div>
                </CardBody>
            </Card>
        </div>

        <div className="space-y-6">
           <Card>
             <CardHeader title="Pending Approvals" />
             <CardBody>
               {pendingUsers.length === 0 ? (
                    <div className="text-center py-8 text-slate-500 dark:text-slate-400 text-sm">No new resident signups pending.</div>
               ) : (
                   <div className="space-y-4">
                       {pendingUsers.map(u => (
                           <div key={u.id} className="flex items-center justify-between p-3 bg-slate-50 dark:bg-slate-800 rounded-lg">
                               <div><p className="font-medium text-slate-900 dark:text-white">{u.name}</p><p className="text-xs text-slate-500 dark:text-slate-400">Unit: {u.unitNumber}</p></div>
                               <div className="flex gap-2">
                                   <button onClick={() => handleApprove(u.id)} className="p-1.5 bg-green-100 text-green-700 rounded"><Check size={16} /></button>
                                   <button className="p-1.5 bg-red-100 text-red-700 rounded"><X size={16} /></button>
                               </div>
                           </div>
                       ))}
                   </div>
               )}
             </CardBody>
           </Card>
           
           <Card className="bg-slate-900 text-white border-none">
             <CardBody>
                <h4 className="font-bold text-lg mb-2">Upgrade to Premium</h4>
                <p className="text-slate-300 text-sm mb-4">Remove ads for your residents and unlock detailed export logs.</p>
                <button className="w-full bg-white text-slate-900 py-2 rounded font-medium hover:bg-slate-100 transition-colors">Contact Sales</button>
             </CardBody>
           </Card>
        </div>
      </div>
    </div>
  );
};
