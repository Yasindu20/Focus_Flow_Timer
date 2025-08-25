import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/leaderboard.dart';
import '../services/leaderboard_service.dart';
import '../widgets/leaderboard_card.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LeaderboardType _selectedType = LeaderboardType.productivity;

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
        return Scaffold(
          appBar: AppBar(
            title: const Text('Leaderboards'),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                onPressed: () => leaderboardService.refreshLeaderboards(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
              IconButton(
                onPressed: () => _showLeaderboardInfo(context, leaderboardService),
                icon: const Icon(Icons.info_outline),
                tooltip: 'Info',
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildUserRankCard(leaderboardService),
                _buildLeaderboardTypeSelector(),
                Expanded(
                  child: _buildLeaderboardContent(leaderboardService),
                ),
              ],
            ),
          ),
          floatingActionButton: leaderboardService.isOnline
              ? null
              : FloatingActionButton.extended(
                  heroTag: "leaderboard_fab",
                  onPressed: () => _showOfflineMessage(context),
                  icon: const Icon(Icons.cloud_off),
                  label: const Text('Offline'),
                  backgroundColor: Colors.grey,
                ),
        );
      },
    );
  }

  Widget _buildUserRankCard(LeaderboardService service) {
    final userEntry = service.userEntry;
    final currentLeaderboard = service.getLeaderboard(_selectedType);
    
    if (userEntry == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey[300]!,
              Colors.grey[200]!,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.grey[600]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Join the Competition!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Complete focus sessions to join the leaderboard',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final userRank = service.getUserRank(_selectedType) ?? 0;
    final totalParticipants = currentLeaderboard?.totalParticipants ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getRankGradientColors(userRank),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: userEntry.avatar != null
                ? NetworkImage(userEntry.avatar!)
                : null,
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            child: userEntry.avatar == null
                ? Text(
                    userEntry.displayName.isNotEmpty
                        ? userEntry.displayName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userEntry.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Rank #$userRank of $totalParticipants',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _getDisplayValue(userEntry, _selectedType),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                _getDisplayUnit(_selectedType),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTypeSelector() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: LeaderboardType.values.length,
        itemBuilder: (context, index) {
          final type = LeaderboardType.values[index];
          final isSelected = _selectedType == type;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = type;
              });
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    LeaderboardConfig.typeIcons[type] ?? '🏆',
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LeaderboardConfig.typeNames[type]?.split(' ')[0] ?? 'Unknown',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardContent(LeaderboardService service) {
    final leaderboard = service.getLeaderboard(_selectedType);
    
    if (leaderboard == null || leaderboard.entries.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => service.refreshLeaderboards(),
      child: Column(
        children: [
          if (leaderboard.entries.isNotEmpty) _buildPodium(leaderboard.topTen.take(3).toList()),
          Expanded(
            child: _buildLeaderboardList(leaderboard.entries),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> topThree) {
    if (topThree.length < 3) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(
        minHeight: 150,
        maxHeight: 180,
      ),
      margin: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Second place
          Expanded(
            child: _buildPodiumPosition(
              topThree.length > 1 ? topThree[1] : null,
              2,
              120,
              Colors.grey,
            ),
          ),
          // First place
          Expanded(
            child: _buildPodiumPosition(
              topThree[0],
              1,
              160,
              Colors.amber,
            ),
          ),
          // Third place
          Expanded(
            child: _buildPodiumPosition(
              topThree.length > 2 ? topThree[2] : null,
              3,
              100,
              Colors.brown,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPosition(
    LeaderboardEntry? entry,
    int position,
    double height,
    Color color,
  ) {
    if (entry == null) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Center(
          child: Text(
            '-',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.8),
            color.withValues(alpha: 0.6),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 20,
            backgroundImage: entry.avatar != null
                ? NetworkImage(entry.avatar!)
                : null,
            backgroundColor: Colors.white,
            child: entry.avatar == null
                ? Text(
                    entry.displayName.isNotEmpty
                        ? entry.displayName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  )
                : null,
          ),
          Text(
            entry.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _getDisplayValue(entry, _selectedType),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$position',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(List<LeaderboardEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isCurrentUser = entry.userId == Provider.of<LeaderboardService>(context, listen: false).userEntry?.userId;
        
        return LeaderboardCard(
          entry: entry,
          leaderboardType: _selectedType,
          isCurrentUser: isCurrentUser,
          onTap: () => _showUserProfile(context, entry),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 80,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No Rankings Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Complete focus sessions to join the leaderboard and compete with others!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.timer),
            label: const Text('Start Focusing'),
          ),
        ],
      ),
    );
  }

  void _showUserProfile(BuildContext context, LeaderboardEntry entry) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: entry.avatar != null
                    ? NetworkImage(entry.avatar!)
                    : null,
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                child: entry.avatar == null
                    ? Text(
                        entry.displayName.isNotEmpty
                            ? entry.displayName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                entry.displayName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rank #${entry.rank}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _getRankColor(entry.rank),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              _buildProfileStats(entry),
              const SizedBox(height: 20),
              _buildAchievementsList(entry.achievements),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStats(LeaderboardEntry entry) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatColumn(
                'Focus Time',
                entry.formattedFocusTime,
                Icons.timer,
              ),
            ),
            Expanded(
              child: _buildStatColumn(
                'Sessions',
                '${entry.sessionsCompleted}',
                Icons.play_circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatColumn(
                'Streak',
                '${entry.streakDays} days',
                Icons.local_fire_department,
              ),
            ),
            Expanded(
              child: _buildStatColumn(
                'Score',
                '${entry.score.toInt()}',
                Icons.star,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsList(List<String> achievementIds) {
    if (achievementIds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.emoji_events_outlined, color: Colors.grey),
            SizedBox(width: 8),
            Text('No achievements yet'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Achievements (${achievementIds.length})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: achievementIds.take(6).map((id) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '🏆',
                  style: TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
          ),
          if (achievementIds.length > 6)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${achievementIds.length - 6} more',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showLeaderboardInfo(BuildContext context, LeaderboardService service) {
    final insights = service.getLeaderboardInsights();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.leaderboard,
                color: Theme.of(context).primaryColor,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Leaderboard Info',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ...List<String>.from(insights['insights'] ?? []).map(
                (insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(insight),
                ),
              ),
              if (List<String>.from(insights['suggestions'] ?? []).isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Tips to Climb the Leaderboard',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...List<String>.from(insights['suggestions'] ?? []).map(
                  (suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• $suggestion'),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total Players: ${insights['total_participants'] ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(
                    insights['is_top_performer'] == true
                        ? Icons.star
                        : Icons.trending_up,
                    color: insights['is_top_performer'] == true
                        ? Colors.amber
                        : Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('Got it!'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOfflineMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.white),
            SizedBox(width: 8),
            Text('You\'re offline. Rankings may not be current.'),
          ],
        ),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _getDisplayValue(LeaderboardEntry entry, LeaderboardType type) {
    switch (type) {
      case LeaderboardType.productivity:
        return '${entry.score.toInt()}';
      case LeaderboardType.focusTime:
        return entry.formattedFocusTime;
      case LeaderboardType.streaks:
        return '${entry.streakDays}';
      case LeaderboardType.sessions:
        return '${entry.sessionsCompleted}';
      case LeaderboardType.tasks:
        return '${entry.stats.tasksCompleted}';
      case LeaderboardType.consistency:
        return '${entry.stats.weeklyScore.toInt()}';
    }
  }

  String _getDisplayUnit(LeaderboardType type) {
    switch (type) {
      case LeaderboardType.productivity:
        return 'score';
      case LeaderboardType.focusTime:
        return '';
      case LeaderboardType.streaks:
        return 'days';
      case LeaderboardType.sessions:
        return 'sessions';
      case LeaderboardType.tasks:
        return 'tasks';
      case LeaderboardType.consistency:
        return 'score';
    }
  }

  List<Color> _getRankGradientColors(int rank) {
    if (rank == 1) {
      return [Colors.amber[400]!, Colors.amber[600]!];
    } else if (rank <= 3) {
      return [Colors.orange[400]!, Colors.orange[600]!];
    } else if (rank <= 10) {
      return [Colors.blue[400]!, Colors.blue[600]!];
    } else {
      return [Colors.grey[400]!, Colors.grey[600]!];
    }
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank <= 3) return Colors.orange;
    if (rank <= 10) return Colors.blue;
    return Colors.grey;
  }
}