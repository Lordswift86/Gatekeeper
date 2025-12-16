import React, { useState, useEffect } from 'react';
import { User, UserRole, Estate } from './types';

import { Layout } from './components/Layout';
import { Auth } from './Auth';
import { ResidentDashboard } from './modules/resident/ResidentDashboard';
import { SecurityDashboard } from './modules/security/SecurityDashboard';
import { EstateAdminDashboard } from './modules/estate-admin/EstateAdminDashboard';
import { SuperAdminDashboard } from './modules/super-admin/SuperAdminDashboard';
import api from './services/api';
import { TokenManager } from './services/apiConfig';

function App() {
  const [user, setUser] = useState<User | null>(null);
  const [estate, setEstate] = useState<Estate | undefined>(undefined);
  const [currentView, setCurrentView] = useState('dashboard');
  const [theme, setTheme] = useState<'light' | 'dark'>('light');
  const [isCheckingAuth, setIsCheckingAuth] = useState(true);

  // Initialize theme based on system preference
  useEffect(() => {
    if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
      setTheme('dark');
    }
  }, []);

  // Apply theme class to document
  useEffect(() => {
    if (theme === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [theme]);

  // Check for existing auth on mount
  useEffect(() => {
    const checkAuth = async () => {
      const token = TokenManager.getToken();

      if (token) {
        try {
          // Try to get user profile with existing token
          const userProfile = await api.getProfile();
          setUser(userProfile);
        } catch (error) {
          // Token invalid or expired, clear it
          TokenManager.clearToken();
          setUser(null);
        }
      }

      setIsCheckingAuth(false);
    };

    checkAuth();
  }, []);

  const toggleTheme = () => {
    setTheme(prev => prev === 'light' ? 'dark' : 'light');
  };

  useEffect(() => {
    if (user) {
      if (user.role !== UserRole.SUPER_ADMIN && user.estateId) {
        // Fetch estate details (except for Super Admin who has no specific estate)
        api.getEstateById(user.estateId)
          .then(e => setEstate(e))
          .catch(err => {
            console.error('Failed to load estate:', err);
            // Optional: Handle error or setEstate(undefined)
          });
      } else {
        setEstate(undefined);
      }

      // Set default view based on role
      if (user.role === UserRole.SECURITY) setCurrentView('scanner');
      else if (user.role === UserRole.ESTATE_ADMIN) setCurrentView('overview');
      else if (user.role === UserRole.SUPER_ADMIN) setCurrentView('overview');
      else setCurrentView('dashboard');
    }
  }, [user]);

  const handleLogin = (loggedInUser: User) => {
    setUser(loggedInUser);
  };

  const handleLogout = () => {
    TokenManager.clearToken();
    setUser(null);
    setEstate(undefined);
  };

  // Show loading while checking auth
  if (isCheckingAuth) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-indigo-500 to-purple-600">
        <div className="text-white text-xl">Loading...</div>
      </div>
    );
  }

  if (!user) {
    return <Auth onLogin={handleLogin} />;
  }

  const showAds = estate ? estate.subscriptionTier !== 'PREMIUM' : false;

  return (
    <Layout
      user={user}
      estate={estate}
      currentView={currentView}
      onViewChange={setCurrentView}
      onLogout={handleLogout}
      onThemeToggle={toggleTheme}
      theme={theme}
    >
      {user.role === UserRole.RESIDENT && (
        <ResidentDashboard user={user} showAds={showAds} currentView={currentView} />
      )}
      {user.role === UserRole.SECURITY && (
        <SecurityDashboard user={user} currentView={currentView} />
      )}
      {user.role === UserRole.ESTATE_ADMIN && estate && (
        <EstateAdminDashboard user={user} currentView={currentView} />
      )}
      {user.role === UserRole.SUPER_ADMIN && (
        <SuperAdminDashboard user={user} currentView={currentView} />
      )}
    </Layout>
  );
}

export default App;
