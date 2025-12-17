export enum UserRole {
  SUPER_ADMIN = 'SUPER_ADMIN',
  ESTATE_ADMIN = 'ESTATE_ADMIN',
  RESIDENT = 'RESIDENT',
  SECURITY = 'SECURITY',
}

export enum PassStatus {
  ACTIVE = 'ACTIVE',
  CHECKED_IN = 'CHECKED_IN',
  EXPIRED = 'EXPIRED',
  CANCELLED = 'CANCELLED',
}

export enum PassType {
  ONE_TIME = 'ONE_TIME',
  RECURRING = 'RECURRING',
  DELIVERY = 'DELIVERY',
}

export enum SubscriptionTier {
  FREE = 'FREE',
  PREMIUM = 'PREMIUM',
}

export enum BillStatus {
  PAID = 'PAID',
  UNPAID = 'UNPAID',
}

export enum BillType {
  SERVICE_CHARGE = 'SERVICE_CHARGE',
  POWER = 'POWER',
  WASTE = 'WASTE',
  WATER = 'WATER',
  SECURITY_LEVY = 'SECURITY_LEVY',
  MAINTENANCE = 'MAINTENANCE',
  UTILITY = 'UTILITY',
  OTHER = 'OTHER',
}

export enum CallStatus {
  RINGING = 'RINGING',
  CONNECTED = 'CONNECTED',
  ENDED = 'ENDED',
}

export interface Estate {
  id: string;
  name: string;
  code: string; // Property Code for onboarding
  securityPhone?: string;
  subscriptionTier: SubscriptionTier;
  status: 'ACTIVE' | 'SUSPENDED';
}

export interface User {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  estateId: string;
  unitNumber?: string;
  isApproved: boolean; // For resident onboarding
  estate?: Estate;
}

export interface GuestPass {
  id: string;
  code: string; // 5-digit code
  hostId: string;
  hostName: string; // Denormalized for easy display
  hostUnit: string;
  guestName: string;
  exitInstruction?: string;
  status: PassStatus;
  type: PassType;
  recurringDays?: string[]; // e.g. ['Mon', 'Tue']
  recurringTimeStart?: string; // HH:mm
  recurringTimeEnd?: string; // HH:mm
  createdAt: number;
  validUntil: number; // timestamp
  entryTime?: number;
  exitTime?: number;

  // Delivery specific
  plateNumber?: string;
  deliveryCompany?: string;
}

export interface Announcement {
  id: string;
  estateId: string;
  title: string;
  content: string;
  createdAt: string;
}

export interface LogEntry {
  id: string;
  estateId: string;
  guestName: string;
  destination: string;
  entryTime: number;
  exitTime?: number;
  type: 'MANUAL' | 'DIGITAL';
  notes?: string;
}

export interface Bill {
  id: string;
  estateId: string;
  userId: string;
  type: BillType;
  amount: number;
  dueDate: number; // timestamp
  status: BillStatus;
  paidAt?: number;
  description: string;
}

export interface IntercomSession {
  id: string;
  estateId: string;
  residentId: string;
  residentName: string;
  securityId?: string; // Optional if resident initiates
  initiator: 'SECURITY' | 'RESIDENT';
  status: CallStatus;
  timestamp: number;
}

export interface ChatMessage {
  id: string;
  fromId: string;
  toId: string; // 'SECURITY' or UserID
  content: string;
  timestamp: number;
  read: boolean;
}

export interface EmergencyAlert {
  id: string;
  estateId: string;
  residentId: string;
  unitNumber: string;
  status: 'ACTIVE' | 'RESOLVED';
  timestamp: number;
}

// Super Admin Specific
export interface GlobalAd {
  id: string;
  title: string;
  content: string;
  imageUrl?: string;
  targetUrl?: string;
  impressions: number;
  isActive: boolean;
  createdAt: number;
}

export interface SystemLog {
  id: string;
  action: string;
  actor: string;
  details: string;
  timestamp: number;
  severity: 'INFO' | 'WARN' | 'CRITICAL';
}