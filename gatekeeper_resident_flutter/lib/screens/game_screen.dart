import 'package:flutter/material.dart';
import 'package:gatekeeper_resident/widgets/custom_button.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class GameCard {
  final int id;
  final int iconIndex; // Store index instead of IconData for serialization
  bool isFlipped;
  bool isMatched;

  GameCard({
    required this.id,
    required this.iconIndex,
    this.isFlipped = false,
    this.isMatched = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'iconIndex': iconIndex,
    'isFlipped': isFlipped,
    'isMatched': isMatched,
  };

  factory GameCard.fromJson(Map<String, dynamic> json) => GameCard(
    id: json['id'],
    iconIndex: json['iconIndex'],
    isFlipped: json['isFlipped'],
    isMatched: json['isMatched'],
  );
}

class _GameScreenState extends State<GameScreen> {
  static const String _saveKey = 'game_state';
  
  final List<IconData> _icons = [
    LucideIcons.ghost, LucideIcons.heart, LucideIcons.star, LucideIcons.zap, 
    LucideIcons.cloud, LucideIcons.moon, LucideIcons.sun, LucideIcons.anchor,
    LucideIcons.coffee, LucideIcons.music, LucideIcons.smile, LucideIcons.trophy
  ];

  List<GameCard> _cards = [];
  List<int> _flippedIndices = [];
  int _moves = 0;
  int _allowedMoves = 0;
  int _stage = 1;
  bool _isGameWon = false;
  final int _maxStage = 20;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGameState();
  }

  // ========== Persistence Methods ==========
  
  Future<void> _loadGameState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedState = prefs.getString(_saveKey);
      
      if (savedState != null) {
        final state = jsonDecode(savedState);
        setState(() {
          _stage = state['stage'] ?? 1;
          _moves = state['moves'] ?? 0;
          _allowedMoves = state['allowedMoves'] ?? 0;
          _isGameWon = state['isGameWon'] ?? false;
          _cards = (state['cards'] as List)
              .map((c) => GameCard.fromJson(c))
              .toList();
          _isLoading = false;
        });
      } else {
        _initializeGame(_stage);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _initializeGame(_stage);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveGameState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final state = {
        'stage': _stage,
        'moves': _moves,
        'allowedMoves': _allowedMoves,
        'isGameWon': _isGameWon,
        'cards': _cards.map((c) => c.toJson()).toList(),
      };
      await prefs.setString(_saveKey, jsonEncode(state));
    } catch (e) {
      debugPrint('Failed to save game state: $e');
    }
  }

  Future<void> _clearGameState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_saveKey);
    } catch (e) {
      debugPrint('Failed to clear game state: $e');
    }
  }

  // ========== Game Logic ==========

  void _initializeGame(int stage) {
    int tileCount = 4 + (stage - 1) * 2;
    // Cap tiles if we run out of icons
    if (tileCount > _icons.length * 2) tileCount = _icons.length * 2;
    
    int pairCount = tileCount ~/ 2;
    _allowedMoves = (tileCount * 2) - (tileCount ~/ 2);

    List<int> selectedIconIndices = List.generate(pairCount, (i) => i % _icons.length);

    List<GameCard> pairs = [];
    for (var i = 0; i < selectedIconIndices.length; i++) {
      pairs.add(GameCard(id: i * 2, iconIndex: selectedIconIndices[i]));
      pairs.add(GameCard(id: i * 2 + 1, iconIndex: selectedIconIndices[i]));
    }
    
    pairs.shuffle();

    setState(() {
      _cards = pairs;
      _flippedIndices = [];
      _moves = 0;
      _isGameWon = false;
    });
    
    _saveGameState();
  }

  void _handleCardTap(int index) {
    if (_flippedIndices.length == 2 || _cards[index].isFlipped || _cards[index].isMatched) return;

    setState(() {
      _cards[index].isFlipped = true;
      _flippedIndices.add(index);
    });

    if (_flippedIndices.length == 2) {
      setState(() => _moves++);
      _checkForMatch();
    }
    
    _saveGameState();
  }

  void _checkForMatch() {
    final idx1 = _flippedIndices[0];
    final idx2 = _flippedIndices[1];

    if (_cards[idx1].iconIndex == _cards[idx2].iconIndex) {
      Timer(const Duration(milliseconds: 500), () {
        setState(() {
          _cards[idx1].isMatched = true;
          _cards[idx2].isMatched = true;
          _flippedIndices.clear();
          
          if (_cards.every((c) => c.isMatched)) {
            _isGameWon = true;
          }
        });
        _saveGameState();
      });
    } else {
       Timer(const Duration(milliseconds: 1000), () {
        setState(() {
          _cards[idx1].isFlipped = false;
          _cards[idx2].isFlipped = false;
          _flippedIndices.clear();
        });
        _saveGameState();
      });
    }
  }

  void _nextStage() {
    if (_stage < _maxStage) {
      setState(() {
        _stage++;
        _initializeGame(_stage);
      });
    }
  }

  void _resetGame() {
    _clearGameState();
    setState(() {
      _stage = 1;
      _initializeGame(1);
    });
  }

  // ========== Grid Calculation ==========
  
  /// Calculate optimal grid dimensions to fit all tiles without scrolling
  (int columns, int rows) _calculateGridDimensions(int tileCount) {
    // Find the most square-like arrangement
    int cols = 2;
    int rows = (tileCount / cols).ceil();
    
    // Try to find a more balanced layout
    for (int c = 2; c <= tileCount ~/ 2; c++) {
      if (tileCount % c == 0) {
        int r = tileCount ~/ c;
        // Prefer layouts that are more square and wider than tall
        if ((c - r).abs() < (cols - rows).abs() || (c > r && cols < rows)) {
          cols = c;
          rows = r;
        }
      }
    }
    
    // Ensure more columns than rows for landscape feel
    if (rows > cols) {
      int temp = rows;
      rows = cols;
      cols = temp;
    }
    
    return (cols, rows);
  }

  @override
  Widget build(BuildContext context) {
    bool isFailed = _moves > _allowedMoves && !_isGameWon;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Relax Zone')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relax Zone'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text('Stage $_stage / $_maxStage', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _moves > _allowedMoves ? Colors.red.withOpacity(0.1) : Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _moves > _allowedMoves ? Colors.red : Colors.indigo),
              ),
              child: Text(
                'Moves: $_moves / $_allowedMoves',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _moves > _allowedMoves ? Colors.red : Colors.indigo,
                ),
              ),
            ),
          ),
          
          Expanded(
            child: Stack(
              children: [
                // Use LayoutBuilder for dynamic tile sizing
                LayoutBuilder(
                  builder: (context, constraints) {
                    final (columns, rows) = _calculateGridDimensions(_cards.length);
                    
                    const double padding = 16.0;
                    const double spacing = 8.0;
                    
                    // Calculate available space
                    final availableWidth = constraints.maxWidth - (padding * 2) - (spacing * (columns - 1));
                    final availableHeight = constraints.maxHeight - (padding * 2) - (spacing * (rows - 1));
                    
                    // Calculate tile size to fit all tiles
                    final tileWidth = availableWidth / columns;
                    final tileHeight = availableHeight / rows;
                    final tileSize = tileWidth < tileHeight ? tileWidth : tileHeight;
                    
                    // Icon size scales with tile
                    final iconSize = (tileSize * 0.4).clamp(16.0, 40.0);
                    
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(padding),
                        child: Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          alignment: WrapAlignment.center,
                          children: List.generate(_cards.length, (index) {
                            final card = _cards[index];
                            return GestureDetector(
                              onTap: () => _handleCardTap(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: tileSize,
                                height: tileSize,
                                decoration: BoxDecoration(
                                  color: (card.isFlipped || card.isMatched) ? Colors.white : Colors.indigo,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.indigo),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: (card.isFlipped || card.isMatched)
                                      ? Icon(_icons[card.iconIndex], size: iconSize, color: Colors.indigo)
                                      : Icon(LucideIcons.gamepad2, size: iconSize, color: Colors.white24),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  },
                ),

                if (_isGameWon || isFailed)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(32),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             Icon(
                               isFailed ? LucideIcons.xCircle : (_stage == _maxStage ? LucideIcons.crown : LucideIcons.trophy),
                               size: 64,
                               color: isFailed ? Colors.red : Colors.amber,
                             ),
                             const SizedBox(height: 16),
                             Text(
                               isFailed ? 'Level Failed' : (_stage == _maxStage ? 'Champion!' : 'Level Complete!'),
                               style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                             ),
                             const SizedBox(height: 8),
                             Text('Moves taken: $_moves'),
                             const SizedBox(height: 24),
                             if (isFailed)
                               CustomButton(text: 'Retry', onPressed: () => _initializeGame(_stage), isDanger: true)
                             else if (_stage < _maxStage)
                               CustomButton(text: 'Next Level', onPressed: _nextStage)
                             else
                               CustomButton(text: 'Play Again', onPressed: _resetGame)
                          ],
                        ),
                      ),
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
