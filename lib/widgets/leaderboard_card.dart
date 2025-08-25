import 'package:flutter/material.dart';
import '../models/leaderboard.dart';

class LeaderboardCard extends StatefulWidget {
  final LeaderboardEntry entry;
  final LeaderboardType leaderboardType;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  const LeaderboardCard({
    super.key,
    required this.entry,
    required this.leaderboardType,
    this.isCurrentUser = false,
    this.onTap,
  });

  @override
  State<LeaderboardCard> createState() => _LeaderboardCardState();
}

class _LeaderboardCardState extends State<LeaderboardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTopRank = widget.entry.rank <= 3;
    // final isPodiumFinisher = widget.entry.rank <= 10;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) => _animationController.reverse(),
            onTapCancel: () => _animationController.reverse(),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: widget.isCurrentUser
                    ? LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.1),
                          Theme.of(context).primaryColor.withOpacity(0.05),
                        ],
                      )
                    : null,
                color: widget.isCurrentUser ? null : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isCurrentUser
                      ? Theme.of(context).primaryColor
                      : isTopRank
                          ? _getRankColor(widget.entry.rank).withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                  width: widget.isCurrentUser ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isCurrentUser
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: widget.isCurrentUser ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Rank indicator
                  _buildRankIndicator(),
                  const SizedBox(width: 16),
                  
                  // User avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: widget.entry.avatar != null
                        ? NetworkImage(widget.entry.avatar!)
                        : null,
                    backgroundColor: _getRankColor(widget.entry.rank).withOpacity(0.2),
                    child: widget.entry.avatar == null
                        ? Text(
                            widget.entry.displayName.isNotEmpty
                                ? widget.entry.displayName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getRankColor(widget.entry.rank),
                            ),
                          )
                        : null,
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.entry.displayName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: widget.isCurrentUser
                                      ? Theme.of(context).primaryColor
                                      : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.isCurrentUser)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'You',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _buildUserStats(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Main metric value
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _getDisplayValue(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isTopRank ? _getRankColor(widget.entry.rank) : Colors.black87,
                        ),
                      ),
                      Text(
                        _getDisplayUnit(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  
                  // Achievement indicators
                  if (widget.entry.achievements.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _buildAchievementIndicator(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankIndicator() {
    final rank = widget.entry.rank;
    final isTopRank = rank <= 3;
    final rankColor = _getRankColor(rank);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: isTopRank
            ? LinearGradient(
                colors: [
                  rankColor.withOpacity(0.8),
                  rankColor.withOpacity(0.6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        color: isTopRank ? null : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTopRank ? rankColor : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Center(
        child: rank <= 3
            ? Icon(
                _getRankIcon(rank),
                color: Colors.white,
                size: 18,
              )
            : Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  Widget _buildUserStats() {
    return Row(
      children: [
        _buildStatItem(
          Icons.timer,
          widget.entry.formattedFocusTime,
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          Icons.local_fire_department,
          '${widget.entry.streakDays}d',
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          Icons.play_circle_outline,
          '${widget.entry.sessionsCompleted}',
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementIndicator() {
    final achievementCount = widget.entry.achievements.length;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.emoji_events,
            color: Colors.amber,
            size: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$achievementCount',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ),
      ],
    );
  }

  String _getDisplayValue() {
    switch (widget.leaderboardType) {
      case LeaderboardType.productivity:
        return '${widget.entry.score.toInt()}';
      case LeaderboardType.focusTime:
        return widget.entry.formattedFocusTime;
      case LeaderboardType.streaks:
        return '${widget.entry.streakDays}';
      case LeaderboardType.sessions:
        return '${widget.entry.sessionsCompleted}';
      case LeaderboardType.tasks:
        return '${widget.entry.stats.tasksCompleted}';
      case LeaderboardType.consistency:
        return '${widget.entry.stats.weeklyScore.toInt()}';
    }
  }

  String _getDisplayUnit() {
    switch (widget.leaderboardType) {
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
        return 'consistency';
    }
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber[600]!; // Gold
    if (rank == 2) return Colors.grey[400]!; // Silver
    if (rank == 3) return Colors.brown[400]!; // Bronze
    if (rank <= 10) return Colors.blue[400]!; // Top 10
    return Colors.grey[600]!; // Others
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.looks_one;
      case 2:
        return Icons.looks_two;
      case 3:
        return Icons.looks_3;
      default:
        return Icons.star;
    }
  }
}

class LeaderboardEmptyCard extends StatelessWidget {
  final String message;
  final VoidCallback? onAction;
  final String? actionText;

  const LeaderboardEmptyCard({
    super.key,
    required this.message,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionText != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(actionText!),
            ),
          ],
        ],
      ),
    );
  }
}

class RankChangeIndicator extends StatelessWidget {
  final int rankChange;
  final bool animate;

  const RankChangeIndicator({
    super.key,
    required this.rankChange,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (rankChange == 0) return const SizedBox.shrink();

    final isPositive = rankChange > 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 2),
          Text(
            '${rankChange.abs()}',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}