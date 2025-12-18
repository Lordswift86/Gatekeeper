import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class ColorSwitchGameScreen extends StatefulWidget {
  const ColorSwitchGameScreen({super.key});

  @override
  State<ColorSwitchGameScreen> createState() => _ColorSwitchGameScreenState();
}

class _ColorSwitchGameScreenState extends State<ColorSwitchGameScreen> {
  final List<Color> _colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow];
  Color _targetColor = Colors.red;
  Color _currentColor = Colors.blue;
  int _score = 0;
  int _timeLeft = 60;
  Timer? _gameTimer;
  Timer? _colorTimer;
  bool _isPlaying = false;

  void _startGame() {
    setState(() {
      _score = 0;
      _timeLeft = 30;
      _isPlaying = true;
      _pickColors();
    });
    
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _gameOver();
      }
    });

    _startColorRotation();
  }

  void _startColorRotation() {
    _colorTimer?.cancel();
    _colorTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted) {
        setState(() {
          _currentColor = _colors[Random().nextInt(_colors.length)];
        });
      }
    });
  }

  void _pickColors() {
    final random = Random();
    setState(() {
      _targetColor = _colors[random.nextInt(_colors.length)];
      _currentColor = _colors[random.nextInt(_colors.length)];
    });
  }

  void _onTap() {
    if (!_isPlaying) return;

    if (_currentColor == _targetColor) {
      setState(() {
        _score++;
        _pickColors(); // Change target instantly on success
      });
      // Speed up rotation slightly?
      _colorTimer?.cancel();
      _colorTimer = Timer.periodic(Duration(milliseconds: max(200, 800 - (_score * 20))), (timer) {
         if (mounted) setState(() => _currentColor = _colors[Random().nextInt(_colors.length)]);
      });

    } else {
      _gameOver();
    }
  }

  void _gameOver() {
    _gameTimer?.cancel();
    _colorTimer?.cancel();
    setState(() => _isPlaying = false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Game Over'),
        content: Text('Score: $_score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startGame();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _colorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Color Match')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Time: $_timeLeft', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Score: $_score', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Tap when the circle matches the border!', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const Spacer(),
          GestureDetector(
            onTap: _onTap,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentColor,
                border: Border.all(color: _targetColor, width: 20),
              ),
              child: _isPlaying 
                ? null 
                : const Center(child: Text('TAP TO START', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
          ),
          const Spacer(),
          if (!_isPlaying)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                   minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Start Game'),
              ),
            ),
        ],
      ),
    );
  }
}
