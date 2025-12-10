import { User, UserRole, Estate, SubscriptionTier, GuestPass, PassStatus, PassType, Announcement, LogEntry, Bill, BillStatus, BillType, IntercomSession, CallStatus, ChatMessage, EmergencyAlert, GlobalAd, SystemLog } from '../types';

// --- Seed Data ---

let ESTATES: Estate[] = [
  { id: 'est_1', name: 'Sunset Gardens', code: 'SUN01', subscriptionTier: SubscriptionTier.FREE, status: 'ACTIVE' },
  { id: 'est_2', name: 'Royal Heights', code: 'ROY02', subscriptionTier: SubscriptionTier.PREMIUM, status: 'ACTIVE' },
  { id: 'est_3', name: 'Palm Springs', code: 'PLM03', subscriptionTier: SubscriptionTier.FREE, status: 'SUSPENDED' },
];

let USERS: User[] = [
  // Super Admin
  { id: 'u_0', name: 'Super Admin', email: 'admin@gatekeeper.com', role: UserRole.SUPER_ADMIN, estateId: '', isApproved: true },
  
  // Estate Admin (Sunset Gardens - Free)
  { id: 'u_1', name: 'Alice Admin', email: 'alice@sunset.com', role: UserRole.ESTATE_ADMIN, estateId: 'est_1', isApproved: true },
  
  // Resident (Sunset Gardens - Free)
  { id: 'u_2', name: 'Bob Resident', email: 'bob@sunset.com', role: UserRole.RESIDENT, estateId: 'est_1', unitNumber: '101', isApproved: true },
  
  // Unapproved Resident (Sunset Gardens)
  { id: 'u_99', name: 'New Guy', email: 'new@sunset.com', role: UserRole.RESIDENT, estateId: 'est_1', unitNumber: '105', isApproved: false },

  // Security (Sunset Gardens - Free)
  { id: 'u_3', name: 'Sam Security', email: 'sam@sunset.com', role: UserRole.SECURITY, estateId: 'est_1', isApproved: true },
  
  // Resident (Royal Heights - Premium)
  { id: 'u_4', name: 'Richie Rich', email: 'richie@royal.com', role: UserRole.RESIDENT, estateId: 'est_2', unitNumber: 'PH-1', isApproved: true },
];

let PASSES: GuestPass[] = [
  {
    id: 'p_1',
    code: '12345',
    hostId: 'u_2',
    hostName: 'Bob Resident',
    hostUnit: '101',
    guestName: 'John Doe',
    status: PassStatus.ACTIVE,
    type: PassType.ONE_TIME,
    createdAt: Date.now() - 3600000,
    validUntil: Date.now() + 3600000 * 11,
    exitInstruction: 'Leaving with a heavy box.',
  },
  {
    id: 'p_2',
    code: '54321',
    hostId: 'u_2',
    hostName: 'Bob Resident',
    hostUnit: '101',
    guestName: 'Jane Smith',
    status: PassStatus.CHECKED_IN,
    type: PassType.ONE_TIME,
    createdAt: Date.now() - 7200000,
    validUntil: Date.now() + 3600000 * 10,
    entryTime: Date.now() - 1800000,
  }
];

let LOGS: LogEntry[] = [];

let ANNOUNCEMENTS: Announcement[] = [
  { id: 'a_1', estateId: 'est_1', title: 'Gate Maintenance', content: 'Main gate will be closed for 1 hour on Tuesday.', date: '2023-10-25' },
];

let BILLS: Bill[] = [
  { 
    id: 'b_1', 
    estateId: 'est_1', 
    userId: 'u_2', 
    type: BillType.SERVICE_CHARGE, 
    amount: 150.00, 
    dueDate: Date.now() - (86400000 * 35), // 35 days overdue
    status: BillStatus.UNPAID, 
    description: 'September 2023 Service Charge' 
  },
  { 
    id: 'b_2', 
    estateId: 'est_1', 
    userId: 'u_2', 
    type: BillType.POWER, 
    amount: 45.50, 
    dueDate: Date.now() + (86400000 * 10), // Future
    status: BillStatus.UNPAID, 
    description: 'October Power Bill' 
  }
];

let CALLS: IntercomSession[] = [];
let MESSAGES: ChatMessage[] = [];
let ALERTS: EmergencyAlert[] = [];

let GLOBAL_ADS: GlobalAd[] = [
  { id: 'ad_1', title: 'Fiber Internet Deal', content: 'Get 50% off for 3 months', impressions: 1450, isActive: true, createdAt: Date.now() },
  { id: 'ad_2', title: 'Smart Lock Promo', content: 'Secure your door today', impressions: 890, isActive: true, createdAt: Date.now() - 86400000 },
];

let SYSTEM_LOGS: SystemLog[] = [
  { id: 'log_1', action: 'LOGIN_SUCCESS', actor: 'admin@gatekeeper.com', details: 'Super Admin login from IP 192.168.1.1', timestamp: Date.now() - 300000, severity: 'INFO' },
  { id: 'log_2', action: 'ESTATE_SUSPENDED', actor: 'admin@gatekeeper.com', details: 'Suspended Estate: Palm Springs', timestamp: Date.now() - 86400000, severity: 'WARN' },
  { id: 'log_3', action: 'FAILED_LOGIN', actor: 'unknown', details: 'Failed login attempt for bob@sunset.com', timestamp: Date.now() - 120000, severity: 'WARN' },
];

// --- Service Methods ---

export const MockService = {
  login: async (email: string): Promise<User | null> => {
    // Simulate API delay
    await new Promise(resolve => setTimeout(resolve, 500));
    SYSTEM_LOGS.unshift({
        id: `log_${Date.now()}`,
        action: 'LOGIN_ATTEMPT',
        actor: email,
        details: 'User attempted login',
        timestamp: Date.now(),
        severity: 'INFO'
    });
    return USERS.find(u => u.email === email) || null;
  },

  register: async (name: string, email: string, role: UserRole, estateCode: string, unitNumber?: string): Promise<{success: boolean, message?: string, user?: User}> => {
    await new Promise(resolve => setTimeout(resolve, 800));
    
    // Check if email exists
    if (USERS.find(u => u.email === email)) {
      return { success: false, message: 'Email already exists' };
    }

    // Find Estate
    const estate = ESTATES.find(e => e.code === estateCode);
    if (!estate) {
      return { success: false, message: 'Invalid Estate Property Code' };
    }

    const newUser: User = {
      id: `u_${Date.now()}`,
      name,
      email,
      role,
      estateId: estate.id,
      unitNumber: unitNumber || '',
      isApproved: false // Requires admin approval
    };

    USERS = [...USERS, newUser];
    return { success: true, user: newUser };
  },

  getEstate: (estateId: string): Estate | undefined => {
    return ESTATES.find(e => e.id === estateId);
  },

  getAnnouncements: (estateId: string): Announcement[] => {
    return ANNOUNCEMENTS.filter(a => a.estateId === estateId);
  },

  // Resident Methods
  getUserPasses: (userId: string): GuestPass[] => {
    return PASSES.filter(p => p.hostId === userId).sort((a, b) => b.createdAt - a.createdAt);
  },

  generatePass: (
    userId: string, 
    guestName: string, 
    exitInstruction?: string, 
    type: PassType = PassType.ONE_TIME,
    schedule?: { days: string[], start: string, end: string },
    deliveryCompany?: string
  ): GuestPass => {
    const user = USERS.find(u => u.id === userId);
    if (!user) throw new Error("User not found");

    // Calculate Validity
    let validUntil = Date.now();
    if (type === PassType.ONE_TIME) validUntil += 3600000 * 12; // 12 hours
    else if (type === PassType.RECURRING) validUntil += 3600000 * 24 * 30; // 30 days
    else if (type === PassType.DELIVERY) validUntil += 1800000; // 30 mins

    const newPass: GuestPass = {
      id: `p_${Date.now()}`,
      code: Math.floor(10000 + Math.random() * 90000).toString(),
      hostId: userId,
      hostName: user.name,
      hostUnit: user.unitNumber || 'N/A',
      guestName: type === PassType.DELIVERY ? (deliveryCompany || 'Delivery') : guestName,
      deliveryCompany,
      exitInstruction,
      status: PassStatus.ACTIVE,
      type,
      recurringDays: schedule?.days,
      recurringTimeStart: schedule?.start,
      recurringTimeEnd: schedule?.end,
      createdAt: Date.now(),
      validUntil,
    };
    PASSES = [newPass, ...PASSES];
    return newPass;
  },

  cancelPass: (passId: string) => {
    PASSES = PASSES.map(p => p.id === passId ? { ...p, status: PassStatus.CANCELLED } : p);
  },

  // Security Methods
  validateCode: async (code: string, estateId: string): Promise<{ success: boolean; pass?: GuestPass; message?: string }> => {
    await new Promise(resolve => setTimeout(resolve, 800)); // Simulate network/sync

    const pass = PASSES.find(p => p.code === code);
    
    if (!pass) return { success: false, message: 'Invalid Code' };
    
    // Validate Estate mismatch
    const host = USERS.find(u => u.id === pass.hostId);
    if (host && host.estateId !== estateId) {
        return { success: false, message: 'Code belongs to a different estate.' };
    }

    if (pass.status === PassStatus.CANCELLED) return { success: false, message: 'Code has been cancelled by host.' };
    
    // Check Expiry
    if (pass.type === PassType.ONE_TIME || pass.type === PassType.DELIVERY) {
      if (pass.status === PassStatus.EXPIRED) return { success: false, message: 'Code expired.' };
      if (pass.validUntil < Date.now()) {
          pass.status = PassStatus.EXPIRED;
          return { success: false, message: 'Code expired.' };
      }
    }

    return { success: true, pass };
  },

  getExpectedDeliveries: (estateId: string): GuestPass[] => {
    return PASSES.filter(p => {
       const host = USERS.find(u => u.id === p.hostId);
       return host?.estateId === estateId && p.type === PassType.DELIVERY && p.status === PassStatus.ACTIVE;
    });
  },

  verifyDelivery: (passId: string, plateNumber: string, company?: string) => {
    PASSES = PASSES.map(p => {
      if (p.id === passId) {
        return { 
          ...p, 
          status: PassStatus.CHECKED_IN, 
          entryTime: Date.now(), 
          plateNumber,
          deliveryCompany: company || p.deliveryCompany 
        };
      }
      return p;
    });
    
    const pass = PASSES.find(p => p.id === passId);
    if (pass) {
        const estateId = USERS.find(u => u.id === pass.hostId)?.estateId || '';
        LOGS.push({
            id: `l_del_${Date.now()}`,
            estateId,
            guestName: pass.guestName,
            destination: `Unit ${pass.hostUnit}`,
            entryTime: Date.now(),
            type: 'DIGITAL',
            notes: `Delivery (${pass.deliveryCompany}) - Plate: ${plateNumber}`
        });
    }
  },

  processEntry: (passId: string) => {
    const pass = PASSES.find(p => p.id === passId);
    if (!pass) return;

    PASSES = PASSES.map(p => p.id === passId ? { ...p, status: PassStatus.CHECKED_IN, entryTime: Date.now() } : p);
    
    // Create Log Entry
    const log: LogEntry = {
      id: `l_${Date.now()}`,
      estateId: USERS.find(u => u.id === pass.hostId)?.estateId || '',
      guestName: pass.guestName,
      destination: `Unit ${pass.hostUnit}`,
      entryTime: Date.now(),
      type: 'DIGITAL',
      notes: pass.type === PassType.RECURRING ? 'Recurring Staff' : 'Guest'
    };
    LOGS.push(log);
  },

  processExit: (passId: string) => {
    const pass = PASSES.find(p => p.id === passId);
    if (!pass) return;

    const newStatus = pass.type === PassType.RECURRING ? PassStatus.ACTIVE : PassStatus.EXPIRED;

    PASSES = PASSES.map(p => p.id === passId ? { ...p, status: newStatus, exitTime: Date.now() } : p);

    // Update Log
    const lastLog = LOGS.find(l => l.guestName === pass.guestName && !l.exitTime); // Naive matching
    if (lastLog) lastLog.exitTime = Date.now();
  },

  // Offline Sync Methods
  getOfflineData: async (estateId: string): Promise<GuestPass[]> => {
    await new Promise(resolve => setTimeout(resolve, 1000));
    return PASSES.filter(p => {
      const host = USERS.find(u => u.id === p.hostId);
      return host?.estateId === estateId && (p.status === PassStatus.ACTIVE || p.status === PassStatus.CHECKED_IN);
    });
  },

  syncOfflineActions: async (actions: { type: 'ENTRY' | 'EXIT'; passId: string; timestamp: number }[]) => {
    await new Promise(resolve => setTimeout(resolve, 1500)); 

    actions.forEach(action => {
      const pass = PASSES.find(p => p.id === action.passId);
      if (!pass) return;

      if (action.type === 'ENTRY') {
        if (pass.status !== PassStatus.CHECKED_IN) { 
            pass.status = PassStatus.CHECKED_IN;
            pass.entryTime = action.timestamp;
            
            const estateId = USERS.find(u => u.id === pass.hostId)?.estateId || '';
            LOGS.push({
              id: `l_sync_${Date.now()}_${Math.random()}`,
              estateId,
              guestName: pass.guestName,
              destination: `Unit ${pass.hostUnit}`,
              entryTime: action.timestamp,
              type: 'DIGITAL',
              notes: 'Synced Entry'
            });
        }
      } else if (action.type === 'EXIT') {
        const newStatus = pass.type === PassType.RECURRING ? PassStatus.ACTIVE : PassStatus.EXPIRED;
        pass.status = newStatus;
        pass.exitTime = action.timestamp;
        
        const log = LOGS.find(l => l.guestName === pass.guestName && !l.exitTime);
        if (log) log.exitTime = action.timestamp;
      }
    });

    return { success: true };
  },

  // Logbook Methods
  addManualLogEntry: (estateId: string, guestName: string, destination: string, notes?: string) => {
    const log: LogEntry = {
      id: `ml_${Date.now()}`,
      estateId,
      guestName,
      destination,
      entryTime: Date.now(),
      type: 'MANUAL',
      notes
    };
    LOGS = [log, ...LOGS];
  },

  getEstateLogs: (estateId: string): LogEntry[] => {
    return LOGS.filter(l => l.estateId === estateId).sort((a, b) => b.entryTime - a.entryTime);
  },

  // Billing & Payments
  getUserBills: (userId: string): Bill[] => {
    return BILLS.filter(b => b.userId === userId);
  },
  
  getEstateBills: (estateId: string): Bill[] => {
    return BILLS.filter(b => b.estateId === estateId).sort((a, b) => b.dueDate - a.dueDate);
  },

  checkAccessRestricted: (userId: string): boolean => {
    const overdueLimit = Date.now() - (86400000 * 30); // 30 days ago
    const overdueBills = BILLS.filter(b => b.userId === userId && b.status === BillStatus.UNPAID && b.dueDate < overdueLimit);
    return overdueBills.length > 0;
  },

  payBill: async (billId: string) => {
    await new Promise(resolve => setTimeout(resolve, 800));
    BILLS = BILLS.map(b => b.id === billId ? { ...b, status: BillStatus.PAID, paidAt: Date.now() } : b);
  },

  createBill: (estateId: string, userId: string, type: BillType, amount: number, dueDate: number, description: string) => {
    const newBill: Bill = {
        id: `b_${Date.now()}`,
        estateId,
        userId,
        type,
        amount,
        dueDate,
        status: BillStatus.UNPAID,
        description
    };
    BILLS = [newBill, ...BILLS];
  },

  // Intercom Methods
  getEstateResidents: (estateId: string): User[] => {
    return USERS.filter(u => u.estateId === estateId && u.role === UserRole.RESIDENT);
  },

  initiateCall: (initiatorId: string, targetId: string): string => {
    const initiator = USERS.find(u => u.id === initiatorId);
    let estateId = initiator?.estateId || '';
    
    // Determine who is resident and who is security (or simplified as Resident vs Gate)
    let residentId = targetId;
    let securityId = initiatorId;
    let initiatorType: 'SECURITY' | 'RESIDENT' = 'SECURITY';

    if (initiator?.role === UserRole.RESIDENT) {
        residentId = initiatorId;
        securityId = targetId || 'GATE'; // If target undefined, assume general gate
        initiatorType = 'RESIDENT';
    } else {
        // Security calling resident
        residentId = targetId;
        securityId = initiatorId;
    }
    
    const resident = USERS.find(u => u.id === residentId);
    estateId = resident?.estateId || estateId;

    const call: IntercomSession = {
        id: `call_${Date.now()}`,
        estateId,
        residentId,
        residentName: resident?.name || 'Resident',
        securityId,
        initiator: initiatorType,
        status: CallStatus.RINGING,
        timestamp: Date.now()
    };
    CALLS.push(call);
    return call.id;
  },

  endCall: (callId: string) => {
    CALLS = CALLS.map(c => c.id === callId ? { ...c, status: CallStatus.ENDED } : c);
  },

  answerCall: (callId: string) => {
    CALLS = CALLS.map(c => c.id === callId ? { ...c, status: CallStatus.CONNECTED } : c);
  },

  getIncomingCall: (userId: string): IntercomSession | undefined => {
    // Return calls where the user is the target
    return CALLS.find(c => {
        const isTarget = c.initiator === 'SECURITY' ? c.residentId === userId : c.securityId === 'GATE'; // Simulating gate receiving all resident calls
        return isTarget && 
        (c.status === CallStatus.RINGING || c.status === CallStatus.CONNECTED) && 
        c.timestamp > Date.now() - 60000;
    });
  },

  // Chat Methods
  sendMessage: (fromId: string, toId: string, content: string) => {
    const msg: ChatMessage = {
      id: `msg_${Date.now()}`,
      fromId,
      toId,
      content,
      timestamp: Date.now(),
      read: false
    };
    MESSAGES.push(msg);
  },

  getMessages: (userId: string, contactId: string): ChatMessage[] => {
    return MESSAGES.filter(m => 
      (m.fromId === userId && m.toId === contactId) || 
      (m.fromId === contactId && m.toId === userId) ||
      (m.fromId === contactId && m.toId === 'GATE' && userId === 'u_3') || // Hack for demo security ID
      (m.fromId === userId && m.toId === 'GATE')
    ).sort((a, b) => a.timestamp - b.timestamp);
  },

  // SOS Methods
  sendSOS: (estateId: string, residentId: string, unitNumber: string) => {
    const alert: EmergencyAlert = {
      id: `alert_${Date.now()}`,
      estateId,
      residentId,
      unitNumber,
      status: 'ACTIVE',
      timestamp: Date.now()
    };
    ALERTS.push(alert);
    SYSTEM_LOGS.unshift({
        id: `log_sos_${Date.now()}`,
        action: 'SOS_ALERT',
        actor: residentId,
        details: `Emergency triggered by Unit ${unitNumber}`,
        timestamp: Date.now(),
        severity: 'CRITICAL'
    });
  },

  getActiveAlerts: (estateId: string): EmergencyAlert[] => {
    return ALERTS.filter(a => a.estateId === estateId && a.status === 'ACTIVE');
  },

  resolveAlert: (alertId: string) => {
    ALERTS = ALERTS.map(a => a.id === alertId ? { ...a, status: 'RESOLVED' } : a);
  },

  // Admin Stats & Methods
  getEstateStats: (estateId: string) => {
    const estateUsers = USERS.filter(u => u.estateId === estateId);
    const estatePasses = PASSES.filter(p => estateUsers.some(u => u.id === p.hostId));
    
    const totalPasses = estatePasses.length;
    const activeVisitors = estatePasses.filter(p => p.status === PassStatus.CHECKED_IN).length;
    const entriesToday = LOGS.filter(l => l.estateId === estateId && l.entryTime > Date.now() - 86400000).length;
    return { totalPasses, activeVisitors, entriesToday };
  },

  getPendingUsers: (estateId: string): User[] => {
    return USERS.filter(u => u.estateId === estateId && !u.isApproved);
  },

  approveUser: (userId: string) => {
    USERS = USERS.map(u => u.id === userId ? { ...u, isApproved: true } : u);
  },
  
  rejectUser: (userId: string) => {
    USERS = USERS.filter(u => u.id !== userId);
  },

  createAnnouncement: (estateId: string, title: string, content: string) => {
    const newAnnouncement: Announcement = {
      id: `a_${Date.now()}`,
      estateId,
      title,
      content,
      date: new Date().toISOString().split('T')[0]
    };
    ANNOUNCEMENTS = [newAnnouncement, ...ANNOUNCEMENTS];
  },

  // Super Admin Methods
  getAllEstates: (): Estate[] => {
    return ESTATES;
  },

  createEstate: (name: string, code: string, tier: SubscriptionTier) => {
    const newEstate: Estate = {
        id: `est_${Date.now()}`,
        name,
        code: code.toUpperCase(),
        subscriptionTier: tier,
        status: 'ACTIVE'
    };
    ESTATES = [...ESTATES, newEstate];
    SYSTEM_LOGS.unshift({
        id: `log_est_${Date.now()}`,
        action: 'CREATE_ESTATE',
        actor: 'SUPER_ADMIN',
        details: `Created estate: ${name} (${code})`,
        timestamp: Date.now(),
        severity: 'INFO'
    });
  },

  toggleEstateTier: (estateId: string) => {
    ESTATES = ESTATES.map(e => {
      if (e.id === estateId) {
        return {
          ...e,
          subscriptionTier: e.subscriptionTier === SubscriptionTier.FREE ? SubscriptionTier.PREMIUM : SubscriptionTier.FREE
        };
      }
      return e;
    });
  },

  toggleEstateStatus: (estateId: string) => {
    ESTATES = ESTATES.map(e => {
        if (e.id === estateId) {
            const newStatus = e.status === 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE';
            SYSTEM_LOGS.unshift({
                id: `log_stat_${Date.now()}`,
                action: newStatus === 'SUSPENDED' ? 'SUSPEND_ESTATE' : 'ACTIVATE_ESTATE',
                actor: 'SUPER_ADMIN',
                details: `${newStatus} estate: ${e.name}`,
                timestamp: Date.now(),
                severity: 'WARN'
            });
            return {
                ...e,
                status: newStatus
            };
        }
        return e;
    });
  },

  getGlobalStats: () => {
    return {
      totalEstates: ESTATES.length,
      totalUsers: USERS.length,
      adImpressions: GLOBAL_ADS.reduce((acc, curr) => acc + curr.impressions, 0)
    };
  },

  // Super Admin Extended Controls
  getAllUsers: (): User[] => {
    return USERS;
  },

  deleteUser: (userId: string) => {
    const user = USERS.find(u => u.id === userId);
    USERS = USERS.filter(u => u.id !== userId);
    SYSTEM_LOGS.unshift({
        id: `log_del_${Date.now()}`,
        action: 'DELETE_USER',
        actor: 'SUPER_ADMIN',
        details: `Deleted user: ${user?.email}`,
        timestamp: Date.now(),
        severity: 'CRITICAL'
    });
  },

  getGlobalAds: (): GlobalAd[] => {
    return GLOBAL_ADS;
  },

  createGlobalAd: (title: string, content: string) => {
    const newAd: GlobalAd = {
      id: `ad_${Date.now()}`,
      title,
      content,
      impressions: 0,
      isActive: true,
      createdAt: Date.now()
    };
    GLOBAL_ADS = [newAd, ...GLOBAL_ADS];
  },

  updateGlobalAd: (adId: string, title: string, content: string, isActive: boolean) => {
    GLOBAL_ADS = GLOBAL_ADS.map(ad =>
      ad.id === adId ? { ...ad, title, content, isActive } : ad
    );
  },

  deleteGlobalAd: (adId: string) => {
    GLOBAL_ADS = GLOBAL_ADS.filter(a => a.id !== adId);
  },

  getSystemLogs: (): SystemLog[] => {
    return SYSTEM_LOGS.sort((a, b) => b.timestamp - a.timestamp);
  }
};