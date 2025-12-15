import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

class Game2048 extends StatefulWidget {
  const Game2048({super.key});

  @override
  State<Game2048> createState() => _Game2048State();
}

class _Game2048State extends State<Game2048> {
  static const int gridSize = 4;
  static const String _saveKey = 'game_2048_state';
  
  List<List<int>> board = List.generate(gridSize, (_) => List.filled(gridSize, 0));
  int score = 0;
  int highScore = 0;
  bool isGameOver = false;
  bool hasWon = false;

  @override
  void initState() {
    super.initState();
    _loadGameState();
  }

  Future<void> _loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedState = prefs.getString(_saveKey);
    highScore = prefs.getInt('${_saveKey}_high') ?? 0;
    
    if (savedState != null) {
      try {
        final state = jsonDecode(savedState);
        setState(() {
          board = (state['board'] as List).map((row) => (row as List).map((e) => e as int).toList()).toList();
          score = state['score'] ?? 0;
          isGameOver = state['isGameOver'] ?? false;
          hasWon = state['hasWon'] ?? false;
        });
      } catch (e) {
        _newGame();
      }
    } else {
      _newGame();
    }
  }

  Future<void> _saveGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final state = {
      'board': board,
      'score': score,
      'isGameOver': isGameOver,
      'hasWon': hasWon,
    };
    await prefs.setString(_saveKey, jsonEncode(state));
    
    if (score > highScore) {
      await prefs.setInt('${_saveKey}_high', score);
      setState(() => highScore = score);
    }
  }

  void _newGame() {
    setState(() {
      board = List.generate(gridSize, (_) => List.filled(gridSize, 0));
      score = 0;
      isGameOver = false;
      hasWon = false;
    });
    _addRandomTile();
    _addRandomTile();
    _saveGameState();
  }

  void _addRandomTile() {
    List<Point<int>> empty = [];
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (board[i][j] == 0) empty.add(Point(i, j));
      }
    }
    
    if (empty.isEmpty) return;
    
    final random = Random();
    final pos = empty[random.nextInt(empty.length)];
    board[pos.x][pos.y] = random.nextDouble() < 0.9 ? 2 : 4;
  }

  bool _canMove() {
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (board[i][j] == 0) return true;
        if (j < gridSize - 1 && board[i][j] == board[i][j + 1]) return true;
        if (i < gridSize - 1 && board[i][j] == board[i + 1][j]) return true;
      }
    }
    return false;
  }

  List<int> _slideRow(List<int> row) {
    List<int> result = row.where((x) => x != 0).toList();
    
    for (int i = 0; i < result.length - 1; i++) {
      if (result[i] == result[i + 1]) {
        result[i] *= 2;
        score += result[i];
        if (result[i] == 2048 && !hasWon) hasWon = true;
        result.removeAt(i + 1);
      }
    }
    
    while (result.length < gridSize) {
      result.add(0);
    }
    
    return result;
  }

  void _move(String direction) {
    if (isGameOver) return;
    
    List<List<int>> oldBoard = board.map((r) => List<int>.from(r)).toList();
    
    switch (direction) {
      case 'left':
        for (int i = 0; i < gridSize; i++) {
          board[i] = _slideRow(board[i]);
        }
        break;
      case 'right':
        for (int i = 0; i < gridSize; i++) {
          board[i] = _slideRow(board[i].reversed.toList()).reversed.toList();
        }
        break;
      case 'up':
        for (int j = 0; j < gridSize; j++) {
          List<int> col = [for (int i = 0; i < gridSize; i++) board[i][j]];
          col = _slideRow(col);
          for (int i = 0; i < gridSize; i++) {
            board[i][j] = col[i];
          }
        }
        break;
      case 'down':
        for (int j = 0; j < gridSize; j++) {
          List<int> col = [for (int i = gridSize - 1; i >= 0; i--) board[i][j]];
          col = _slideRow(col);
          for (int i = 0; i < gridSize; i++) {
            board[gridSize - 1 - i][j] = col[i];
          }
        }
        break;
    }
    
    bool moved = false;
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (board[i][j] != oldBoard[i][j]) {
          moved = true;
          break;
        }
      }
      if (moved) break;
    }
    
    if (moved) {
      _addRandomTile();
      if (!_canMove()) {
        isGameOver = true;
      }
      setState(() {});
      _saveGameState();
    }
  }

  Color _getTileColor(int value) {
    switch (value) {
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
      default: return const Color(0xFF3C3A32);
    }
  }

  Color _getTextColor(int value) => value <= 4 ? Colors.grey.shade700 : Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2048'),
        actions: [
          IconButton(
            onPressed: _newGame,
            icon: const Icon(LucideIcons.refreshCw),
            tooltip: 'New Game',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ScoreBox(label: 'Score', value: score),
                _ScoreBox(label: 'Best', value: highScore),
              ],
            ),
          ),
          
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (d) {
                if (d.velocity.pixelsPerSecond.dx > 100) _move('right');
                if (d.velocity.pixelsPerSecond.dx < -100) _move('left');
              },
              onVerticalDragEnd: (d) {
                if (d.velocity.pixelsPerSecond.dy > 100) _move('down');
                if (d.velocity.pixelsPerSecond.dy < -100) _move('up');
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final boardSize = min(constraints.maxWidth, constraints.maxHeight) - 32;
                  final cellSize = (boardSize - 16) / gridSize;
                  
                  return Center(
                    child: Container(
                      width: boardSize,
                      height: boardSize,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBBADA0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          // Grid
                          GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: gridSize,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                            itemCount: gridSize * gridSize,
                            itemBuilder: (context, index) {
                              final i = index ~/ gridSize;
                              final j = index % gridSize;
                              final value = board[i][j];
                              
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                decoration: BoxDecoration(
                                  color: value == 0 ? const Color(0xFFCDC1B4) : _getTileColor(value),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: value == 0 ? null : Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Text(
                                        '$value',
                                        style: TextStyle(
                                          fontSize: value >= 1000 ? 20 : 28,
                                          fontWeight: FontWeight.bold,
                                          color: _getTextColor(value),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          // Game Over / Win overlay
                          if (isGameOver || hasWon)
                            Container(
                              decoration: BoxDecoration(
                                color: (hasWon ? Colors.amber : Colors.black).withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      hasWon ? LucideIcons.trophy : LucideIcons.frown,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      hasWon ? 'You Win!' : 'Game Over!',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _newGame,
                                      icon: const Icon(LucideIcons.refreshCw),
                                      label: const Text('New Game'),
                                    ),
                                  ],
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
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Swipe to move tiles',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String label;
  final int value;
  
  const _ScoreBox({required this.label, required this.value});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFBBADA0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.white70)),
          Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
