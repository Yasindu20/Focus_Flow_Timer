import 'package:flutter/material.dart';

class StreakWidget extends StatelessWidget {
  final int streak;

  const StreakWidget({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Focus Streak',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                streak.toString(),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                streak == 1 ? 'day' : 'days',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getStreakMessage(streak),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          _buildStreakBadges(streak),
        ],
      ),
    );
  }

  Widget _buildStreakBadges(int streak) {
    final badges = <Widget>[];
    
    // Add flame icons based on streak milestones
    if (streak >= 1) badges.add(_buildBadge(Icons.local_fire_department, Colors.orange.shade300));
    if (streak >= 3) badges.add(_buildBadge(Icons.local_fire_department, Colors.orange.shade400));
    if (streak >= 7) badges.add(_buildBadge(Icons.local_fire_department, Colors.orange.shade500));
    if (streak >= 14) badges.add(_buildBadge(Icons.whatshot, Colors.red.shade400));
    if (streak >= 30) badges.add(_buildBadge(Icons.whatshot, Colors.red.shade600));

    return Row(
      children: badges,
    );
  }

  Widget _buildBadge(IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(
        icon,
        color: color,
        size: 16,
      ),
    );
  }

  String _getStreakMessage(int streak) {
    if (streak == 0) return 'Start your focus journey today!';
    if (streak == 1) return 'Great start! Keep it up!';
    if (streak < 7) return 'Building momentum!';
    if (streak < 14) return 'You\'re on fire!';
    if (streak < 30) return 'Incredible consistency!';
    return 'Focus master! Outstanding!';
  }
}