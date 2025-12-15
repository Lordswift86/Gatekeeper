// API Configuration
export const API_CONFIG = {
    baseURL: import.meta.env.VITE_API_URL || 'http://localhost:3000/api',
    timeout: 30000,
};

// Token management
const TOKEN_KEY = 'gatekeeper_token';

export const TokenManager = {
    getToken: (): string | null => {
        return localStorage.getItem(TOKEN_KEY);
    },

    setToken: (token: string): void => {
        localStorage.setItem(TOKEN_KEY, token);
    },

    clearToken: (): void => {
        localStorage.removeItem(TOKEN_KEY);
    },

    hasToken: (): boolean => {
        return !!localStorage.getItem(TOKEN_KEY);
    },
};
