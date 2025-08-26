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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomScrollView(
                  slivers: [
                    // Responsive Tab Bar - using SliverPersistentHeader for proper sizing
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: LeaderboardTabBarDelegate(
                        tabBar: _buildRankingTabBar(isDark, isSmallScreen, isNarrowScreen),
                        height: _calculateTabBarHeight(isSmallScreen, isNarrowScreen),
                      ),
                    ),
                    
                    // Content area with proper constraints
                    SliverFillRemaining(
                      child: TabBarView(
                        controller: _tabController,
                        children: LeaderboardType.values.map((type) {
                          return _buildEnhancedLeaderboardContent(leaderboardService, type);
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  double _calculateTabBarHeight(bool isSmallScreen, bool isNarrowScreen) {
    // Calculate height based on actual components:
    // - Container margin (top + bottom): 8 or 16px  
    // - Container padding (top + bottom): 4 or 8px
    // - Container border (top + bottom): 2px
    // - TabBar intrinsic height: ~48px (Material Design standard)
    // - Icon size: 12-16px + text height + internal padding
    
    final double marginVertical = isSmallScreen ? 8.0 : 16.0; // top + bottom margins
    final double paddingVertical = isSmallScreen ? 4.0 : 8.0; // top + bottom padding
    const double borderVertical = 2.0; // top + bottom borders
    final double tabBarHeight = isSmallScreen ? 44.0 : 48.0; // Estimated TabBar height
    
    final double totalHeight = marginVertical + paddingVertical + borderVertical + tabBarHeight;
    
    // Round up to ensure we have enough space and avoid fractional pixel issues
    return totalHeight.ceilToDouble();
  }
  
  Widget _buildRankingTabBar(bool isDark, bool isSmallScreen, bool isNarrowScreen) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, isSmallScreen ? 4 : 8, 16, isSmallScreen ? 4 : 8),
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
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade400,
              Colors.orange.shade500,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: isNarrowScreen ? 7 : (isSmallScreen ? 8 : 9),
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: isNarrowScreen ? 6 : (isSmallScreen ? 7 : 8),
        ),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: LeaderboardType.values.map((type) {
          return Tab(
            text: isNarrowScreen ? _getLeaderboardTypeShortLabel(type) : _getLeaderboardTypeLabel(type),
            icon: Icon(_getLeaderboardTypeIcon(type), size: isSmallScreen ? 12 : 16),
          );
        }).toList(),
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
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
    
    return Center(
      child: Container(
        margin: EdgeInsets.all(isSmallScreen ? 24 : 32),
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
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
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              'Complete focus sessions and climb the leaderboard!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedLeaderboardCard(dynamic entry, LeaderboardType type, int index, bool isSmallScreen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTopThree = index < 3;
    final rankColors = [
      Colors.amber.shade500, // 1st place - Gold
      Colors.grey.shade400,  // 2nd place - Silver  
      Colors.orange.shade600, // 3rd place - Bronze
    ];
    
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
            width: isSmallScreen ? 32 : 40,
            height: isSmallScreen ? 32 : 40,
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
                      size: isSmallScreen ? 16 : 20,
                    )
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          
          // User Avatar (placeholder) - responsive
          Container(
            width: isSmallScreen ? 36 : 48,
            height: isSmallScreen ? 36 : 48,
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
              size: isSmallScreen ? 18 : 24,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User ${index + 1}', // Placeholder user name
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  _getTypeDescription(type),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          
          // Score/Value
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

class LeaderboardTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget tabBar;
  final double height;

  LeaderboardTabBarDelegate({required this.tabBar, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Constrain the child to exactly match the reported height
    // This ensures layoutExtent equals paintExtent
    return SizedBox(
      height: maxExtent,
      child: ClipRect(
        child: OverflowBox(
          minHeight: maxExtent,
          maxHeight: maxExtent,
          child: tabBar,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(LeaderboardTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar || height != oldDelegate.height;
  }
}