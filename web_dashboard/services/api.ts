import axios, { AxiosInstance, AxiosError } from 'axios';
import { API_CONFIG, TokenManager } from './apiConfig';
import { User, Estate, Bill, GuestPass } from '../types';

// Create axios instance
const axiosInstance: AxiosInstance = axios.create({
    baseURL: API_CONFIG.baseURL,
    timeout: API_CONFIG.timeout,
    headers: {
        'Content-Type': 'application/json',
    },
});

// Request interceptor - add token to requests
axiosInstance.interceptors.request.use(
    (config) => {
        const token = TokenManager.getToken();
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
    },
    (error) => Promise.reject(error)
);

// Response interceptor - handle errors
axiosInstance.interceptors.response.use(
    (response) => response,
    (error: AxiosError) => {
        if (error.response?.status === 401) {
            TokenManager.clearToken();
            window.location.href = '/';
        }
        return Promise.reject(error);
    }
);

// API Service
export const api = {
    // ============= Authentication =============

    async login(email: string, password: string): Promise<{ user: User; token: string }> {
        const { data } = await axiosInstance.post('/auth/login', { email, password });
        if (data.accessToken) {
            TokenManager.setToken(data.accessToken);
        }
        return data;
    },

    async register(userData: {
        name: string;
        email: string;
        password: string;
        role: string;
        estateCode: string;
        unitNumber?: string;
    }): Promise<{ user: User }> {
        const { data } = await axiosInstance.post('/auth/register', userData);
        return data;
    },

    logout(): void {
        TokenManager.clearToken();
    },

    // ============= Estates =============

    async getAllEstates(): Promise<Estate[]> {
        const { data } = await axiosInstance.get('/estates');
        return data;
    },

    async getEstateById(id: string): Promise<Estate> {
        const { data } = await axiosInstance.get(`/estates/${id}`);
        return data;
    },

    async createEstate(estateData: {
        name: string;
        code: string;
        tier: string;
    }): Promise<Estate> {
        const { data } = await axiosInstance.post('/estates', estateData);
        return data;
    },

    async toggleEstateStatus(id: string): Promise<Estate> {
        const { data } = await axiosInstance.put(`/estates/${id}/status`);
        return data;
    },

    async updateEstate(id: string, updates: Partial<Estate>): Promise<Estate> {
        const { data } = await axiosInstance.put(`/estates/${id}`, updates);
        return data;
    },

    async getEstateStats(estateId?: string): Promise<any> {
        const { data } = await axiosInstance.get('/estates/stats');
        return data;
    },

    // ============= Users =============

    async getProfile(): Promise<User> {
        const { data } = await axiosInstance.get('/users/profile');
        return data;
    },

    async updateProfile(updates: Partial<User>): Promise<User> {
        const { data } = await axiosInstance.put('/users/profile', updates);
        return data;
    },

    async getAllUsers(): Promise<User[]> {
        const { data } = await axiosInstance.get('/users');
        return data;
    },

    async getPendingUsers(): Promise<User[]> {
        const { data } = await axiosInstance.get('/users/pending');
        return data;
    },

    async approveUser(userId: string): Promise<void> {
        await axiosInstance.post(`/users/${userId}/approve`);
    },

    async getAllResidents(): Promise<User[]> {
        const { data } = await axiosInstance.get('/users/residents');
        return data;
    },

    async deleteUser(userId: string): Promise<void> {
        await axiosInstance.delete(`/users/${userId}`);
    },

    // ============= Guest Passes =============

    async getMyPasses(): Promise<GuestPass[]> {
        const { data } = await axiosInstance.get('/passes/my-passes');
        return data;
    },

    async generatePass(passData: {
        guestName: string;
        type: string;
        validUntil?: string;
        exitInstruction?: string;
        deliveryCompany?: string;
        recurringDays?: string[];
        recurringTimeStart?: string;
        recurringTimeEnd?: string;
    }): Promise<GuestPass> {
        const { data } = await axiosInstance.post('/passes/generate', passData);
        return data;
    },

    async validatePass(code: string): Promise<any> {
        const { data } = await axiosInstance.post('/passes/validate', { code });
        return data;
    },

    async processEntry(passId: string): Promise<void> {
        await axiosInstance.post(`/passes/${passId}/entry`);
    },

    async processExit(passId: string): Promise<void> {
        await axiosInstance.post(`/passes/${passId}/exit`);
    },

    async cancelPass(passId: string): Promise<void> {
        await axiosInstance.delete(`/passes/${passId}`);
    },

    async triggerSOS(location?: string): Promise<void> {
        await axiosInstance.post('/security/alert', { location });
    },

    // ============= Bills =============

    async getMyBills(): Promise<Bill[]> {
        const { data } = await axiosInstance.get('/bills/my');
        return data;
    },

    async getEstateBills(): Promise<Bill[]> {
        const { data } = await axiosInstance.get('/bills/estate');
        return data;
    },

    async createBill(billData: {
        userId: string;
        type: string;
        amount: number;
        dueDate: string;
        description: string;
    }): Promise<Bill> {
        const { data } = await axiosInstance.post('/bills', billData);
        return data;
    },

    async payBill(billId: string): Promise<Bill> {
        const { data } = await axiosInstance.post(`/bills/${billId}/pay`);
        return data;
    },

    // ============= Security / Logs =============

    async getSecurityLogs(): Promise<any[]> {
        const { data } = await axiosInstance.get('/security/logs');
        return data;
    },

    async addManualLog(logData: {
        guestName: string;
        destination: string;
        notes?: string;
    }): Promise<any> {
        const { data } = await axiosInstance.post('/security/logs', logData);
        return data;
    },

    // ============= Announcements =============

    async getAnnouncements(): Promise<any[]> {
        const { data } = await axiosInstance.get('/security/announcements');
        return data;
    },

    async createAnnouncement(announcementData: {
        title: string;
        content: string;
    }): Promise<any> {
        const { data } = await axiosInstance.post('/security/announcements', announcementData);
        return data;
    },

    // ============= Global Ads (Super Admin) =============

    async getGlobalAds(): Promise<any[]> {
        const { data } = await axiosInstance.get('/admin/global-ads');
        return data;
    },

    async createGlobalAd(adData: {
        title: string;
        content: string;
        imageUrl?: string;
    }): Promise<any> {
        const { data } = await axiosInstance.post('/admin/global-ads', adData);
        return data;
    },

    async updateGlobalAd(id: string, adData: Partial<any>): Promise<any> {
        const { data } = await axiosInstance.put(`/admin/global-ads/${id}`, adData);
        return data;
    },

    async deleteGlobalAd(id: string): Promise<void> {
        await axiosInstance.delete(`/admin/global-ads/${id}`);
    },

    // ============= Platform Stats (Super Admin) =============

    async getPlatformStats(): Promise<any> {
        const { data } = await axiosInstance.get('/admin/stats');
        return data;
    },

    async getSystemLogs(filters?: any): Promise<any[]> {
        const { data } = await axiosInstance.get('/admin/system-logs', { params: filters });
        return data;
    },
};

export default api;
