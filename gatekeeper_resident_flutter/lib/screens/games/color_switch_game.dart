import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';

class ColorSwitchGame extends StatefulWidget {
  const ColorSwitchGame({super.key});

  @override
  State<ColorSwitchGame> createState() => _ColorSwitchGameState();
}

class _ColorSwitchGameState extends State<ColorSwitchGame> with SingleTickerProviderStateMixin {
  static const String _saveKey = 'color_switch_high_score';
  
  final List<Color> colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
  ];
  
  Color targetColor = Colors.red;
  Color currentColor = Colors.blue;
  int score = 0;
  int highScore = 0;
  int lives = 3;
  bool isPlaying = false;
  bool isGameOver = false;
  double timeLeft = 3.0;
  double maxTime = 3.0;
  Timer? gameTimer;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => highScore = prefs.getInt(_saveKey) ?? 0);
  }

  Future<void> _saveHighScore() async {
    if (score > highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_saveKey, score);
      setState(() => highScore = score);
    }
  }

  void _startGame() {
    setState(() {
      score = 0;
      lives = 3;
      isPlaying = true;
      isGameOver = false;
      maxTime = 3.0;
    });
    _nextRound();
  }

  void _nextRound() {
    final random = Random();
    setState(() {
      targetColor = colors[random.nextInt(colors.length)];
      currentColor = colors[random.nextInt(colors.length)];
      timeLeft = maxTime;
    });
    
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        timeLeft -= 0.05;
        if (timeLeft <= 0) {
          _handleTimeout();
        }
      });
    });
  }

  void _handleTimeout() {
    gameTimer?.cancel();
    if (targetColor == currentColor) {
      // Should have tapped!
      _loseLife();
    } else {
      // Correct - didn't tap
      _nextRound();
    }
  }

  void _handleTap() {
    if (!isPlaying || isGameOver) return;
    gameTimer?.cancel();
    
    if (targetColor == currentColor) {
      // Correct!
      setState(() {
        score++;
        if (score % 5 == 0 && maxTime > 1.0) {
          maxTime -= 0.2; // Speed up
        }
      });
      _nextRound();
    } else {
      // Wrong!
      _loseLife();
    }
  }

  void _loseLife() {
    setState(() {
      lives--;
      if (lives <= 0) {
        isGameOver = true;
        isPlaying = false;
        _saveHighScore();
      }
    });
    
    if (!isGameOver) {
      _nextRound();
    }
  }

  String _getColorName(Color color) {
    if (color == Colors.red) return 'RED';
    if (color == Colors.blue) return 'BLUE';
    if (color == Colors.green) return 'GREEN';
    if (color == Colors.yellow) return 'YELLOW';
    if (color == Colors.purple) return 'PURPLE';
    if (color == Colors.orange) return 'ORANGE';
    return 'COLOR';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Switch'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('Best: $highScore', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Score and Lives
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.indigo),
                  ),
                  child: Text('Score: $score', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                ),
                Row(
                  children: List.generate(3, (i) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      LucideIcons.heart,
                      color: i < lives ? Colors.red : Colors.grey.shade300,
                      size: 24,
                    ),
                  )),
                ),
              ],
            ),
          ),
          
          // Timer bar
          if (isPlaying)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: timeLeft / maxTime,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    timeLeft < 1.0 ? Colors.red : Colors.green,
                  ),
                  minHeight: 8,
                ),
              ),
            ),
          
          Expanded(
            child: GestureDetector(
              onTap: _handleTap,
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: isPlaying ? _buildGameContent() : _buildStartContent(),
                ),
              ),
            ),
          ),
          
          // Instructions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              isPlaying 
                  ? 'Tap when colors match!' 
                  : 'Tap to start',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent() {
    if (isGameOver) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.frown, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Game Over!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text('Score: $score', style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startGame,
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Play Again'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      );
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'TAP IF',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: targetColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getColorName(targetColor),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 32),
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: currentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: currentColor.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.palette, size: 64, color: Colors.indigo.shade300),
        const SizedBox(height: 16),
        const Text('Color Switch', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Tap when the circle color matches the target!',
          style: TextStyle(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _startGame,
          icon: const Icon(LucideIcons.play),
          label: const Text('Start Game'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ],
    );
  }
}
