import 'package:flutter/material.dart';
import 'package:gatekeeper_resident/widgets/custom_button.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class GameCard {
  final int id;
  final IconData icon;
  bool isFlipped;
  bool isMatched;

  GameCard({
    required this.id,
    required this.icon,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

class _GameScreenState extends State<GameScreen> {
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

  @override
  void initState() {
    super.initState();
    _initializeGame(_stage);
  }

  void _initializeGame(int stage) {
    int tileCount = 4 + (stage - 1) * 2;
    // Cap tiles if we run out of icons (simple logic fix)
    if (tileCount > _icons.length * 2) tileCount = _icons.length * 2;
    
    int pairCount = tileCount ~/ 2;
    _allowedMoves = (tileCount * 2) - (tileCount ~/ 2);

    List<IconData> selectedIcons = _icons.take(pairCount).toList();
    if (selectedIcons.length < pairCount) {
      // Simplistic fill if not enough unique icons
      selectedIcons.addAll(_icons.take(pairCount - selectedIcons.length));
    }

    List<GameCard> pairs = [];
    for (var i = 0; i < selectedIcons.length; i++) {
        pairs.add(GameCard(id: i * 2, icon: selectedIcons[i]));
        pairs.add(GameCard(id: i * 2 + 1, icon: selectedIcons[i]));
    }
    
    pairs.shuffle();

    setState(() {
      _cards = pairs;
      _flippedIndices = [];
      _moves = 0;
      _isGameWon = false;
    });
  }

  void _handleCardTap(int index) {
    if (_flippedIndices.length == 2 || _cards[index].isFlipped || _cards[index].isMatched) return;

    setState(() {
      _cards[index].isFlipped = true;
      _flippedIndices.add(index);
    });

    if (_flippedIndices.length == 2) {
      setState(() => _moves++); // Fix applied here too: increment on pair completion
      _checkForMatch();
    }
  }

  void _checkForMatch() {
    final idx1 = _flippedIndices[0];
    final idx2 = _flippedIndices[1];

    if (_cards[idx1].icon == _cards[idx2].icon) {
      Timer(const Duration(milliseconds: 500), () {
        setState(() {
          _cards[idx1].isMatched = true;
          _cards[idx2].isMatched = true;
          _flippedIndices.clear();
          
          if (_cards.every((c) => c.isMatched)) {
            _isGameWon = true;
          }
        });
      });
    } else {
       Timer(const Duration(milliseconds: 1000), () {
        setState(() {
          _cards[idx1].isFlipped = false;
          _cards[idx2].isFlipped = false;
          _flippedIndices.clear();
        });
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
    setState(() {
      _stage = 1;
      _initializeGame(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isFailed = _moves > _allowedMoves && _isGameWon;

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
                GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 100,
                    childAspectRatio: 1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return GestureDetector(
                      onTap: () => _handleCardTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: (card.isFlipped || card.isMatched) ? Colors.white : Colors.indigo,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.indigo),
                        ),
                        child: Center(
                          child: (card.isFlipped || card.isMatched)
                              ? Icon(card.icon, size: 32, color: Colors.indigo)
                              : const Icon(LucideIcons.gamepad2, color: Colors.white24),
                        ),
                      ),
                    );
                  },
                ),

                if (_isGameWon)
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
