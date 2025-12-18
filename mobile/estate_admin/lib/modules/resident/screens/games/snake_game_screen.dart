import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class SnakeGameScreen extends StatefulWidget {
  const SnakeGameScreen({super.key});

  @override
  State<SnakeGameScreen> createState() => _SnakeGameScreenState();
}

class _SnakeGameScreenState extends State<SnakeGameScreen> {
  static const int _gridSize = 20;
  static const int _rows = 30;
  static const int _cols = 20;

  List<Point> _snake = [const Point(10, 10)];
  Point _food = const Point(15, 15);
  String _direction = 'up';
  Timer? _timer;
  bool _isPlaying = false;
  int _score = 0;

  void _startGame() {
    setState(() {
      _snake = [const Point(10, 10), const Point(10, 11), const Point(10, 12)];
      _direction = 'up';
      _score = 0;
      _isPlaying = true;
      _generateFood();
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      _moveSnake();
    });
  }

  void _generateFood() {
    final random = Random();
    int x, y;
    do {
      x = random.nextInt(_cols);
      y = random.nextInt(_rows);
    } while (_snake.contains(Point(x, y)));
    setState(() {
      _food = Point(x, y);
    });
  }

  void _moveSnake() {
    if (!_isPlaying) return;

    Point newHead;
    switch (_direction) {
      case 'up':
        newHead = Point(_snake.first.x, _snake.first.y - 1);
        break;
      case 'down':
        newHead = Point(_snake.first.x, _snake.first.y + 1);
        break;
      case 'left':
        newHead = Point(_snake.first.x - 1, _snake.first.y);
        break;
      case 'right':
        newHead = Point(_snake.first.x + 1, _snake.first.y);
        break;
      default:
        return;
    }

    if (newHead.x < 0 || newHead.x >= _cols || newHead.y < 0 || newHead.y >= _rows || _snake.contains(newHead)) {
      _gameOver();
      return;
    }

    setState(() {
      _snake.insert(0, newHead);
      if (newHead == _food) {
        _score += 10;
        _generateFood();
      } else {
        _snake.removeLast();
      }
    });
  }

  void _gameOver() {
    _timer?.cancel();
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
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Snake')),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Score: $_score', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.delta.dy > 0 && _direction != 'up') _direction = 'down';
                else if (details.delta.dy < 0 && _direction != 'down') _direction = 'up';
              },
              onHorizontalDragUpdate: (details) {
                if (details.delta.dx > 0 && _direction != 'left') _direction = 'right';
                else if (details.delta.dx < 0 && _direction != 'right') _direction = 'left';
              },
              child: Container(
                color: Colors.grey.shade900,
                child: CustomPaint(
                  painter: SnakePainter(_snake, _food, _cols, _rows),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          if (!_isPlaying)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Game'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SnakePainter extends CustomPainter {
  final List<Point> snake;
  final Point food;
  final int cols;
  final int rows;

  SnakePainter(this.snake, this.food, this.cols, this.rows);

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;

    final paint = Paint()..style = PaintingStyle.fill;

    // Draw Food
    paint.color = Colors.red;
    canvas.drawRect(
      Rect.fromLTWH(food.x * cellWidth, food.y * cellHeight, cellWidth, cellHeight),
      paint,
    );

    // Draw Snake
    paint.color = Colors.green;
    for (var point in snake) {
      canvas.drawRect(
        Rect.fromLTWH(point.x * cellWidth, point.y * cellHeight, cellWidth, cellHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
