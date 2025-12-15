import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
                    route: '/game/memory',
                  ),
                  _GameCard(
                    title: 'Snake',
                    subtitle: 'Classic arcade',
                    icon: LucideIcons.bug, // No snake icon, using bug
                    color: Colors.green,
                    route: '/game/snake',
                  ),
                  _GameCard(
                    title: '2048',
                    subtitle: 'Tile puzzle',
                    icon: LucideIcons.layoutGrid,
                    color: Colors.orange,
                    route: '/game/2048',
                  ),
                  _GameCard(
                    title: 'Color Switch',
                    subtitle: 'Test reflexes',
                    icon: LucideIcons.palette,
                    color: Colors.purple,
                    route: '/game/color',
                  ),
                  _GameCard(
                    title: 'Breathing',
                    subtitle: 'Calm your mind',
                    icon: LucideIcons.wind,
                    color: Colors.teal,
                    route: '/game/breathing',
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
  final String route;
  final bool isWellness;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    this.isWellness = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.8),
              color,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
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
                color: Colors.white.withOpacity(0.1),
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
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      if (isWellness)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
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
                      color: Colors.white.withOpacity(0.8),
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
