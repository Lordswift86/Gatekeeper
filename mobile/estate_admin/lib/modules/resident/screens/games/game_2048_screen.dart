import 'dart:math';
import 'package:flutter/material.dart';

class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  List<int> _grid = List.filled(16, 0);
  int _score = 0;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      _grid = List.filled(16, 0);
      _score = 0;
      _isGameOver = false;
      _addNewTile();
      _addNewTile();
    });
  }

  void _addNewTile() {
    List<int> emptyIndices = [];
    for (int i = 0; i < 16; i++) {
      if (_grid[i] == 0) emptyIndices.add(i);
    }
    if (emptyIndices.isNotEmpty) {
      int index = emptyIndices[Random().nextInt(emptyIndices.length)];
      _grid[index] = Random().nextInt(10) == 0 ? 4 : 2;
    }
  }

  void _onSwipe(SwipeDirection direction) {
    if (_isGameOver) return;

    bool moved = false;
    List<int> newGrid = List.from(_grid);

    // Simplified logic: Extract rows/cols, process, put back
    // This is a naive implementation but functional for basic play
    if (direction == SwipeDirection.left || direction == SwipeDirection.right) {
      for (int i = 0; i < 4; i++) {
        List<int> row = [newGrid[i * 4], newGrid[i * 4 + 1], newGrid[i * 4 + 2], newGrid[i * 4 + 3]];
        List<int> processed = _processList(row, direction == SwipeDirection.left);
        for (int j = 0; j < 4; j++) {
           if (newGrid[i * 4 + j] != processed[j]) moved = true;
           newGrid[i * 4 + j] = processed[j];
        }
      }
    } else {
      for (int i = 0; i < 4; i++) {
        List<int> col = [newGrid[i], newGrid[i + 4], newGrid[i + 8], newGrid[i + 12]];
        List<int> processed = _processList(col, direction == SwipeDirection.up);
        for (int j = 0; j < 4; j++) {
           if (newGrid[i + j * 4] != processed[j]) moved = true;
           newGrid[i + j * 4] = processed[j];
        }
      }
    }

    if (moved) {
      setState(() {
        _grid = newGrid;
        _addNewTile();
      });
      _checkGameOver();
    }
  }

  List<int> _processList(List<int> list, bool forward) {
    List<int> nonZero = list.where((e) => e != 0).toList();
    if (!forward) nonZero = nonZero.reversed.toList();

    List<int> merged = [];
    int i = 0;
    while (i < nonZero.length) {
      if (i + 1 < nonZero.length && nonZero[i] == nonZero[i + 1]) {
        merged.add(nonZero[i] * 2);
        setState(() => _score += nonZero[i] * 2);
        i += 2;
      } else {
        merged.add(nonZero[i]);
        i++;
      }
    }

    if (!forward) merged = merged.reversed.toList();
    
    while (merged.length < 4) {
      if (forward) merged.add(0); else merged.insert(0, 0);
    }
    return merged;
  }

  void _checkGameOver() {
    if (!_grid.contains(0)) {
      // Check for possible merges
      bool possible = false;
      for (int i = 0; i < 16; i++) {
        int val = _grid[i];
        if (i % 4 < 3 && val == _grid[i + 1]) possible = true;
        if (i < 12 && val == _grid[i + 4]) possible = true;
      }
      if (!possible) {
        setState(() => _isGameOver = true);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
             title: const Text('Game Over'),
             content: Text('Score: $_score'),
             actions: [
               TextButton(onPressed: () {
                 Navigator.pop(ctx);
                 _startNewGame();
               }, child: const Text('Play Again'))
             ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2048'),
        actions: [
          IconButton(onPressed: _startNewGame, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Score: $_score', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: GestureDetector(
              onPanEnd: (details) {
                double dx = details.velocity.pixelsPerSecond.dx;
                double dy = details.velocity.pixelsPerSecond.dy;
                if (dx.abs() > dy.abs()) {
                  if (dx > 0) _onSwipe(SwipeDirection.right);
                  else _onSwipe(SwipeDirection.left);
                } else {
                  if (dy > 0) _onSwipe(SwipeDirection.down);
                  else _onSwipe(SwipeDirection.up);
                }
              },
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: 16,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: _getTileColor(_grid[index]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _grid[index] == 0 ? '' : '${_grid[index]}',
                        style: TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold,
                            color: _grid[index] <= 4 ? Colors.grey[800] : Colors.white
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTileColor(int value) {
    switch (value) {
      case 0: return Colors.grey.shade300;
      case 2: return const Color(0xFFEEE4DA);
      case 4: return const Color(0xFFEDE0C8);
      case 8: return const Color(0xFFF2B179);
      case 16: return const Color(0xFFF59563);
      case 32: return const Color(0xFFF67C5F);
      case 64: return const Color(0xFFF65E3B);
      case 128: return const Color(0xFFEDCF72);
      case 256: return const Color(0xFFEDCC61);
      case 512: return const Color(0xFFEDC850);
      case 1024: return const Color(0xFFEDC53F);
      case 2048: return const Color(0xFFEDC22E);
      default: return Colors.black;
    }
  }
}

enum SwipeDirection { up, down, left, right }
