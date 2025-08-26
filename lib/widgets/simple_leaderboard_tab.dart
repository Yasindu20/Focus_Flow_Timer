import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/leaderboard.dart';
import '../services/leaderboard_service.dart';
import '../widgets/leaderboard_card.dart';

/// A simplified tab-friendly version of LeaderboardScreen content
class SimpleLeaderboardTab extends StatefulWidget {
  const SimpleLeaderboardTab({super.key});

  @override
  State<SimpleLeaderboardTab> createState() => _SimpleLeaderboardTabState();
}

class _SimpleLeaderboardTabState extends State<SimpleLeaderboardTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: LeaderboardType.values.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeaderboardService>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LeaderboardService>(
      builder: (context, leaderboardService, child) {
        return Column(
          children: [
            // Custom tab bar for leaderboard types
            Container(
              color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                onTap: (index) {
                  // Tab selection is handled by TabController automatically
                },
                tabs: LeaderboardType.values.map((type) {
                  return Tab(
                    text: _getLeaderboardTypeLabel(type),
                    icon: Icon(_getLeaderboardTypeIcon(type)),
                  );
                }).toList(),
              ),
            ),
            // Content area
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: LeaderboardType.values.map((type) {
                  return _buildLeaderboardContent(leaderboardService, type);
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLeaderboardContent(LeaderboardService service, LeaderboardType type) {
    final leaderboard = service.getLeaderboard(type);
    
    // Handle null leaderboard or empty entries
    if (leaderboard == null || leaderboard.entries.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => service.refreshLeaderboards(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leaderboard.entries.length,
        itemBuilder: (context, index) {
          final entry = leaderboard.entries[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LeaderboardCard(
              entry: entry,
              leaderboardType: type,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No rankings available yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete some focus sessions to see rankings!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getLeaderboardTypeLabel(LeaderboardType type) {
    switch (type) {
      case LeaderboardType.productivity:
        return 'Productivity';
      case LeaderboardType.focusTime:
        return 'Focus Time';
      case LeaderboardType.tasks:
        return 'Tasks';
      case LeaderboardType.streaks:
        return 'Streaks';
      case LeaderboardType.sessions:
        return 'Sessions';
      case LeaderboardType.consistency:
        return 'Consistency';
    }
  }

  IconData _getLeaderboardTypeIcon(LeaderboardType type) {
    switch (type) {
      case LeaderboardType.productivity:
        return Icons.trending_up;
      case LeaderboardType.focusTime:
        return Icons.timer;
      case LeaderboardType.tasks:
        return Icons.task_alt;
      case LeaderboardType.streaks:
        return Icons.local_fire_department;
      case LeaderboardType.sessions:
        return Icons.play_circle;
      case LeaderboardType.consistency:
        return Icons.check_circle;
    }
  }
}