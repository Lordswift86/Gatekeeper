import React, { useState, useEffect } from 'react';
import { User, GuestPass, PassStatus, PassType, Bill, BillStatus } from '../../types';
import { MockService } from '../../services/mockData';
import { Card, CardHeader, CardBody } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { Plus, Clock, Share2, Trash2, UserCheck, Truck, AlertOctagon, CheckCircle, Wallet, AlertCircle, CreditCard, Lock, X, History, Bell, Shield, Key, Gamepad2, Ghost, Heart, Star, Zap, Cloud, Moon, Sun, Anchor, Coffee, Music, Smile, Trophy, RefreshCw, ArrowRight, Crown, Flag, Flame, Plane, Rocket, Scissors, Umbrella, Gift, Globe, Camera, Phone, Siren } from 'lucide-react';
import { AdBanner } from '../../components/AdBanner';

interface Props {
  user: User;
  showAds: boolean;
  currentView: string;
}

// Game Types
interface GameCard {
  id: number;
  iconId: number;
  isFlipped: boolean;
  isMatched: boolean;
}

const GAME_ICONS = [
  Ghost, Heart, Star, Zap, Cloud, Moon, 
  Sun, Anchor, Coffee, Music, Smile, Trophy,
  Flag, Flame, Plane, Rocket, Scissors, Umbrella, 
  Gift, Globe, Camera, Key, Lock, Bell
];

export const ResidentDashboard: React.FC<Props> = ({ user, showAds, currentView }) => {
  const [passes, setPasses] = useState<GuestPass[]>([]);
  const [bills, setBills] = useState<Bill[]>([]);
  const [isAccessRestricted, setIsAccessRestricted] = useState(false);
  const [estateName, setEstateName] = useState('');

  // Form State
  const [isCreating, setIsCreating] = useState(false);
  const [createType, setCreateType] = useState<PassType>(PassType.ONE_TIME);
  const [guestName, setGuestName] = useState('');
  const [exitInstruction, setExitInstruction] = useState('');
  
  // Recurring Form State
  const [recurringStart, setRecurringStart] = useState('08:00');
  const [recurringEnd, setRecurringEnd] = useState('18:00');
  const [selectedDays, setSelectedDays] = useState<string[]>(['Mon', 'Tue', 'Wed', 'Thu', 'Fri']);
  
  // Delivery State
  const [deliveryCompany, setDeliveryCompany] = useState('');

  // Payment Modal State
  const [paymentModalOpen, setPaymentModalOpen] = useState(false);
  const [selectedBill, setSelectedBill] = useState<Bill | null>(null);
  const [paymentProcessing, setPaymentProcessing] = useState(false);
  const [cardDetails, setCardDetails] = useState({ number: '', expiry: '', cvv: '', name: user.name });
  
  // Settings State
  const [notificationsEnabled, setNotificationsEnabled] = useState(true);
  const [privacyEnabled, setPrivacyEnabled] = useState(true);

  // SOS State
  const [sosActive, setSosActive] = useState(false);

  // Game State
  const [gameCards, setGameCards] = useState<GameCard[]>([]);
  const [flippedIndices, setFlippedIndices] = useState<number[]>([]);
  const [moves, setMoves] = useState(0);
  const [allowedMoves, setAllowedMoves] = useState(0);
  const [isGameWon, setIsGameWon] = useState(false);
  const [stage, setStage] = useState(1);
  const MAX_STAGE = 20;

  const DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  useEffect(() => {
    loadData();
    const restricted = MockService.checkAccessRestricted(user.id);
    setIsAccessRestricted(restricted);
  }, [user.id, currentView]);

  useEffect(() => {
    if (currentView === 'game') {
      initializeGame(stage);
    }
  }, [currentView]);

  // Game Logic
  const initializeGame = (currentStage: number) => {
    // Formula: starting 2x2 (4 tiles) and increase by 2 tiles per stage
    const tileCount = 4 + (currentStage - 1) * 2;
    const pairCount = tileCount / 2;
    
    // Formula: x = (number of tiles * 2) - (number of tiles / 2)
    const maxMovesAllowed = Math.floor((tileCount * 2) - (tileCount / 2));
    setAllowedMoves(maxMovesAllowed);

    // Select icons
    const selectedIcons = GAME_ICONS.slice(0, pairCount);
    // Ensure we have enough icons, if pairCount exceeds GAME_ICONS length, reuse (though we added enough)
    const iconsToUse = selectedIcons.length < pairCount 
        ? [...selectedIcons, ...GAME_ICONS.slice(0, pairCount - selectedIcons.length)]
        : selectedIcons;

    const pairs = [...iconsToUse, ...iconsToUse];
    
    // Shuffle
    const shuffled = pairs
      .map((icon) => ({ icon, sort: Math.random() }))
      .sort((a, b) => a.sort - b.sort)
      .map((item, index) => ({
        id: index,
        iconId: GAME_ICONS.indexOf(item.icon),
        isFlipped: false,
        isMatched: false
      }));

    setGameCards(shuffled);
    setFlippedIndices([]);
    setMoves(0);
    setIsGameWon(false);
  };

  const handleNextStage = () => {
    if (stage < MAX_STAGE) {
      const nextStage = stage + 1;
      setStage(nextStage);
      initializeGame(nextStage);
    }
  };

  const handleRestartGame = () => {
    // Retry current level
    initializeGame(stage);
  };

  const handleResetToLevel1 = () => {
      setStage(1);
      initializeGame(1);
  };

  const handleCardClick = (index: number) => {
    if (flippedIndices.length === 2 || gameCards[index].isFlipped || gameCards[index].isMatched) return;

    // Increment move count on every valid click
    setMoves(m => m + 1);

    const newCards = [...gameCards];
    newCards[index].isFlipped = true;
    setGameCards(newCards);

    const newFlipped = [...flippedIndices, index];
    setFlippedIndices(newFlipped);

    if (newFlipped.length === 2) {
      checkForMatch(newFlipped, newCards);
    }
  };

  const checkForMatch = (indices: number[], currentCards: GameCard[]) => {
    const [first, second] = indices;
    if (currentCards[first].iconId === currentCards[second].iconId) {
      // Match found
      setTimeout(() => {
        const matchedCards = [...currentCards];
        matchedCards[first].isMatched = true;
        matchedCards[second].isMatched = true;
        setGameCards(matchedCards);
        setFlippedIndices([]);
        
        if (matchedCards.every(c => c.isMatched)) {
          setIsGameWon(true);
        }
      }, 500);
    } else {
      // No match
      setTimeout(() => {
        const resetCards = [...currentCards];
        resetCards[first].isFlipped = false;
        resetCards[second].isFlipped = false;
        setGameCards(resetCards);
        setFlippedIndices([]);
      }, 1000);
    }
  };


  const loadData = () => {
    setPasses(MockService.getUserPasses(user.id));
    setBills(MockService.getUserBills(user.id));
    const est = MockService.getEstate(user.estateId);
    setEstateName(est?.name || 'GateKeeper Estate');
  };

  const toggleDay = (day: string) => {
    if (selectedDays.includes(day)) {
      setSelectedDays(selectedDays.filter(d => d !== day));
    } else {
      setSelectedDays([...selectedDays, day]);
    }
  };

  const handleCreatePass = (e: React.FormEvent) => {
    e.preventDefault();
    if (createType !== PassType.DELIVERY && !guestName) return;
    if (createType === PassType.DELIVERY && !deliveryCompany) return;
    
    MockService.generatePass(
      user.id, 
      guestName, 
      exitInstruction,
      createType,
      createType === PassType.RECURRING ? { days: selectedDays, start: recurringStart, end: recurringEnd } : undefined,
      deliveryCompany
    );

    setIsCreating(false);
    setGuestName('');
    setExitInstruction('');
    setDeliveryCompany('');
    setCreateType(PassType.ONE_TIME);
    loadData();
  };

  const handleCancelPass = (pass: GuestPass) => {
    if (window.confirm(`Are you sure you want to cancel the pass for ${pass.guestName}? The code will immediately become invalid.`)) {
      MockService.cancelPass(pass.id);
      loadData();
    }
  };

  const handleSharePass = async (pass: GuestPass) => {
    const validTime = new Date(pass.validUntil).toLocaleString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
    
    let text = `GateKeeper Access Pass\n\n`;
    text += `Visitor: ${pass.guestName}\n`;
    text += `Code: ${pass.code}\n`;
    text += `Location: ${estateName}, Unit ${user.unitNumber}\n`;
    text += `Valid until: ${validTime}\n`;
    
    if (pass.exitInstruction) {
        text += `Note: ${pass.exitInstruction}\n`;
    }
    
    text += `\nPlease show this code to security at the gate.`;

    if (navigator.share) {
        try {
            await navigator.share({
                title: 'Entry Pass',
                text: text
            });
        } catch (err) {
            // Share cancelled
        }
    } else {
        try {
            await navigator.clipboard.writeText(text);
            alert('Access pass copied to clipboard!');
        } catch (err) {
            alert(`Your code is ${pass.code}`);
        }
    }
  };

  const initiatePayment = (bill: Bill) => {
    setSelectedBill(bill);
    setPaymentModalOpen(true);
    setCardDetails({ number: '', expiry: '', cvv: '', name: user.name });
  };

  const processPayment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedBill) return;

    setPaymentProcessing(true);
    
    // Simulate Gateway Delay
    setTimeout(async () => {
        await MockService.payBill(selectedBill.id);
        setPaymentProcessing(false);
        setPaymentModalOpen(false);
        setSelectedBill(null);
        loadData();
        // Re-check restriction immediately
        setIsAccessRestricted(MockService.checkAccessRestricted(user.id));
        alert('Payment Successful!');
    }, 2000);
  };

  const handleSOS = () => {
      if (window.confirm("ARE YOU SURE? This will alert security immediately.")) {
          MockService.sendSOS(user.estateId, user.id, user.unitNumber || '');
          setSosActive(true);
          setTimeout(() => setSosActive(false), 5000);
      }
  };

  const handleCallSecurity = () => {
      MockService.initiateCall(user.id, 'GATE');
      alert("Calling Gate Security...");
  };

  // Filter passes
  const activePasses = passes.filter(p => (p.status === PassStatus.ACTIVE || p.status === PassStatus.CHECKED_IN) && p.type === PassType.ONE_TIME);
  const activeDeliveries = passes.filter(p => (p.status === PassStatus.ACTIVE || p.status === PassStatus.CHECKED_IN) && p.type === PassType.DELIVERY);
  const recurringPasses = passes.filter(p => (p.status === PassStatus.ACTIVE || p.status === PassStatus.CHECKED_IN) && p.type === PassType.RECURRING);
  const historyPasses = passes.filter(p => p.status === PassStatus.EXPIRED || p.status === PassStatus.CANCELLED);

  // Helper to open specific create modal
  const openCreate = (type: PassType) => {
    setCreateType(type);
    setIsCreating(true);
  };

  // --- VIEW: GAME ---
  if (currentView === 'game') {
    // Dynamic grid columns based on number of tiles
    const tileCount = gameCards.length;
    const cols = Math.ceil(Math.sqrt(tileCount));
    const isLevelFailed = isGameWon && moves > allowedMoves;

    return (
      <div className="space-y-6">
        <div className="flex flex-col md:flex-row justify-between items-center gap-4">
          <h2 className="text-2xl font-bold text-slate-900 dark:text-white flex items-center gap-2">
            <Gamepad2 className="text-indigo-600 dark:text-indigo-400" /> Relax Zone
          </h2>
          <div className="flex items-center gap-2">
             <div className="bg-slate-100 dark:bg-slate-800 px-3 py-1.5 rounded-lg flex items-center gap-2">
               <span className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase">Stage</span>
               <span className="text-sm font-bold text-indigo-600 dark:text-indigo-400">{stage} / {MAX_STAGE}</span>
             </div>
             <Button onClick={handleResetToLevel1} variant="secondary" className="gap-2 text-xs">
                <RefreshCw size={14} /> Reset
             </Button>
          </div>
        </div>

        <div className="text-center mb-4">
          <span className={`inline-block px-4 py-2 rounded-full font-bold text-sm border ${moves > allowedMoves ? 'bg-red-100 text-red-700 border-red-200 dark:bg-red-900/30 dark:text-red-300 dark:border-red-800' : 'bg-indigo-100 text-indigo-700 border-indigo-200 dark:bg-indigo-900/30 dark:text-indigo-300 dark:border-indigo-800'}`}>
            Moves: {moves} / {allowedMoves}
          </span>
        </div>

        <div className="max-w-2xl mx-auto relative">
          {/* Win Overlay */}
          {isGameWon && (
            <div className="absolute inset-0 z-10 flex flex-col items-center justify-center bg-white/95 dark:bg-slate-900/95 backdrop-blur-sm rounded-xl animate-fade-in border-2 border-indigo-100 dark:border-indigo-900 px-4 text-center">
              {isLevelFailed ? (
                 <>
                    <X size={64} className="text-red-500 mb-4 animate-bounce" />
                    <h3 className="text-3xl font-bold text-slate-900 dark:text-white mb-2">Level Failed</h3>
                    <p className="text-slate-600 dark:text-slate-300 mb-6 font-medium">
                        You took {moves} moves. Maximum allowed is {allowedMoves}.
                    </p>
                    <Button onClick={handleRestartGame} size="lg" className="shadow-xl shadow-red-200 dark:shadow-none bg-red-600 hover:bg-red-700">
                        Retry Level
                    </Button>
                 </>
              ) : (
                 <>
                    {stage === MAX_STAGE ? (
                        <Crown size={64} className="text-yellow-500 mb-4 animate-bounce" />
                    ) : (
                        <Trophy size={64} className="text-indigo-500 mb-4 animate-bounce" />
                    )}
                    
                    <h3 className="text-3xl font-bold text-slate-900 dark:text-white mb-2">
                        {stage === MAX_STAGE ? 'Grand Champion!' : 'Stage Complete!'}
                    </h3>
                    
                    <p className="text-slate-600 dark:text-slate-300 mb-6 font-medium">
                        {stage === MAX_STAGE ? `You beat the game in ${moves} moves.` : `You cleared Stage ${stage} in ${moves} moves.`}
                    </p>
                    
                    {stage < MAX_STAGE ? (
                        <Button onClick={handleNextStage} size="lg" className="shadow-xl shadow-indigo-200 dark:shadow-none gap-2">
                            Next Level <ArrowRight size={20} />
                        </Button>
                    ) : (
                        <Button onClick={handleResetToLevel1} size="lg" className="shadow-xl shadow-indigo-200 dark:shadow-none">
                            Play Again
                        </Button>
                    )}
                 </>
              )}
            </div>
          )}

          <div 
            className="grid gap-3 md:gap-4 transition-all duration-300"
            style={{ 
                gridTemplateColumns: `repeat(${cols}, minmax(0, 1fr))` 
            }}
          >
            {gameCards.map((card, index) => {
              const Icon = GAME_ICONS[card.iconId] || GAME_ICONS[0]; // Fallback if icon missing
              return (
                <div 
                  key={index} 
                  onClick={() => handleCardClick(index)}
                  className={`aspect-square cursor-pointer transition-all duration-300 transform preserve-3d relative ${card.isFlipped || card.isMatched ? 'rotate-y-180' : ''}`}
                >
                  <div className={`w-full h-full rounded-xl flex items-center justify-center shadow-sm transition-all ${
                    card.isFlipped || card.isMatched 
                      ? 'bg-white dark:bg-slate-800 border-2 border-indigo-500 dark:border-indigo-400 rotate-y-180' 
                      : 'bg-indigo-600 dark:bg-indigo-800 hover:bg-indigo-500'
                  }`}>
                    {(card.isFlipped || card.isMatched) ? (
                      <Icon size={tileCount > 16 ? 16 : 24} className="text-indigo-600 dark:text-indigo-400 animate-fade-in" />
                    ) : (
                      <Gamepad2 size={tileCount > 16 ? 16 : 24} className="text-indigo-300/30" />
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
        
        <div className="bg-slate-50 dark:bg-slate-800/50 p-6 rounded-xl text-center max-w-md mx-auto mt-8 border border-slate-200 dark:border-slate-700">
          <h4 className="font-bold text-slate-900 dark:text-white mb-2">How to Play</h4>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Tap cards to find matching pairs. Complete the stage within the move limit to advance. 
            There are {MAX_STAGE} stages in total!
          </p>
        </div>
      </div>
    );
  }

  // --- VIEW: PAYMENTS ---
  if (currentView === 'payments') {
    return (
        <div className="space-y-6">
            <h2 className="text-2xl font-bold text-slate-900 dark:text-white flex items-center gap-2">
                <CreditCard className="text-indigo-600 dark:text-indigo-400" /> Payments & Bills
            </h2>
            {bills.length === 0 ? (
                <div className="text-center py-12 bg-white dark:bg-slate-900 rounded-xl border border-dashed border-slate-300 dark:border-slate-700">
                   <CheckCircle className="mx-auto h-12 w-12 text-green-500 mb-3" />
                   <h3 className="text-lg font-medium text-slate-900 dark:text-white">All Caught Up!</h3>
                   <p className="text-slate-500 dark:text-slate-400">You have no outstanding bills at the moment.</p>
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {bills.map(bill => (
                        <Card key={bill.id} className={bill.status === BillStatus.PAID ? 'opacity-75' : ''}>
                            <CardBody>
                                <div className="flex justify-between items-start mb-4">
                                    <div className={`p-2 rounded-lg ${bill.status === BillStatus.PAID ? 'bg-green-100 dark:bg-green-900/30 text-green-600' : 'bg-orange-100 dark:bg-orange-900/30 text-orange-600'}`}>
                                        <Wallet size={20} />
                                    </div>
                                    <span className={`px-2 py-1 text-xs font-bold rounded uppercase ${bill.status === BillStatus.PAID ? 'bg-green-100 dark:bg-green-900/30 text-green-700' : 'bg-red-100 dark:bg-red-900/30 text-red-700'}`}>
                                        {bill.status}
                                    </span>
                                </div>
                                <h4 className="font-bold text-slate-900 dark:text-white text-lg">${bill.amount.toFixed(2)}</h4>
                                <p className="text-sm font-medium text-slate-700 dark:text-slate-300">{bill.description}</p>
                                <div className="mt-4 pt-4 border-t border-slate-100 dark:border-slate-800 text-xs flex justify-between text-slate-500 dark:text-slate-400">
                                   <span>Type: {bill.type.replace('_', ' ')}</span>
                                   <span>Due: {new Date(bill.dueDate).toLocaleDateString()}</span>
                                </div>
                                
                                {bill.status === BillStatus.UNPAID && (
                                    <Button fullWidth className="mt-4 gap-2" onClick={() => initiatePayment(bill)}>
                                        <CreditCard size={16} /> Pay Now
                                    </Button>
                                )}
                            </CardBody>
                        </Card>
                    ))}
                </div>
            )}
            
            {/* Modal */}
            {paymentModalOpen && selectedBill && (
              <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/80 backdrop-blur-sm animate-fade-in p-4">
                  <div className="bg-white dark:bg-slate-900 rounded-2xl shadow-2xl w-full max-w-md overflow-hidden border border-slate-200 dark:border-slate-800">
                      <div className="p-6 border-b border-slate-100 dark:border-slate-800 flex justify-between items-center">
                          <h3 className="text-lg font-bold text-slate-900 dark:text-white flex items-center gap-2">
                              <Lock className="w-4 h-4 text-green-500" /> Secure Payment
                          </h3>
                          <button onClick={() => setPaymentModalOpen(false)} className="text-slate-400 hover:text-slate-500"><X size={20} /></button>
                      </div>
                      <div className="p-6 bg-slate-50 dark:bg-slate-800/50">
                          <div className="flex justify-between items-end mb-1">
                              <span className="text-sm text-slate-500 dark:text-slate-400">Total Due</span>
                              <span className="text-2xl font-bold text-slate-900 dark:text-white">${selectedBill.amount.toFixed(2)}</span>
                          </div>
                          <p className="text-xs text-slate-500 dark:text-slate-400">{selectedBill.description}</p>
                      </div>
                      <div className="p-6">
                          <form onSubmit={processPayment} className="space-y-4">
                              <div>
                                  <label className="block text-xs font-bold text-slate-500 dark:text-slate-400 uppercase mb-1">Card Number</label>
                                  <div className="relative">
                                      <CreditCard className="absolute left-3 top-2.5 text-slate-400" size={18} />
                                      <input 
                                          className="w-full pl-10 p-2 border border-slate-300 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white"
                                          placeholder="0000 0000 0000 0000"
                                          value={cardDetails.number}
                                          onChange={e => setCardDetails({...cardDetails, number: e.target.value.replace(/\D/g, '').slice(0, 16)})}
                                          required
                                      />
                                  </div>
                              </div>
                              <div className="grid grid-cols-2 gap-4">
                                  <div>
                                      <label className="block text-xs font-bold text-slate-500 dark:text-slate-400 uppercase mb-1">Expiry</label>
                                      <input 
                                          className="w-full p-2 border border-slate-300 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white"
                                          placeholder="MM/YY"
                                          maxLength={5}
                                          value={cardDetails.expiry}
                                          onChange={e => setCardDetails({...cardDetails, expiry: e.target.value})}
                                          required
                                      />
                                  </div>
                                  <div>
                                      <label className="block text-xs font-bold text-slate-500 dark:text-slate-400 uppercase mb-1">CVV</label>
                                      <input 
                                          className="w-full p-2 border border-slate-300 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white"
                                          placeholder="123"
                                          maxLength={3}
                                          type="password"
                                          value={cardDetails.cvv}
                                          onChange={e => setCardDetails({...cardDetails, cvv: e.target.value})}
                                          required
                                      />
                                  </div>
                              </div>
                              <Button type="submit" fullWidth disabled={paymentProcessing} className="mt-4">
                                  {paymentProcessing ? 'Processing Payment...' : `Pay $${selectedBill.amount.toFixed(2)}`}
                              </Button>
                          </form>
                      </div>
                  </div>
              </div>
            )}
        </div>
    );
  }

  // --- VIEW: HISTORY ---
  if (currentView === 'history') {
      return (
          <div className="space-y-6">
              <h2 className="text-2xl font-bold text-slate-900 dark:text-white flex items-center gap-2">
                <History className="text-indigo-600 dark:text-indigo-400" /> Pass History
              </h2>
              <Card>
                  <CardHeader title="Past Visits & Expired Codes" />
                  <div className="overflow-x-auto">
                    {historyPasses.length === 0 ? (
                        <div className="p-8 text-center text-slate-500 dark:text-slate-400">No history available yet.</div>
                    ) : (
                        <table className="w-full text-sm text-left">
                            <thead className="bg-slate-50 dark:bg-slate-800/50 text-slate-500 dark:text-slate-400 border-b border-slate-200 dark:border-slate-700">
                                <tr>
                                    <th className="px-6 py-3">Date Created</th>
                                    <th className="px-6 py-3">Guest Name</th>
                                    <th className="px-6 py-3">Type</th>
                                    <th className="px-6 py-3">Entry Time</th>
                                    <th className="px-6 py-3">Exit Time</th>
                                    <th className="px-6 py-3">Status</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                                {historyPasses.map(pass => (
                                    <tr key={pass.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/50 text-slate-700 dark:text-slate-300">
                                        <td className="px-6 py-4">{new Date(pass.createdAt).toLocaleDateString()}</td>
                                        <td className="px-6 py-4 font-medium text-slate-900 dark:text-white">{pass.guestName}</td>
                                        <td className="px-6 py-4 text-xs uppercase">{pass.type}</td>
                                        <td className="px-6 py-4 text-slate-500">
                                            {pass.entryTime ? new Date(pass.entryTime).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) : '-'}
                                        </td>
                                        <td className="px-6 py-4 text-slate-500">
                                            {pass.exitTime ? new Date(pass.exitTime).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) : '-'}
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className={`px-2 py-1 rounded text-xs font-bold ${
                                                pass.status === PassStatus.CHECKED_IN ? 'bg-green-100 text-green-700' :
                                                pass.status === PassStatus.EXPIRED ? 'bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400' :
                                                'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400'
                                            }`}>
                                                {pass.status}
                                            </span>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    )}
                  </div>
              </Card>
          </div>
      );
  }

  // --- VIEW: SETTINGS ---
  if (currentView === 'settings') {
      return (
          <div className="space-y-6">
              <h2 className="text-2xl font-bold text-slate-900 dark:text-white flex items-center gap-2">
                <AlertCircle className="text-indigo-600 dark:text-indigo-400" /> Account Settings
              </h2>
              
              <Card>
                  <CardHeader title="Preferences" />
                  <CardBody className="space-y-6">
                      <div className="flex items-center justify-between">
                          <div className="flex gap-4">
                              <div className="p-2 bg-indigo-50 dark:bg-indigo-900/20 rounded-lg text-indigo-600 dark:text-indigo-400">
                                  <Bell />
                              </div>
                              <div>
                                  <h4 className="font-bold text-slate-900 dark:text-white">Push Notifications</h4>
                                  <p className="text-sm text-slate-500 dark:text-slate-400">Receive alerts when guests arrive or leave.</p>
                              </div>
                          </div>
                          <label className="relative inline-flex items-center cursor-pointer">
                              <input type="checkbox" className="sr-only peer" checked={notificationsEnabled} onChange={() => setNotificationsEnabled(!notificationsEnabled)} />
                              <div className="w-11 h-6 bg-slate-200 dark:bg-slate-700 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-600"></div>
                          </label>
                      </div>

                      <div className="flex items-center justify-between">
                          <div className="flex gap-4">
                              <div className="p-2 bg-indigo-50 dark:bg-indigo-900/20 rounded-lg text-indigo-600 dark:text-indigo-400">
                                  <Shield />
                              </div>
                              <div>
                                  <h4 className="font-bold text-slate-900 dark:text-white">Privacy Mode</h4>
                                  <p className="text-sm text-slate-500 dark:text-slate-400">Hide guest details from estate logs after 30 days.</p>
                              </div>
                          </div>
                          <label className="relative inline-flex items-center cursor-pointer">
                              <input type="checkbox" className="sr-only peer" checked={privacyEnabled} onChange={() => setPrivacyEnabled(!privacyEnabled)} />
                              <div className="w-11 h-6 bg-slate-200 dark:bg-slate-700 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-600"></div>
                          </label>
                      </div>
                  </CardBody>
              </Card>

              <Card>
                  <CardHeader title="Security" />
                  <CardBody>
                      <div className="flex items-center justify-between">
                           <div className="flex gap-4">
                              <div className="p-2 bg-indigo-50 dark:bg-indigo-900/20 rounded-lg text-indigo-600 dark:text-indigo-400">
                                  <Key />
                              </div>
                              <div>
                                  <h4 className="font-bold text-slate-900 dark:text-white">Password</h4>
                                  <p className="text-sm text-slate-500 dark:text-slate-400">Change your account password.</p>
                              </div>
                           </div>
                           <Button variant="secondary" onClick={() => alert("Password reset link sent to your email.")}>Update Password</Button>
                      </div>
                  </CardBody>
              </Card>
          </div>
      );
  }

  // --- DEFAULT VIEW: DASHBOARD (PASSES) ---
  return (
    <div className="space-y-6 relative">
      {/* SOS Notification */}
      {sosActive && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-red-900/90 animate-pulse">
              <div className="text-center text-white p-8">
                  <Siren size={80} className="mx-auto mb-4 animate-bounce" />
                  <h1 className="text-4xl font-bold">SOS SENT!</h1>
                  <p className="text-xl mt-2">Security has been alerted to your location.</p>
              </div>
          </div>
      )}

      {isAccessRestricted && (
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 p-4 rounded-xl flex items-start gap-4 animate-bounce-in">
           <AlertOctagon className="text-red-600 dark:text-red-400 w-6 h-6 shrink-0 mt-0.5" />
           <div>
             <h3 className="font-bold text-red-700 dark:text-red-400">Service Restricted</h3>
             <p className="text-sm text-red-600 dark:text-red-300 mt-1">You have unpaid bills overdue by more than 30 days. Guest code generation is disabled until payment is made.</p>
           </div>
        </div>
      )}

      {/* SAFETY BAR */}
      <div className="bg-slate-100 dark:bg-slate-800 rounded-2xl p-4 flex justify-between items-center shadow-inner">
          <button onClick={handleCallSecurity} className="flex items-center gap-2 text-slate-700 dark:text-slate-300 hover:text-indigo-600 dark:hover:text-indigo-400 font-bold transition-colors">
              <div className="bg-green-500 p-2 rounded-full text-white">
                  <Phone size={20} />
              </div>
              Call Gate Security
          </button>
          
          <button onClick={handleSOS} className="bg-red-600 hover:bg-red-700 text-white px-6 py-2 rounded-xl font-bold flex items-center gap-2 shadow-lg shadow-red-200 dark:shadow-red-900/20 transform active:scale-95 transition-all">
              <Siren size={20} className="animate-pulse" /> SOS ALERT
          </button>
      </div>

      {/* PASSES VIEW */}
      <div className="flex justify-between items-center">
          <h2 className="text-xl font-bold text-slate-900 dark:text-white">Quick Actions</h2>
      </div>
      
      <div className="grid grid-cols-2 gap-4">
          <button 
              onClick={() => openCreate(PassType.ONE_TIME)} 
              disabled={isAccessRestricted}
              className="flex flex-col items-center justify-center p-6 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl shadow-lg shadow-indigo-200 dark:shadow-none transition-all disabled:opacity-50 disabled:cursor-not-allowed"
          >
              <Plus size={24} className="mb-2" />
              <span className="font-bold">New Guest</span>
          </button>
          <button 
              onClick={() => openCreate(PassType.DELIVERY)} 
              disabled={isAccessRestricted}
              className="flex flex-col items-center justify-center p-6 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white hover:border-indigo-500 hover:text-indigo-600 dark:hover:text-indigo-400 rounded-xl transition-all disabled:opacity-50 disabled:cursor-not-allowed"
          >
              <Truck size={24} className="mb-2" />
              <span className="font-bold">Expect Delivery</span>
          </button>
      </div>

      {/* Creation Modal */}
      {isCreating && (
          <Card className="border-indigo-100 ring-2 ring-indigo-50 dark:ring-indigo-900/30 animate-fade-in">
          <CardHeader title={createType === PassType.DELIVERY ? "Expected Delivery" : "Create Guest Pass"} />
          <CardBody>
              {!isAccessRestricted ? (
                  <form onSubmit={handleCreatePass} className="space-y-4">
                      {/* Toggle Types if not Delivery */}
                      {createType !== PassType.DELIVERY && (
                          <div className="flex gap-4 mb-4 border-b border-slate-100 dark:border-slate-800 pb-2">
                          <button 
                              type="button"
                              onClick={() => setCreateType(PassType.ONE_TIME)}
                              className={`pb-2 text-sm font-medium transition-colors ${createType === PassType.ONE_TIME ? 'text-indigo-600 dark:text-indigo-400 border-b-2 border-indigo-600 dark:border-indigo-400' : 'text-slate-500 dark:text-slate-400'}`}
                          >
                              One-Time Visitor
                          </button>
                          <button 
                              type="button"
                              onClick={() => setCreateType(PassType.RECURRING)}
                              className={`pb-2 text-sm font-medium transition-colors ${createType === PassType.RECURRING ? 'text-indigo-600 dark:text-indigo-400 border-b-2 border-indigo-600 dark:border-indigo-400' : 'text-slate-500 dark:text-slate-400'}`}
                          >
                              Recurring Staff
                          </button>
                          </div>
                      )}

                      {createType === PassType.DELIVERY ? (
                          <div>
                              <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Delivery Company</label>
                              <div className="grid grid-cols-3 gap-2 mb-2">
                                  {['UberEats', 'Amazon', 'FedEx'].map(c => (
                                      <button 
                                          key={c} type="button" 
                                          onClick={() => setDeliveryCompany(c)}
                                          className={`text-xs py-2 rounded border ${deliveryCompany === c ? 'bg-indigo-600 text-white border-indigo-600' : 'bg-white dark:bg-slate-800 border-slate-300 dark:border-slate-600 text-slate-600 dark:text-slate-300'}`}
                                      >
                                          {c}
                                      </button>
                                  ))}
                              </div>
                              <input 
                                  type="text" 
                                  value={deliveryCompany}
                                  onChange={(e) => setDeliveryCompany(e.target.value)}
                                  className="w-full border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white rounded-lg px-3 py-2 text-sm"
                                  placeholder="Other Provider Name"
                                  required
                              />
                              <p className="text-xs text-orange-600 dark:text-orange-400 mt-2 flex items-center gap-1">
                                  <Clock size={12} /> Valid for 30 minutes only.
                              </p>
                          </div>
                      ) : (
                          <div>
                              <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                              {createType === PassType.ONE_TIME ? 'Guest Name' : 'Staff Name'}
                              </label>
                              <input 
                              type="text" 
                              value={guestName}
                              onChange={(e) => setGuestName(e.target.value)}
                              className="w-full border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white rounded-lg px-3 py-2 focus:ring-indigo-500 focus:border-indigo-500"
                              placeholder={createType === PassType.ONE_TIME ? "e.g. John Doe" : "e.g. Maria (Maid)"}
                              required
                              />
                          </div>
                      )}

                      {createType === PassType.RECURRING && (
                          <div className="p-4 bg-slate-50 dark:bg-slate-800/50 rounded-lg border border-slate-200 dark:border-slate-700 space-y-3">
                          <label className="block text-sm font-medium text-slate-700 dark:text-slate-300">Schedule</label>
                          <div className="flex flex-wrap gap-2">
                              {DAYS.map(day => (
                              <button
                                  key={day}
                                  type="button"
                                  onClick={() => toggleDay(day)}
                                  className={`text-xs px-2 py-1 rounded border transition-colors ${
                                  selectedDays.includes(day) 
                                  ? 'bg-indigo-100 border-indigo-200 text-indigo-700 dark:bg-indigo-900/40 dark:border-indigo-700 dark:text-indigo-300 font-bold' 
                                  : 'bg-white dark:bg-slate-800 border-slate-200 dark:border-slate-700 text-slate-500 dark:text-slate-400'
                                  }`}
                              >
                                  {day}
                              </button>
                              ))}
                          </div>
                          <div className="flex gap-4">
                              <div>
                              <label className="text-xs text-slate-500 dark:text-slate-400 block mb-1">Start Time</label>
                              <input 
                                  type="time" 
                                  value={recurringStart} 
                                  onChange={e => setRecurringStart(e.target.value)}
                                  className="text-sm border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white rounded px-2 py-1"
                              />
                              </div>
                              <div>
                              <label className="text-xs text-slate-500 dark:text-slate-400 block mb-1">End Time</label>
                              <input 
                                  type="time" 
                                  value={recurringEnd} 
                                  onChange={e => setRecurringEnd(e.target.value)}
                                  className="text-sm border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white rounded px-2 py-1"
                              />
                              </div>
                          </div>
                          </div>
                      )}
                      
                      {createType !== PassType.DELIVERY && (
                          <div>
                              <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Exit Instruction (Optional)</label>
                              <input 
                                  type="text" 
                                  value={exitInstruction}
                                  onChange={(e) => setExitInstruction(e.target.value)}
                                  className="w-full border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white rounded-lg px-3 py-2 focus:ring-indigo-500 focus:border-indigo-500"
                                  placeholder="e.g. Taking the TV, Driving Blue Toyota"
                              />
                          </div>
                      )}

                      <div className="flex gap-3 pt-2">
                          <Button type="submit" fullWidth>
                              {createType === PassType.DELIVERY ? 'Authorize Delivery' : 'Generate Code'}
                          </Button>
                          <Button type="button" variant="ghost" onClick={() => setIsCreating(false)}>Cancel</Button>
                      </div>
                  </form>
              ) : (
                  <div className="text-center text-slate-500 py-4">
                      Please clear outstanding bills to resume.
                  </div>
              )}
          </CardBody>
          </Card>
      )}

      {/* Active Deliveries */}
      {activeDeliveries.length > 0 && (
          <div className="mb-6">
              <h3 className="font-semibold text-slate-800 dark:text-slate-200 flex items-center gap-2 mb-3">
                  <Truck size={18} className="text-blue-600 dark:text-blue-400" /> Expected Deliveries
              </h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {activeDeliveries.map(pass => (
                      <Card key={pass.id} className="bg-blue-50 dark:bg-blue-900/20 border-blue-100 dark:border-blue-900/50">
                          <CardBody className="flex justify-between items-center">
                              <div>
                                  <h4 className="font-bold text-slate-900 dark:text-white">{pass.guestName}</h4>
                                  <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
                                      Code: <span className="font-mono">{pass.code}</span>
                                  </p>
                              </div>
                              <div className="text-right">
                                  <span className="text-xs font-bold text-orange-600 dark:text-orange-400 block">
                                      {pass.status === PassStatus.CHECKED_IN ? 'ARRIVED' : 'WAITING'}
                                  </span>
                                  <Button size="sm" variant="danger" className="mt-2 text-xs h-7 px-2" onClick={() => handleCancelPass(pass)}>Cancel</Button>
                              </div>
                          </CardBody>
                      </Card>
                  ))}
              </div>
          </div>
      )}
      
      {/* Recurring & Active Sections */}
      {recurringPasses.length > 0 && (
          <div className="mb-6">
          <h3 className="font-semibold text-slate-800 dark:text-slate-200 flex items-center gap-2 mb-3">
              <UserCheck size={18} className="text-purple-600 dark:text-purple-400" /> My Staff
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {recurringPasses.map(pass => (
              <Card key={pass.id} className="bg-purple-50 dark:bg-purple-900/20 border-purple-100 dark:border-purple-900/50">
                  <CardBody>
                  <div className="flex justify-between items-start">
                      <div>
                      <h4 className="font-bold text-slate-900 dark:text-white">{pass.guestName}</h4>
                      <p className="text-xs text-slate-500 dark:text-slate-400 mt-1 font-mono">{pass.code}</p>
                      </div>
                      <span className="px-2 py-1 bg-white dark:bg-purple-900/40 rounded border border-purple-200 dark:border-purple-800 text-purple-700 dark:text-purple-300 text-xs font-bold">
                      STAFF
                      </span>
                  </div>
                  <div className="mt-4 flex gap-2">
                      <Button size="sm" variant="secondary" className="bg-white dark:bg-slate-800 text-xs h-8" onClick={() => handleSharePass(pass)}>Share</Button>
                      <Button size="sm" variant="danger" className="text-xs h-8" onClick={() => handleCancelPass(pass)}>Revoke</Button>
                  </div>
                  </CardBody>
              </Card>
              ))}
          </div>
          </div>
      )}

      <h3 className="font-semibold text-slate-800 dark:text-slate-200 flex items-center gap-2">
          <Clock size={18} className="text-indigo-600 dark:text-indigo-400" /> Active Visitor Passes
      </h3>
      
      {activePasses.length === 0 ? (
          <div className="text-center py-6 bg-white dark:bg-slate-900 rounded-xl border border-dashed border-slate-300 dark:border-slate-700">
          <p className="text-slate-500 dark:text-slate-400 text-sm">No active visitor passes.</p>
          </div>
      ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {activePasses.map(pass => (
              <Card key={pass.id}>
              <CardBody>
                  <div className="flex flex-col items-center text-center">
                  <div className="text-3xl font-mono font-bold tracking-widest text-slate-900 dark:text-white my-2">
                      {pass.code}
                  </div>
                  <h4 className="font-semibold text-slate-900 dark:text-white">{pass.guestName}</h4>
                  <p className="text-xs text-slate-500 dark:text-slate-400 mb-4">Valid until {new Date(pass.validUntil).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</p>
                  
                  <div className="flex gap-2 w-full">
                      <Button variant="secondary" fullWidth className="gap-2 text-xs" onClick={() => handleSharePass(pass)}>
                      <Share2 size={14} /> Share
                      </Button>
                      <Button variant="danger" className="px-3" onClick={() => handleCancelPass(pass)}>
                      <Trash2 size={14} />
                      </Button>
                  </div>
                  </div>
              </CardBody>
              </Card>
          ))}
          </div>
      )}

      {showAds && <AdBanner position="inline" />}
      
    </div>
  );
};