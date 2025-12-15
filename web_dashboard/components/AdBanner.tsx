import React from 'react';
import { Megaphone } from 'lucide-react';

export const AdBanner: React.FC<{ position: 'footer' | 'inline' }> = ({ position }) => {
  if (position === 'footer') {
    return (
      <div className="fixed bottom-0 left-0 right-0 bg-slate-900 text-white p-3 z-50 flex items-center justify-between px-6 shadow-lg">
        <div className="flex items-center gap-3">
          <div className="bg-white/10 p-2 rounded">
            <Megaphone size={16} className="text-yellow-400" />
          </div>
          <div className="text-sm">
            <span className="font-bold text-yellow-400">Sponsored:</span> Get 50% off Smart Locks today!
          </div>
        </div>
        <button className="text-xs text-slate-400 hover:text-white underline">Remove Ads</button>
      </div>
    );
  }

  return (
    <div className="w-full bg-slate-100 border-2 border-dashed border-slate-300 rounded-lg p-6 flex flex-col items-center justify-center text-center my-4">
      <p className="text-xs font-bold text-slate-400 uppercase tracking-wide mb-2">Advertisement</p>
      <h4 className="text-lg font-semibold text-slate-800">Best Fiber Internet in Your Estate</h4>
      <p className="text-slate-600 text-sm mt-1">Connect now for ultra-fast speeds.</p>
    </div>
  );
};