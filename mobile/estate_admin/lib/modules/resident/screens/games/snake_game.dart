import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  static const int gridSize = 15;
  static const String _saveKey = 'snake_high_score';
  
  List<Point<int>> snake = [];
  Point<int> food = const Point(7, 7);
  Point<int> direction = const Point(1, 0);
  Timer? gameTimer;
  int score = 0;
  int highScore = 0;
  bool isPlaying = false;
  bool isGameOver = false;
  
  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _resetGame();
  }
  
  @override
  void dispose() {
    gameTimer?.cancel();
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

  void _resetGame() {
    snake = [const Point(7, 7), const Point(6, 7), const Point(5, 7)];
    direction = const Point(1, 0);
    score = 0;
    isGameOver = false;
    _spawnFood();
  }

  void _spawnFood() {
    final random = Random();
    Point<int> newFood;
    do {
      newFood = Point(random.nextInt(gridSize), random.nextInt(gridSize));
    } while (snake.contains(newFood));
    food = newFood;
  }

  void _startGame() {
    if (isGameOver) _resetGame();
    setState(() => isPlaying = true);
    gameTimer = Timer.periodic(const Duration(milliseconds: 700), (_) => _moveSnake());
  }

  void _pauseGame() {
    gameTimer?.cancel();
    setState(() => isPlaying = false);
  }

  void _moveSnake() {
    if (!mounted) return;
    
    final newHead = Point(
      (snake.first.x + direction.x) % gridSize,
      (snake.first.y + direction.y) % gridSize,
    );

    // Check collision with self
    if (snake.contains(newHead)) {
      _gameOver();
      return;
    }

    setState(() {
      snake.insert(0, newHead);
      
      if (newHead == food) {
        score += 10;
        _spawnFood();
      } else {
        snake.removeLast();
      }
    });
  }

  void _gameOver() {
    gameTimer?.cancel();
    _saveHighScore();
    setState(() {
      isPlaying = false;
      isGameOver = true;
    });
  }

  void _changeDirection(Point<int> newDir) {
    // Can't reverse direction
    if (direction.x + newDir.x == 0 && direction.y + newDir.y == 0) return;
    direction = newDir;
  }

  void _handleSwipe(DragEndDetails details) {
    if (!isPlaying) return;
    
    final dx = details.velocity.pixelsPerSecond.dx;
    final dy = details.velocity.pixelsPerSecond.dy;
    
    if (dx.abs() > dy.abs()) {
      _changeDirection(Point(dx > 0 ? 1 : -1, 0));
    } else {
      _changeDirection(Point(0, dy > 0 ? 1 : -1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snake'),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text('Score: $score', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ),
                IconButton(
                  onPressed: isPlaying ? _pauseGame : _startGame,
                  icon: Icon(isPlaying ? LucideIcons.pause : LucideIcons.play),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: GestureDetector(
              onPanEnd: _handleSwipe,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellSize = (min(constraints.maxWidth, constraints.maxHeight) - 32) / gridSize;
                  
                  return Center(
                    child: Container(
                      width: cellSize * gridSize,
                      height: cellSize * gridSize,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green.shade300, width: 2),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.green.shade50,
                      ),
                      child: Stack(
                        children: [
                          // Food
                          Positioned(
                            left: food.x * cellSize,
                            top: food.y * cellSize,
                            child: Container(
                              width: cellSize,
                              height: cellSize,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(cellSize / 2),
                              ),
                              child: Icon(LucideIcons.apple, size: cellSize * 0.6, color: Colors.white),
                            ),
                          ),
                          // Snake
                          ...snake.asMap().entries.map((entry) {
                            final isHead = entry.key == 0;
                            return Positioned(
                              left: entry.value.x * cellSize,
                              top: entry.value.y * cellSize,
                              child: Container(
                                width: cellSize - 2,
                                height: cellSize - 2,
                                margin: const EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  color: isHead ? Colors.green.shade700 : Colors.green,
                                  borderRadius: BorderRadius.circular(isHead ? cellSize / 3 : 4),
                                ),
                              ),
                            );
                          }),
                          
                          // Game Over Overlay
                          if (isGameOver)
                            Container(
                              color: Colors.black54,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.skull, size: 48, color: Colors.white),
                                    const SizedBox(height: 16),
                                    const Text('Game Over!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                                    Text('Score: $score', style: const TextStyle(color: Colors.white70)),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _startGame,
                                      icon: const Icon(LucideIcons.refreshCw),
                                      label: const Text('Play Again'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          
                          // Start Overlay
                          if (!isPlaying && !isGameOver)
                            Container(
                              color: Colors.black38,
                              child: Center(
                                child: ElevatedButton.icon(
                                  onPressed: _startGame,
                                  icon: const Icon(LucideIcons.play),
                                  label: const Text('Start'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  ),
                                ),
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
          
          // Touch controls hint
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Swipe to change direction',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}
