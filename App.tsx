import React, { useState, useEffect } from 'react';
import { User, UserRole, Estate, SubscriptionTier } from './types';
import { MockService } from './services/mockData';
import { Layout } from './components/Layout';
import { Auth } from './pages/Auth';
import { ResidentDashboard } from './modules/resident/ResidentDashboard';
import { SecurityDashboard } from './modules/security/SecurityDashboard';
import { EstateAdminDashboard } from './modules/estate-admin/EstateAdminDashboard';
import { SuperAdminDashboard } from './modules/super-admin/SuperAdminDashboard';

function App() {
  const [user, setUser] = useState<User | null>(null);
  const [estate, setEstate] = useState<Estate | undefined>(undefined);
  const [currentView, setCurrentView] = useState('dashboard');
  const [theme, setTheme] = useState<'light' | 'dark'>('light');

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

  const toggleTheme = () => {
    setTheme(prev => prev === 'light' ? 'dark' : 'light');
  };

  useEffect(() => {
    if (user) {
      if (user.role !== UserRole.SUPER_ADMIN) {
        const e = MockService.getEstate(user.estateId);
        setEstate(e);
      } else {
        setEstate(undefined); // Super Admin has no specific estate
      }

      // Set default view based on role
      if (user.role === UserRole.SECURITY) setCurrentView('scanner');
      else if (user.role === UserRole.ESTATE_ADMIN) setCurrentView('overview');
      else if (user.role === UserRole.SUPER_ADMIN) setCurrentView('overview');
      else setCurrentView('dashboard');
    }
  }, [user]);

  const handleLogout = () => {
    setUser(null);
    setEstate(undefined);
  };

  if (!user) {
    return <Auth onLogin={setUser} />;
  }

  const renderContent = () => {
    switch (user.role) {
      case UserRole.RESIDENT:
        return <ResidentDashboard user={user} showAds={estate?.subscriptionTier === SubscriptionTier.FREE} currentView={currentView} />;
      case UserRole.SECURITY:
        return <SecurityDashboard user={user} currentView={currentView} />;
      case UserRole.ESTATE_ADMIN:
        return <EstateAdminDashboard user={user} currentView={currentView} />;
      case UserRole.SUPER_ADMIN:
        return <SuperAdminDashboard user={user} currentView={currentView} />;
      default:
        return <div>Role not supported</div>;
    }
  };

  return (
    <Layout
      user={user}
      estate={estate}
      onLogout={handleLogout}
      currentView={currentView}
      onChangeView={setCurrentView}
      theme={theme}
      toggleTheme={toggleTheme}
    >
      {renderContent()}
    </Layout>
  );
}

export default App;
