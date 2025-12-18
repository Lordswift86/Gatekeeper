import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gatekeeper_estate_admin/modules/resident/screens/games/memory_game_screen.dart';
import 'package:gatekeeper_estate_admin/modules/resident/screens/games/snake_game_screen.dart';
import 'package:gatekeeper_estate_admin/modules/resident/screens/games/game_2048_screen.dart';
import 'package:gatekeeper_estate_admin/modules/resident/screens/games/color_switch_game_screen.dart';
import 'package:gatekeeper_estate_admin/modules/resident/screens/games/breathing_game_screen.dart';

class GameHubScreen extends StatelessWidget {
  const GameHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relax Zone'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Take a break',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose an activity to unwind',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
                children: const [
                  _GameCard(
                    title: 'Memory Match',
                    subtitle: 'Match the pairs',
                    icon: LucideIcons.brain,
                    color: Colors.indigo,
                    targetScreen: MemoryGameScreen(),
                  ),
                  _GameCard(
                    title: 'Snake',
                    subtitle: 'Classic arcade',
                    icon: LucideIcons.bug,
                    color: Colors.green,
                    targetScreen: SnakeGameScreen(),
                  ),
                  _GameCard(
                    title: '2048',
                    subtitle: 'Tile puzzle',
                    icon: LucideIcons.layoutGrid,
                    color: Colors.orange,
                    targetScreen: Game2048Screen(),
                  ),
                  _GameCard(
                    title: 'Color Switch',
                    subtitle: 'Test reflexes',
                    icon: LucideIcons.palette,
                    color: Colors.purple,
                    targetScreen: ColorSwitchGameScreen(),
                  ),
                  _GameCard(
                    title: 'Breathing',
                    subtitle: 'Calm your mind',
                    icon: LucideIcons.wind,
                    color: Colors.teal,
                    targetScreen: BreathingGameScreen(),
                    isWellness: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget targetScreen;
  final bool isWellness;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.targetScreen,
    this.isWellness = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetScreen),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.8),
              color,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                icon,
                size: 100,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      if (isWellness)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '🧘',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
