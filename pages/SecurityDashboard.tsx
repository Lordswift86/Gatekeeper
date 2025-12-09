import React, { useState, useEffect } from 'react';
import { User, GuestPass, PassStatus, LogEntry, PassType } from '../types';
import { MockService } from '../services/mockData';
import { Card, CardBody, CardHeader } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { ScanLine, LogIn, LogOut, AlertTriangle, Car, BookOpen, Wifi, WifiOff, RefreshCw, Truck, Check, Phone, Search, Mic } from 'lucide-react';

interface Props {
  user: User;
  currentView?: string;
}

interface OfflineAction {
  type: 'ENTRY' | 'EXIT';
  passId: string;
  timestamp: number;
}

export const SecurityDashboard: React.FC<Props> = ({ user, currentView = 'scanner' }) => {
  // Connectivity
  const [isOfflineMode, setIsOfflineMode] = useState(false);
  const [lastSyncTime, setLastSyncTime] = useState<number | null>(null);
  const [isSyncing, setIsSyncing] = useState(false);
  
  // Cache
  const [localCache, setLocalCache] = useState<GuestPass[]>([]);
  const [offlineQueue, setOfflineQueue] = useState<OfflineAction[]>([]);

  // Scanner
  const [code, setCode] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [scanResult, setScanResult] = useState<{ success: boolean; pass?: GuestPass; message?: string } | null>(null);

  // Deliveries
  const [deliveries, setDeliveries] = useState<GuestPass[]>([]);
  const [verifyPlate, setVerifyPlate] = useState<string>('');
  const [activeDeliveryId, setActiveDeliveryId] = useState<string | null>(null);

  // Intercom
  const [residents, setResidents] = useState<User[]>([]);
  const [searchRes, setSearchRes] = useState('');
  const [callingId, setCallingId] = useState<string | null>(null);

  // Logbook
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [manualName, setManualName] = useState('');
  const [manualDest, setManualDest] = useState('');
  const [manualNote, setManualNote] = useState('');

  // Initial Sync and Data Loading
  useEffect(() => {
    performSync();
    if (currentView === 'deliveries') loadDeliveries();
    if (currentView === 'intercom') loadResidents();
    if (currentView === 'logbook') loadLogs();

    const intervalId = setInterval(() => {
      if (!isOfflineMode) performSync();
    }, 300000);

    return () => clearInterval(intervalId);
  }, [user.estateId, isOfflineMode, currentView]);

  const loadLogs = () => { if (!isOfflineMode) setLogs(MockService.getEstateLogs(user.estateId)); };
  const loadDeliveries = () => { setDeliveries(MockService.getExpectedDeliveries(user.estateId)); };
  const loadResidents = () => { setResidents(MockService.getEstateResidents(user.estateId)); };

  const performSync = async () => {
    if (isOfflineMode) return;
    setIsSyncing(true);
    try {
      if (offlineQueue.length > 0) {
        await MockService.syncOfflineActions(offlineQueue);
        setOfflineQueue([]);
      }
      const freshData = await MockService.getOfflineData(user.estateId);
      setLocalCache(freshData);
      setLastSyncTime(Date.now());
    } catch (err) {
      console.error("Sync failed", err);
    } finally {
      setIsSyncing(false);
    }
  };

  // Scanner Handlers
  const handleScan = async (e: React.FormEvent) => {
    e.preventDefault();
    if (code.length < 5) return;
    setIsLoading(true);
    setScanResult(null);

    if (isOfflineMode) {
      setTimeout(() => {
        const pass = localCache.find(p => p.code === code);
        if (!pass) setScanResult({ success: false, message: 'Invalid Code (Offline Cache)' });
        else if (pass.status === PassStatus.CANCELLED) setScanResult({ success: false, message: 'Code cancelled' });
        else if ((pass.type === PassType.ONE_TIME || pass.type === PassType.DELIVERY) && pass.status === PassStatus.EXPIRED) setScanResult({ success: false, message: 'Code expired' });
        else setScanResult({ success: true, pass });
        setIsLoading(false);
      }, 300);
    } else {
      const result = await MockService.validateCode(code, user.estateId);
      setScanResult(result);
      setIsLoading(false);
    }
  };

  const handleAction = (action: 'ENTRY' | 'EXIT') => {
    if (!scanResult?.pass) return;
    if (isOfflineMode) {
      const actionPayload: OfflineAction = { type: action, passId: scanResult.pass.id, timestamp: Date.now() };
      setOfflineQueue(prev => [...prev, actionPayload]);
      setLocalCache(prev => prev.map(p => {
        if (p.id === scanResult.pass!.id) {
          if (action === 'ENTRY') return { ...p, status: PassStatus.CHECKED_IN, entryTime: Date.now() };
          else return { ...p, status: PassStatus.EXPIRED, exitTime: Date.now() };
        }
        return p;
      }));
      alert(`[OFFLINE] Action recorded.`);
    } else {
      action === 'ENTRY' ? MockService.processEntry(scanResult.pass.id) : MockService.processExit(scanResult.pass.id);
      alert(`${action === 'ENTRY' ? 'Entry' : 'Exit'} logged.`);
    }
    setCode('');
    setScanResult(null);
  };

  const triggerCamera = () => { setIsLoading(true); setTimeout(() => { setCode('12345'); setIsLoading(false); }, 1500); };

  // Delivery Handlers
  const handleVerifyDelivery = (passId: string) => {
    MockService.verifyDelivery(passId, verifyPlate);
    setVerifyPlate('');
    setActiveDeliveryId(null);
    loadDeliveries();
    alert("Delivery Verified and Checked In");
  };

  // Intercom Handlers
  const handleCall = (residentId: string) => {
    setCallingId(residentId);
    MockService.initiateCall(user.id, residentId);
    // Simulate call flow
    setTimeout(() => {
        setCallingId(null);
        alert("Call ended (Simulation)");
    }, 5000);
  };

  // Logbook Handlers
  const handleManualEntry = (e: React.FormEvent) => {
    e.preventDefault();
    MockService.addManualLogEntry(user.estateId, manualName, manualDest, manualNote);
    setManualName(''); setManualDest(''); setManualNote('');
    loadLogs();
  };

  // --- VIEWS ---

  if (currentView === 'logbook') {
    return (
      <div className="space-y-6">
        <h2 className="text-xl font-bold text-slate-900 dark:text-white flex items-center gap-2">
          <BookOpen className="text-indigo-600 dark:text-indigo-400" /> Manual Logbook
        </h2>
        <Card>
          <CardHeader title="Record Manual Entry" />
          <CardBody>
            <form onSubmit={handleManualEntry} className="grid grid-cols-1 md:grid-cols-4 gap-4 items-end">
              <input className="border p-2 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white" value={manualName} onChange={e => setManualName(e.target.value)} placeholder="Guest Name" required />
              <input className="border p-2 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white" value={manualDest} onChange={e => setManualDest(e.target.value)} placeholder="Destination Unit" required />
              <input className="border p-2 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white" value={manualNote} onChange={e => setManualNote(e.target.value)} placeholder="Notes" />
              <Button type="submit">Log Entry</Button>
            </form>
          </CardBody>
        </Card>
        <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden shadow-sm">
           <table className="min-w-full divide-y divide-slate-200 dark:divide-slate-800">
             <thead className="bg-slate-50 dark:bg-slate-800/50">
               <tr>
                 <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase">Time</th>
                 <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase">Guest</th>
                 <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase">Dest</th>
               </tr>
             </thead>
             <tbody className="bg-white dark:bg-slate-900 divide-y divide-slate-200 dark:divide-slate-800">
               {logs.map(log => (
                 <tr key={log.id}>
                   <td className="px-4 py-3 text-sm text-slate-500 dark:text-slate-400">{new Date(log.entryTime).toLocaleTimeString()}</td>
                   <td className="px-4 py-3 text-sm font-medium text-slate-900 dark:text-white">{log.guestName}</td>
                   <td className="px-4 py-3 text-sm text-slate-500 dark:text-slate-400">{log.destination}</td>
                 </tr>
               ))}
             </tbody>
           </table>
        </div>
      </div>
    );
  }

  if (currentView === 'deliveries') {
    return (
        <div className="space-y-6">
            <h2 className="text-xl font-bold text-slate-900 dark:text-white flex items-center gap-2">
                <Truck className="text-indigo-600 dark:text-indigo-400" /> Expected Deliveries
            </h2>
            {deliveries.length === 0 ? (
                <div className="text-center py-10 text-slate-500">No expected deliveries at the moment.</div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {deliveries.map(pass => (
                        <Card key={pass.id}>
                            <CardBody>
                                <div className="flex justify-between">
                                    <h4 className="font-bold text-lg dark:text-white">{pass.guestName}</h4>
                                    <span className="text-xs bg-indigo-100 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-300 px-2 py-1 rounded">Unit {pass.hostUnit}</span>
                                </div>
                                <p className="text-sm text-slate-500 dark:text-slate-400 mb-4">Host: {pass.hostName}</p>
                                
                                {activeDeliveryId === pass.id ? (
                                    <div className="space-y-2 animate-fade-in">
                                        <input 
                                            autoFocus
                                            className="w-full border p-2 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white" 
                                            placeholder="Enter Bike/Car Plate Number" 
                                            value={verifyPlate} 
                                            onChange={e => setVerifyPlate(e.target.value)} 
                                        />
                                        <div className="flex gap-2">
                                            <Button size="sm" fullWidth onClick={() => handleVerifyDelivery(pass.id)} disabled={!verifyPlate}>Confirm Check-In</Button>
                                            <Button size="sm" variant="ghost" onClick={() => setActiveDeliveryId(null)}>Cancel</Button>
                                        </div>
                                    </div>
                                ) : (
                                    <Button fullWidth onClick={() => setActiveDeliveryId(pass.id)}>Verify & Check In</Button>
                                )}
                            </CardBody>
                        </Card>
                    ))}
                </div>
            )}
        </div>
    );
  }

  if (currentView === 'intercom') {
      const filteredResidents = residents.filter(r => r.name.toLowerCase().includes(searchRes.toLowerCase()) || r.unitNumber?.includes(searchRes));
      return (
        <div className="space-y-6">
            <h2 className="text-xl font-bold text-slate-900 dark:text-white flex items-center gap-2">
                <Phone className="text-indigo-600 dark:text-indigo-400" /> Resident Intercom
            </h2>
            <div className="relative">
                <Search className="absolute left-3 top-3 text-slate-400" size={18} />
                <input 
                    className="w-full pl-10 p-3 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white"
                    placeholder="Search Resident Name or Unit Number..."
                    value={searchRes}
                    onChange={e => setSearchRes(e.target.value)}
                />
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {filteredResidents.map(res => (
                    <Card key={res.id}>
                        <CardBody className="flex items-center justify-between">
                            <div>
                                <h4 className="font-bold text-slate-900 dark:text-white">{res.name}</h4>
                                <p className="text-sm text-slate-500 dark:text-slate-400">Unit: {res.unitNumber}</p>
                            </div>
                            <button 
                                onClick={() => handleCall(res.id)}
                                disabled={callingId !== null}
                                className={`p-3 rounded-full transition-colors ${callingId === res.id ? 'bg-green-500 text-white animate-pulse' : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-indigo-100 hover:text-indigo-600'}`}
                            >
                                {callingId === res.id ? <Mic /> : <Phone />}
                            </button>
                        </CardBody>
                    </Card>
                ))}
            </div>
        </div>
      );
  }

  // DEFAULT: SCANNER VIEW
  return (
    <div className="max-w-lg mx-auto space-y-6">
      {/* Connectivity */}
      <div className="flex justify-between items-center">
        <h2 className="text-xl font-bold text-slate-900 dark:text-white">Scanner</h2>
        <div className="flex gap-2 items-center">
             <div className={`flex items-center gap-1 text-xs font-mono px-2 py-0.5 rounded ${isOfflineMode ? 'bg-slate-200 dark:bg-slate-700' : 'bg-green-100 dark:bg-green-900/30 text-green-700'}`}>
                {isOfflineMode ? <WifiOff size={12} /> : <Wifi size={12} />} {isOfflineMode ? 'OFFLINE' : 'ONLINE'}
             </div>
             <button onClick={() => performSync()} disabled={isOfflineMode || isSyncing} className="p-2 border rounded hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800 dark:text-slate-300">
                <RefreshCw size={16} className={isSyncing ? 'animate-spin' : ''} />
             </button>
             <button onClick={() => setIsOfflineMode(!isOfflineMode)} className="text-xs border px-2 py-1 rounded dark:border-slate-700 dark:text-slate-300">
                {isOfflineMode ? 'Reconnect' : 'Go Offline'}
             </button>
        </div>
      </div>
      
      {offlineQueue.length > 0 && (
          <div className="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-3 text-xs text-yellow-800 dark:text-yellow-200 text-center">
              {offlineQueue.length} unsynced actions stored locally.
          </div>
      )}

      <Card className="shadow-lg border-slate-300 dark:border-slate-700">
        <CardBody>
            <form onSubmit={handleScan} className="space-y-4">
                <input 
                    type="text" inputMode="numeric" maxLength={5}
                    value={code} onChange={(e) => setCode(e.target.value.replace(/[^0-9]/g, ''))}
                    className="w-full text-center text-4xl tracking-[0.5em] font-mono font-bold py-6 border-2 border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white rounded-xl focus:border-indigo-600 outline-none"
                    placeholder="ENTER CODE" autoFocus
                />
                <div className="grid grid-cols-2 gap-3">
                    <Button type="button" variant="secondary" onClick={triggerCamera} disabled={isLoading} className="py-4">
                        <ScanLine className="mr-2" /> Scan QR
                    </Button>
                    <Button type="submit" disabled={code.length !== 5 || isLoading} className="py-4">
                        {isLoading ? 'Verifying...' : 'Validate'}
                    </Button>
                </div>
            </form>
        </CardBody>
      </Card>

      {/* Result Display */}
      {scanResult && !scanResult.success && (
          <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-xl p-6 text-center animate-fade-in">
              <AlertTriangle className="text-red-600 mx-auto mb-2" size={32} />
              <h3 className="text-lg font-bold text-red-700 dark:text-red-400">Access Denied</h3>
              <p className="text-red-600 dark:text-red-300">{scanResult.message}</p>
              <Button variant="ghost" className="mt-4" onClick={() => setScanResult(null)}>Clear</Button>
          </div>
      )}

      {scanResult && scanResult.success && scanResult.pass && (
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl shadow-lg overflow-hidden animate-fade-in">
              <div className={`p-4 text-white text-center font-bold text-lg ${scanResult.pass.status === PassStatus.ACTIVE ? 'bg-green-600' : 'bg-blue-600'}`}>
                  {scanResult.pass.status === PassStatus.ACTIVE ? 'READY FOR ENTRY' : 'READY FOR EXIT'}
              </div>
              <div className="p-6 space-y-4 text-center">
                  <div>
                      <h2 className="text-2xl font-bold text-slate-900 dark:text-white">{scanResult.pass.guestName}</h2>
                      <p className="text-slate-500 dark:text-slate-400">Visiting: {scanResult.pass.hostName} ({scanResult.pass.hostUnit})</p>
                      {scanResult.pass.type === PassType.DELIVERY && (
                           <div className="mt-2 text-blue-600 dark:text-blue-400 font-bold flex items-center justify-center gap-1"><Truck size={16} /> DELIVERY</div>
                      )}
                  </div>
                  {scanResult.pass.status === PassStatus.CHECKED_IN && scanResult.pass.exitInstruction && (
                      <div className="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-3 text-left">
                          <p className="text-xs font-bold text-amber-700 uppercase">Exit Instruction</p>
                          <p className="text-amber-900 dark:text-amber-200 font-medium">{scanResult.pass.exitInstruction}</p>
                      </div>
                  )}
                  <div className="pt-2">
                      {scanResult.pass.status === PassStatus.ACTIVE && (
                          <Button fullWidth size="lg" className="bg-green-600" onClick={() => handleAction('ENTRY')}><LogIn className="mr-2" /> Grant Entry</Button>
                      )}
                      {scanResult.pass.status === PassStatus.CHECKED_IN && (
                           <Button fullWidth size="lg" className="bg-blue-600" onClick={() => handleAction('EXIT')}><LogOut className="mr-2" /> Confirm Exit</Button>
                      )}
                  </div>
              </div>
          </div>
      )}
    </div>
  );
};
