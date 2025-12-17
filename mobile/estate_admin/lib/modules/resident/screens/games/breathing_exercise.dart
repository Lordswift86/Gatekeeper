import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';
import 'dart:math';

enum BreathPhase { inhale, hold, exhale, rest }

class BreathingExercise extends StatefulWidget {
  const BreathingExercise({super.key});

  @override
  State<BreathingExercise> createState() => _BreathingExerciseState();
}

class _BreathingExerciseState extends State<BreathingExercise> with TickerProviderStateMixin {
  BreathPhase phase = BreathPhase.rest;
  int inhaleSeconds = 4;
  int holdSeconds = 4;
  int exhaleSeconds = 4;
  int totalCycles = 0;
  int currentCycle = 0;
  bool isActive = false;
  int countdown = 0;
  
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;
  late AnimationController _glowController;
  
  Timer? _phaseTimer;

  final List<Map<String, dynamic>> patterns = [
    {'name': '4-4-4 Basic', 'inhale': 4, 'hold': 4, 'exhale': 4, 'icon': LucideIcons.wind},
    {'name': '4-7-8 Relaxing', 'inhale': 4, 'hold': 7, 'exhale': 8, 'icon': LucideIcons.moon},
    {'name': '5-5-5 Balance', 'inhale': 5, 'hold': 5, 'exhale': 5, 'icon': LucideIcons.scale},
    {'name': '3-3-3 Quick', 'inhale': 3, 'hold': 3, 'exhale': 3, 'icon': LucideIcons.zap},
  ];
  
  int selectedPattern = 0;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: Duration(seconds: inhaleSeconds),
    );
    _breathAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _breathController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _selectPattern(int index) {
    if (isActive) return;
    final pattern = patterns[index];
    setState(() {
      selectedPattern = index;
      inhaleSeconds = pattern['inhale'];
      holdSeconds = pattern['hold'];
      exhaleSeconds = pattern['exhale'];
    });
  }

  void _startExercise() {
    setState(() {
      isActive = true;
      currentCycle = 0;
      totalCycles = 5;
    });
    _startPhase(BreathPhase.inhale);
  }

  void _stopExercise() {
    _phaseTimer?.cancel();
    _breathController.stop();
    setState(() {
      isActive = false;
      phase = BreathPhase.rest;
    });
  }

  void _startPhase(BreathPhase newPhase) {
    if (!mounted || !isActive) return;
    
    setState(() => phase = newPhase);
    _phaseTimer?.cancel();
    
    int duration;
    switch (newPhase) {
      case BreathPhase.inhale:
        duration = inhaleSeconds;
        _breathController.duration = Duration(seconds: duration);
        _breathController.forward(from: 0);
        break;
      case BreathPhase.hold:
        duration = holdSeconds;
        break;
      case BreathPhase.exhale:
        duration = exhaleSeconds;
        _breathController.duration = Duration(seconds: duration);
        _breathController.reverse(from: 1);
        break;
      case BreathPhase.rest:
        return;
    }
    
    countdown = duration;
    
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        countdown--;
        if (countdown <= 0) {
          timer.cancel();
          _nextPhase();
        }
      });
    });
  }

  void _nextPhase() {
    switch (phase) {
      case BreathPhase.inhale:
        _startPhase(BreathPhase.hold);
        break;
      case BreathPhase.hold:
        _startPhase(BreathPhase.exhale);
        break;
      case BreathPhase.exhale:
        currentCycle++;
        if (currentCycle >= totalCycles) {
          _stopExercise();
          _showCompletionDialog();
        } else {
          _startPhase(BreathPhase.inhale);
        }
        break;
      case BreathPhase.rest:
        break;
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.checkCircle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text('Well Done!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'You completed $totalCycles breathing cycles.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getPhaseColor() {
    switch (phase) {
      case BreathPhase.inhale:
        return Colors.blue.shade400;
      case BreathPhase.hold:
        return Colors.purple.shade400;
      case BreathPhase.exhale:
        return Colors.teal.shade400;
      case BreathPhase.rest:
        return Colors.indigo.shade300;
    }
  }

  String _getPhaseText() {
    switch (phase) {
      case BreathPhase.inhale:
        return 'Breathe In';
      case BreathPhase.hold:
        return 'Hold';
      case BreathPhase.exhale:
        return 'Breathe Out';
      case BreathPhase.rest:
        return 'Ready?';
    }
  }

  @override
  Widget build(BuildContext context) {
    final phaseColor = _getPhaseColor();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breathing'),
        actions: [
          if (isActive)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  'Cycle ${currentCycle + 1}/$totalCycles',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Pattern selector
          if (!isActive)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: patterns.length,
                  itemBuilder: (context, index) {
                    final pattern = patterns[index];
                    final isSelected = index == selectedPattern;
                    
                    return GestureDetector(
                      onTap: () => _selectPattern(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.indigo : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Colors.indigo : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              pattern['icon'],
                              color: isSelected ? Colors.white : Colors.grey.shade600,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pattern['name'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Phase text
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: phaseColor,
                    ),
                    child: Text(_getPhaseText()),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  if (isActive)
                    Text(
                      '$countdown',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: phaseColor,
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Breathing circle
                  AnimatedBuilder(
                    animation: Listenable.merge([_breathAnimation, _glowController]),
                    builder: (context, child) {
                      final scale = isActive ? _breathAnimation.value : (0.6 + _glowController.value * 0.1);
                      
                      return Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: phaseColor.withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Transform.scale(
                          scale: scale,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  phaseColor.withValues(alpha: 0.9),
                                  phaseColor.withValues(alpha: 0.5),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Start/Stop button
                  ElevatedButton.icon(
                    onPressed: isActive ? _stopExercise : _startExercise,
                    icon: Icon(isActive ? LucideIcons.square : LucideIcons.play),
                    label: Text(isActive ? 'Stop' : 'Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? Colors.red : Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Tips
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.lightbulb, color: Colors.indigo.shade300),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Find a comfortable position and focus on the circle as you breathe.',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
