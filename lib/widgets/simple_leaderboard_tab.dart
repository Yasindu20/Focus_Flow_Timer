import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/leaderboard.dart';
import '../services/leaderboard_service.dart';

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
      try {
        final service = Provider.of<LeaderboardService?>(context, listen: false);
        service?.initialize();
      } catch (e) {
        debugPrint('LeaderboardService initialization error: $e');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LeaderboardService?>(
      builder: (context, leaderboardService, child) {
        // Handle null service gracefully
        if (leaderboardService == null) {
          return const SafeArea(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenHeight < 700;
        final isNarrowScreen = screenWidth < 400;
        
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF1A1A2E).withValues(alpha: 0.7),
                        const Color(0xFF16213E).withValues(alpha: 0.3),
                      ]
                    : [
                        const Color(0xFFF8F9FA).withValues(alpha: 0.7),
                        const Color(0xFFE9ECEF).withValues(alpha: 0.3),
                      ],
              ),
            ),
            child: Column(
              children: [
                // Responsive Tab Bar with proper constraints
                Container(
                  constraints: BoxConstraints(
                    maxHeight: isSmallScreen ? 60 : 80,
                    minHeight: 50,
                  ),
                  child: _buildRankingTabBar(isDark, isSmallScreen, isNarrowScreen),
                ),
                
                // Content area that takes remaining space and handles overflow
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(), // Better mobile scroll physics
                    children: LeaderboardType.values.map((type) {
                      // Wrap each tab content in error boundary with proper scrolling
                      return Builder(
                        builder: (context) {
                          try {
                            return _buildEnhancedLeaderboardContent(leaderboardService, type);
                          } catch (e) {
                            debugPrint('Error building leaderboard content for $type: $e');
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, size: 48, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'Unable to load rankings',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  
  Widget _buildRankingTabBar(bool isDark, bool isSmallScreen, bool isNarrowScreen) {
    return SingleChildScrollView(
      child: Container(
        // Responsive margins for mobile optimization
        margin: EdgeInsets.fromLTRB(
          isSmallScreen ? 8 : 12,
          isSmallScreen ? 4 : 8,
          isSmallScreen ? 8 : 12,
          isSmallScreen ? 4 : 8,
        ),
        padding: EdgeInsets.all(isSmallScreen ? 2 : 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.05),
                ]
              : [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.7),
                ],
        ),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.2) 
              : Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.4) 
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        // Mobile-optimized TabBar properties
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade400,
              Colors.orange.shade500,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.3),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: isNarrowScreen ? 10 : (isSmallScreen ? 11 : 12),
          height: 1.2,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: isNarrowScreen ? 9 : (isSmallScreen ? 10 : 11),
          height: 1.2,
        ),
        labelPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 4 : 6,
          vertical: isSmallScreen ? 0 : 2,
        ),
        // Optimize for mobile scrolling
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: LeaderboardType.values.map((type) {
          return Tab(
            text: isNarrowScreen ? _getLeaderboardTypeShortLabel(type) : _getLeaderboardTypeLabel(type),
            icon: Icon(_getLeaderboardTypeIcon(type), size: isNarrowScreen ? 14 : (isSmallScreen ? 16 : 18)),
            iconMargin: EdgeInsets.only(bottom: isSmallScreen ? 2 : 4),
          );
        }).toList(),
        ),
      ),
    );
  }

  Widget _buildEnhancedLeaderboardContent(LeaderboardService? service, LeaderboardType type) {
    if (service == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final leaderboard = service.getLeaderboard(type);
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    // Handle null leaderboard or empty entries
    if (leaderboard == null || leaderboard.entries.isEmpty) {
      return _buildEnhancedEmptyState(type, isSmallScreen);
    }

    return RefreshIndicator(
      onRefresh: () async {
        try {
          await service.refreshLeaderboards();
        } catch (e) {
          debugPrint('Error refreshing leaderboards: $e');
        }
      },
      child: ListView.builder(
        // Ultra-compact padding for mobile devices
        padding: EdgeInsets.only(
          left: isSmallScreen ? 6 : 8,
          right: isSmallScreen ? 6 : 8,
          top: isSmallScreen ? 2 : 4,
          bottom: isSmallScreen ? 4 : 8,
        ),
        physics: const BouncingScrollPhysics(), // Better mobile scroll physics
        itemCount: leaderboard.entries.length,
        itemBuilder: (context, index) {
          try {
            final entry = leaderboard.entries[index];
            return _buildEnhancedLeaderboardCard(entry, type, index, isSmallScreen);
          } catch (e) {
            debugPrint('Error building leaderboard card at index $index: $e');
            return const SizedBox.shrink(); // Return empty widget on error
          }
        },
      ),
    );
  }


  Widget _buildEnhancedEmptyState(LeaderboardType type, bool isSmallScreen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryNarrow = screenWidth < 360;
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isVeryNarrow ? 16 : (isSmallScreen ? 20 : 24),
        vertical: isSmallScreen ? 20 : 32,
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isVeryNarrow ? screenWidth - 32 : 400,
          ),
          padding: EdgeInsets.all(isVeryNarrow ? 16 : (isSmallScreen ? 20 : 24)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isDark
                ? [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.8),
                    Colors.white.withValues(alpha: 0.4),
                  ],
          ),
          border: Border.all(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.2) 
                : Colors.white.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.3) 
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.shade400,
                    Colors.orange.shade500,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _getLeaderboardTypeIcon(type),
                size: isSmallScreen ? 24 : 32,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            Text(
              'No ${_getLeaderboardTypeLabel(type)} Rankings Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isVeryNarrow ? 18 : (isSmallScreen ? 20 : 24),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              'Complete focus sessions and climb the leaderboard!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: isVeryNarrow ? 13 : (isSmallScreen ? 14 : 16),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isVeryNarrow ? 12 : 16,
                vertical: isSmallScreen ? 6 : 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade400.withValues(alpha: 0.2),
                    Colors.purple.shade400.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.blue.shade400.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '🚀 Start your productivity journey',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: isVeryNarrow ? 12 : (isSmallScreen ? 13 : 14),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildEnhancedLeaderboardCard(dynamic entry, LeaderboardType type, int index, bool isSmallScreen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTopThree = index < 3;
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryNarrow = screenWidth < 360;
    final rankColors = [
      Colors.amber.shade500, // 1st place - Gold
      Colors.grey.shade400,  // 2nd place - Silver  
      Colors.orange.shade600, // 3rd place - Bronze
    ];
    
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 4 : 6),
      padding: EdgeInsets.symmetric(
        horizontal: isVeryNarrow ? 8 : (isSmallScreen ? 10 : 12),
        vertical: isSmallScreen ? 8 : 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: isTopThree ? 0.2 : 0.1),
                  Colors.white.withValues(alpha: isTopThree ? 0.1 : 0.05),
                ]
              : [
                  Colors.white.withValues(alpha: isTopThree ? 0.95 : 0.8),
                  Colors.white.withValues(alpha: isTopThree ? 0.8 : 0.6),
                ],
        ),
        border: Border.all(
          color: isTopThree 
              ? rankColors[index].withValues(alpha: 0.5)
              : (isDark ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.5)),
          width: isTopThree ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isTopThree 
                ? rankColors[index].withValues(alpha: 0.3)
                : (isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05)),
            blurRadius: isTopThree ? 12 : 8,
            spreadRadius: 0,
            offset: Offset(0, isTopThree ? 6 : 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge - responsive size
          Container(
            width: isVeryNarrow ? 28 : (isSmallScreen ? 32 : 36),
            height: isVeryNarrow ? 28 : (isSmallScreen ? 32 : 36),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isTopThree 
                    ? [rankColors[index], rankColors[index].withValues(alpha: 0.8)]
                    : [Colors.grey.shade400, Colors.grey.shade500],
              ),
              shape: BoxShape.circle,
              boxShadow: isTopThree ? [
                BoxShadow(
                  color: rankColors[index].withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ] : [],
            ),
            child: Center(
              child: isTopThree
                  ? Icon(
                      index == 0 ? Icons.emoji_events : 
                      index == 1 ? Icons.military_tech : Icons.workspace_premium,
                      color: Colors.white,
                      size: isVeryNarrow ? 14 : (isSmallScreen ? 16 : 18),
                    )
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isVeryNarrow ? 10 : (isSmallScreen ? 12 : 14),
                      ),
                    ),
            ),
          ),
          SizedBox(width: isVeryNarrow ? 8 : (isSmallScreen ? 10 : 12)),
          
          // User Avatar (placeholder) - responsive
          Container(
            width: isVeryNarrow ? 32 : (isSmallScreen ? 36 : 40),
            height: isVeryNarrow ? 32 : (isSmallScreen ? 36 : 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade400,
                  Colors.purple.shade400,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: isVeryNarrow ? 16 : (isSmallScreen ? 18 : 20),
            ),
          ),
          SizedBox(width: isVeryNarrow ? 8 : (isSmallScreen ? 10 : 12)),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User ${index + 1}', // Placeholder user name
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isVeryNarrow ? 13 : (isSmallScreen ? 14 : 16),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmallScreen ? 1 : 2),
                Text(
                  _getTypeDescription(type),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: isVeryNarrow ? 10 : (isSmallScreen ? 11 : 12),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Score/Value
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isVeryNarrow ? 8 : (isSmallScreen ? 10 : 12),
              vertical: isSmallScreen ? 4 : 6,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isTopThree 
                    ? [rankColors[index].withValues(alpha: 0.2), rankColors[index].withValues(alpha: 0.1)]
                    : [Colors.grey.shade300.withValues(alpha: 0.5), Colors.grey.shade200.withValues(alpha: 0.3)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${100 - (index * 5)}', // Placeholder score
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isTopThree ? rankColors[index] : Colors.grey.shade600,
                fontSize: isVeryNarrow ? 12 : (isSmallScreen ? 14 : 16),
              ),
            ),
          ),
        ],
      ),
    );
  }


  String _getTypeDescription(LeaderboardType type) {
    switch (type) {
      case LeaderboardType.productivity:
        return 'Productivity champion';
      case LeaderboardType.focusTime:
        return 'Focus time master';
      case LeaderboardType.tasks:
        return 'Task completion expert';
      case LeaderboardType.streaks:
        return 'Consistency star';
      case LeaderboardType.sessions:
        return 'Session warrior';
      case LeaderboardType.consistency:
        return 'Reliability king';
    }
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
  
  String _getLeaderboardTypeShortLabel(LeaderboardType type) {
    switch (type) {
      case LeaderboardType.productivity:
        return 'Prod';
      case LeaderboardType.focusTime:
        return 'Focus';
      case LeaderboardType.tasks:
        return 'Tasks';
      case LeaderboardType.streaks:
        return 'Streak';
      case LeaderboardType.sessions:
        return 'Sessions';
      case LeaderboardType.consistency:
        return 'Const';
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

