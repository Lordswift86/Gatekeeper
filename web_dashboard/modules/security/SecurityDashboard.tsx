import React, { useState, useEffect, useRef } from 'react';
import { User, GuestPass, PassStatus, LogEntry, PassType, ChatMessage, EmergencyAlert } from '../../types';
import api from '../../services/api';
import { Card, CardBody, CardHeader } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { ScanLine, LogIn, LogOut, AlertTriangle, Car, BookOpen, Wifi, WifiOff, RefreshCw, Truck, Check, Phone, Search, Mic, MessageSquare, Send, X, Siren } from 'lucide-react';

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

  // Logbook
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [manualName, setManualName] = useState('');
  const [manualDest, setManualDest] = useState('');
  const [manualNote, setManualNote] = useState('');

  // Initial Sync and Data Loading
  useEffect(() => {
    performSync();
    if (currentView === 'deliveries') loadDeliveries();
    if (currentView === 'logbook') loadLogs();

    const intervalId = setInterval(() => {
      if (!isOfflineMode) performSync();
    }, 300000); // Sync every 5 minutes

    return () => clearInterval(intervalId);
  }, [user.estateId, isOfflineMode, currentView]);

  // Sync and Load Functions
  const performSync = async () => {
    if (isOfflineMode) return;
    setIsSyncing(true);

    try {
      // Sync offline queue if any
      if (offlineQueue.length > 0) {
        for (const action of offlineQueue) {
          try {
            if (action.type === 'ENTRY') {
              await api.processEntry(action.passId);
            } else {
              await api.processExit(action.passId);
            }
          } catch (error) {
            console.error('Failed to sync action:', error);
          }
        }
        setOfflineQueue([]);
      }

      setLastSyncTime(Date.now());
    } catch (error: any) {
      console.error('Sync failed:', error);
      if (error.message?.includes('Network') || error.message?.includes('Failed to fetch')) {
        setIsOfflineMode(true);
      }
    } finally {
      setIsSyncing(false);
    }
  };

  const loadDeliveries = async () => {
    try {
      const passes = await api.getMyPasses();
      const deliveryPasses = passes.filter(p =>
        p.type === PassType.DELIVERY &&
        (p.status === PassStatus.ACTIVE || p.status === PassStatus.CHECKED_IN)
      );
      setDeliveries(deliveryPasses);
    } catch (error) {
      console.error('Failed to load deliveries:', error);
    }
  };

  const loadLogs = async () => {
    try {
      const logsData = await api.getSecurityLogs();
      setLogs(logsData);
    } catch (error) {
      console.error('Failed to load logs:', error);
    }
  };

  // Scanner Handlers
  const handleScan = async (e: React.FormEvent) => {
    e.preventDefault();
    if (code.length < 5) return;
    setIsLoading(true);
    setScanResult(null);

    try {
      const result = await api.validatePass(code);
      setScanResult(result);
    } catch (error) {
      setScanResult({ success: false, message: 'Invalid or expired code' });
    } finally {
      setIsLoading(false);
    }
  };

  const handleAction = async (action: 'ENTRY' | 'EXIT') => {
    if (!scanResult?.pass) return;

    if (isOfflineMode) {
      const actionPayload: OfflineAction = { type: action, passId: scanResult.pass.id, timestamp: Date.now() };
      setOfflineQueue(prev => [...prev, actionPayload]);
      alert(`[OFFLINE] Action queued for sync`);
    } else {
      try {
        if (action === 'ENTRY') {
          await api.processEntry(scanResult.pass.id);
        } else {
          await api.processExit(scanResult.pass.id);
        }
        alert(`${action === 'ENTRY' ? 'Entry' : 'Exit'} logged successfully`);
      } catch (error) {
        console.error('Action failed:', error);
        alert('Failed to process action. Try again.');
      }
    }

    setCode('');
    setScanResult(null);
    await performSync();
  };

  // Logbook Handlers
  const handleManualLog = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!manualName || !manualDest) return;

    try {
      await api.createManualLog({
        guestName: manualName,
        destination: manualDest,
        notes: manualNote
      });

      setManualName('');
      setManualDest('');
      setManualNote('');
      await loadLogs();
      alert('Manual entry logged successfully');
    } catch (error) {
      console.error('Failed to create manual log:', error);
      alert('Failed to log entry');
    }
  };

  const triggerCamera = () => {
    setIsLoading(true);
    // Simulate QR scan - in production, integrate with device camera
    setTimeout(() => {
      setCode('12345');
      setIsLoading(false);
    }, 1500);
  };

  // --- SCANNER VIEW ---
  if (currentView === 'scanner') {
    return (
      <div className="space-y-6">
        {/* Sync Status Banner */}
        <Card>
          <CardBody>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                {isOfflineMode ? (
                  <>
                    <WifiOff className="text-orange-500" size={24} />
                    <div>
                      <p className="font-medium text-slate-900 dark:text-white">Offline Mode</p>
                      <p className="text-xs text-slate-500 dark:text-slate-400">
                        {offlineQueue.length} actions queued for sync
                      </p>
                    </div>
                  </>
                ) : (
                  <>
                    <Wifi className="text-green-500" size={24} />
                    <div>
                      <p className="font-medium text-slate-900 dark:text-white">Online</p>
                      {lastSyncTime && (
                        <p className="text-xs text-slate-500 dark:text-slate-400">
                          Last sync: {new Date(lastSyncTime).toLocaleTimeString()}
                        </p>
                      )}
                    </div>
                  </>
                )}
              </div>
              <Button
                onClick={performSync}
                variant="ghost"
                size="sm"
                disabled={isSyncing || isOfflineMode}
              >
                <RefreshCw className={isSyncing ? 'animate-spin' : ''} size={16} />
                {isSyncing ? 'Syncing...' : 'Sync Now'}
              </Button>
            </div>
          </CardBody>
        </Card>

        {/* Scanner Card */}
        <Card>
          <CardHeader title="Access Code Scanner" />
          <CardBody>
            <form onSubmit={handleScan} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                  Enter 5-digit code or scan QR
                </label>
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={code}
                    onChange={e => setCode(e.target.value.replace(/\D/g, '').slice(0, 5))}
                    className="flex-1 border p-3 rounded-lg text-center text-2xl font-mono dark:bg-slate-800 dark:border-slate-700 dark:text-white"
                    placeholder="12345"
                    maxLength={5}
                    disabled={isLoading}
                  />
                  <Button type="button" onClick={triggerCamera} disabled={isLoading}>
                    <ScanLine size={20} />
                  </Button>
                </div>
              </div>
              <Button type="submit" fullWidth isLoading={isLoading}>
                Validate Code
              </Button>
            </form>

            {/* Scan Result */}
            {scanResult && (
              <div className={`mt-6 p-4 rounded-lg ${scanResult.success ? 'bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800' : 'bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800'}`}>
                {scanResult.success && scanResult.pass ? (
                  <div>
                    <div className="flex items-center gap-2 mb-3">
                      <Check className="text-green-600 dark:text-green-400" size={24} />
                      <p className="font-bold text-green-900 dark:text-green-100">Valid Code</p>
                    </div>
                    <div className="grid grid-cols-2 gap-2 text-sm mb-4">
                      <div>
                        <p className="text-slate-500 dark:text-slate-400">Guest:</p>
                        <p className="font-medium text-slate-900 dark:text-white">{scanResult.pass.guestName}</p>
                      </div>
                      <div>
                        <p className="text-slate-500 dark:text-slate-400">Type:</p>
                        <p className="font-medium text-slate-900 dark:text-white">{scanResult.pass.type}</p>
                      </div>
                      <div>
                        <p className="text-slate-500 dark:text-slate-400">Status:</p>
                        <p className="font-medium text-slate-900 dark:text-white">{scanResult.pass.status}</p>
                      </div>
                      {scanResult.pass.exitInstruction && (
                        <div className="col-span-2">
                          <p className="text-slate-500 dark:text-slate-400">Notes:</p>
                          <p className="text-sm text-slate-700 dark:text-slate-300">{scanResult.pass.exitInstruction}</p>
                        </div>
                      )}
                    </div>
                    <div className="flex gap-2">
                      <Button onClick={() => handleAction('ENTRY')} fullWidth>
                        <LogIn size={16} className="mr-2" /> Process Entry
                      </Button>
                      <Button onClick={() => handleAction('EXIT')} variant="ghost" fullWidth>
                        <LogOut size={16} className="mr-2" /> Process Exit
                      </Button>
                    </div>
                  </div>
                ) : (
                  <div className="flex items-center gap-2">
                    <X className="text-red-600 dark:text-red-400" size={24} />
                    <p className="font-medium text-red-900 dark:text-red-100">{scanResult.message}</p>
                  </div>
                )}
              </div>
            )}
          </CardBody>
        </Card>
      </div>
    );
  }

  // --- DELIVERIES VIEW ---
  if (currentView === 'deliveries') {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold text-slate-900 dark:text-white">Expected Deliveries</h2>
            <p className="text-slate-500 dark:text-slate-400">Verify and check in delivery personnel</p>
          </div>
          <Button onClick={loadDeliveries} size="sm">
            <RefreshCw size={16} className="mr-2" /> Refresh
          </Button>
        </div>

        {deliveries.length === 0 ? (
          <Card>
            <CardBody>
              <div className="text-center py-12">
                <Truck className="w-16 h-16 mx-auto text-slate-300 dark:text-slate-700 mb-4" />
                <p className="text-slate-500 dark:text-slate-400">No pending deliveries</p>
              </div>
            </CardBody>
          </Card>
        ) : (
          <div className="grid gap-4">
            {deliveries.map(delivery => (
              <Card key={delivery.id}>
                <CardBody>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                      <div className="p-3 bg-orange-100 dark:bg-orange-900/30 rounded-lg">
                        <Truck className="w-6 h-6 text-orange-600 dark:text-orange-400" />
                      </div>
                      <div>
                        <p className="font-medium text-slate-900 dark:text-white">{delivery.deliveryCompany || 'Delivery Service'}</p>
                        <p className="text-sm text-slate-500 dark:text-slate-400">Code: {delivery.code}</p>
                        <p className="text-xs text-slate-400 dark:text-slate-500">
                          For: Unit {delivery.hostUnitNumber || 'N/A'}
                        </p>
                      </div>
                    </div>
                    <div>
                      <span className={`px-3 py-1 rounded-full text-xs font-bold ${delivery.status === PassStatus.ACTIVE
                          ? 'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300'
                          : 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300'
                        }`}>
                        {delivery.status}
                      </span>
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

  // --- LOGBOOK VIEW ---
  if (currentView === 'logbook') {
    return (
      <div className="space-y-6">
        <div>
          <h2 className="text-2xl font-bold text-slate-900 dark:text-white mb-2">Security Logbook</h2>
          <p className="text-slate-500 dark:text-slate-400">Track all entries and exits</p>
        </div>

        {/* Manual Entry Form */}
        <Card>
          <CardHeader title="Add Manual Entry" />
          <CardBody>
            <form onSubmit={handleManualLog} className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Guest Name</label>
                <input
                  className="w-full border p-2 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white"
                  placeholder="John Doe"
                  value={manualName}
                  onChange={e => setManualName(e.target.value)}
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Destination</label>
                <input
                  className="w-full border p-2 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white"
                  placeholder="e.g., Unit 12"
                  value={manualDest}
                  onChange={e => setManualDest(e.target.value)}
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Notes (Optional)</label>
                <input
                  className="w-full border p-2 rounded dark:bg-slate-800 dark:border-slate-700 dark:text-white"
                  placeholder="Additional info"
                  value={manualNote}
                  onChange={e => setManualNote(e.target.value)}
                />
              </div>
              <div className="md:col-span-3">
                <Button type="submit">
                  <BookOpen size={16} className="mr-2" /> Add Entry
                </Button>
              </div>
            </form>
          </CardBody>
        </Card>

        {/* Logs Table */}
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full text-sm text-left">
              <thead className="text-xs text-slate-700 dark:text-slate-300 uppercase bg-slate-50 dark:bg-slate-800 border-b">
                <tr>
                  <th className="px-6 py-4">Time</th>
                  <th className="px-6 py-4">Guest</th>
                  <th className="px-6 py-4">Destination</th>
                  <th className="px-6 py-4">Action</th>
                  <th className="px-6 py-4">Notes</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                {logs.map(log => (
                  <tr key={log.id} className="bg-white dark:bg-slate-900 hover:bg-slate-50 dark:hover:bg-slate-800">
                    <td className="px-6 py-4 text-slate-600 dark:text-slate-400">
                      {new Date(log.timestamp).toLocaleString()}
                    </td>
                    <td className="px-6 py-4 font-medium text-slate-900 dark:text-white">{log.guestName}</td>
                    <td className="px-6 py-4 text-slate-600 dark:text-slate-400">{log.destination}</td>
                    <td className="px-6 py-4">
                      <span className={`px-2 py-1 rounded text-xs font-bold ${log.action === 'ENTRY'
                          ? 'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300'
                          : 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300'
                        }`}>
                        {log.action}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-500 dark:text-slate-400">{log.notes || '-'}</td>
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