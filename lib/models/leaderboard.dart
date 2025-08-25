import 'package:json_annotation/json_annotation.dart';

part 'leaderboard.g.dart';

@JsonSerializable()
class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String? avatar;
  final double score;
  final int rank;
  final int totalFocusMinutes;
  final int sessionsCompleted;
  final int streakDays;
  final DateTime lastActive;
  final LeaderboardStats stats;
  final List<String> achievements;

  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.avatar,
    required this.score,
    required this.rank,
    required this.totalFocusMinutes,
    required this.sessionsCompleted,
    required this.streakDays,
    required this.lastActive,
    required this.stats,
    this.achievements = const [],
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryFromJson(json);

  Map<String, dynamic> toJson() => _$LeaderboardEntryToJson(this);

  String get formattedFocusTime {
    int hours = totalFocusMinutes ~/ 60;
    int minutes = totalFocusMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get rankSuffix {
    if (rank == 1) return 'st';
    if (rank == 2) return 'nd';
    if (rank == 3) return 'rd';
    return 'th';
  }

  String get rankDisplay => '$rank$rankSuffix';

  bool get isTopPerformer => rank <= 10;
  bool get isPodiumFinisher => rank <= 3;
}

@JsonSerializable()
class LeaderboardStats {
  final double weeklyScore;
  final double monthlyScore;
  final int weeklyMinutes;
  final int monthlyMinutes;
  final int perfectSessions;
  final double averageSessionLength;
  final int tasksCompleted;
  final Map<String, int> categoryBreakdown;

  LeaderboardStats({
    required this.weeklyScore,
    required this.monthlyScore,
    required this.weeklyMinutes,
    required this.monthlyMinutes,
    required this.perfectSessions,
    required this.averageSessionLength,
    required this.tasksCompleted,
    this.categoryBreakdown = const {},
  });

  factory LeaderboardStats.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardStatsFromJson(json);

  Map<String, dynamic> toJson() => _$LeaderboardStatsToJson(this);
}

@JsonSerializable()
class Leaderboard {
  final LeaderboardType type;
  final DateTime lastUpdated;
  final List<LeaderboardEntry> entries;
  final LeaderboardPeriod period;
  final LeaderboardEntry? userEntry;
  final int totalParticipants;

  Leaderboard({
    required this.type,
    required this.lastUpdated,
    required this.entries,
    required this.period,
    this.userEntry,
    required this.totalParticipants,
  });

  factory Leaderboard.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardFromJson(json);

  Map<String, dynamic> toJson() => _$LeaderboardToJson(this);

  List<LeaderboardEntry> get topTen => entries.take(10).toList();
  LeaderboardEntry? get champion => entries.isNotEmpty ? entries.first : null;
}

@JsonEnum()
enum LeaderboardType {
  productivity,
  focusTime,
  streaks,
  sessions,
  tasks,
  consistency,
}

@JsonEnum()
enum LeaderboardPeriod {
  daily,
  weekly,
  monthly,
  allTime,
}

class LeaderboardConfig {
  static Map<LeaderboardType, String> get typeNames => {
        LeaderboardType.productivity: 'Productivity Score',
        LeaderboardType.focusTime: 'Focus Time',
        LeaderboardType.streaks: 'Longest Streaks',
        LeaderboardType.sessions: 'Sessions Completed',
        LeaderboardType.tasks: 'Tasks Completed',
        LeaderboardType.consistency: 'Consistency Score',
      };

  static Map<LeaderboardType, String> get typeDescriptions => {
        LeaderboardType.productivity: 'Based on overall productivity score',
        LeaderboardType.focusTime: 'Total minutes of focused work',
        LeaderboardType.streaks: 'Consecutive days of activity',
        LeaderboardType.sessions: 'Number of completed sessions',
        LeaderboardType.tasks: 'Number of tasks completed',
        LeaderboardType.consistency: 'Regular usage patterns',
      };

  static Map<LeaderboardType, String> get typeIcons => {
        LeaderboardType.productivity: '🏆',
        LeaderboardType.focusTime: '⏱️',
        LeaderboardType.streaks: '🔥',
        LeaderboardType.sessions: '🎯',
        LeaderboardType.tasks: '✅',
        LeaderboardType.consistency: '📊',
      };

  static Map<LeaderboardPeriod, String> get periodNames => {
        LeaderboardPeriod.daily: 'Today',
        LeaderboardPeriod.weekly: 'This Week',
        LeaderboardPeriod.monthly: 'This Month',
        LeaderboardPeriod.allTime: 'All Time',
      };
}

class LeaderboardCalculator {
  static List<LeaderboardEntry> calculateRankings({
    required List<LeaderboardEntry> entries,
    required LeaderboardType type,
  }) {
    // Sort entries based on leaderboard type
    entries.sort((a, b) {
      switch (type) {
        case LeaderboardType.productivity:
          return b.score.compareTo(a.score);
        case LeaderboardType.focusTime:
          return b.totalFocusMinutes.compareTo(a.totalFocusMinutes);
        case LeaderboardType.streaks:
          return b.streakDays.compareTo(a.streakDays);
        case LeaderboardType.sessions:
          return b.sessionsCompleted.compareTo(a.sessionsCompleted);
        case LeaderboardType.tasks:
          return b.stats.tasksCompleted.compareTo(a.stats.tasksCompleted);
        case LeaderboardType.consistency:
          return b.stats.weeklyScore.compareTo(a.stats.weeklyScore);
      }
    });

    // Assign ranks
    for (int i = 0; i < entries.length; i++) {
      entries[i] = LeaderboardEntry(
        userId: entries[i].userId,
        displayName: entries[i].displayName,
        avatar: entries[i].avatar,
        score: entries[i].score,
        rank: i + 1,
        totalFocusMinutes: entries[i].totalFocusMinutes,
        sessionsCompleted: entries[i].sessionsCompleted,
        streakDays: entries[i].streakDays,
        lastActive: entries[i].lastActive,
        stats: entries[i].stats,
        achievements: entries[i].achievements,
      );
    }

    return entries;
  }

  static double calculateConsistencyScore({
    required int weeklyMinutes,
    required int sessionsCompleted,
    required int daysActive,
  }) {
    if (daysActive == 0) return 0.0;

    // Base consistency (0-70 points)
    double dailyAverage = weeklyMinutes / 7.0;
    double dailyConsistency = (dailyAverage / 60.0).clamp(0.0, 1.0) * 70;

    // Session distribution bonus (0-20 points)
    double sessionConsistency = (sessionsCompleted / 7.0).clamp(0.0, 1.0) * 20;

    // Days active bonus (0-10 points)
    double activeDaysBonus = (daysActive / 7.0) * 10;

    return dailyConsistency + sessionConsistency + activeDaysBonus;
  }
}

class MockLeaderboardData {
  static List<LeaderboardEntry> generateMockEntries(int count) {
    final names = [
      'Alex Thompson', 'Sarah Johnson', 'Mike Chen', 'Emma Davis',
      'James Wilson', 'Lisa Garcia', 'David Miller', 'Anna Brown',
      'Chris Taylor', 'Jessica Lee', 'Ryan Martinez', 'Sophie Clark',
      'Daniel Rodriguez', 'Olivia Anderson', 'Matthew White', 'Isabella Thomas',
      'Andrew Jackson', 'Mia Harris', 'Joshua Martin', 'Charlotte Moore'
    ];

    List<LeaderboardEntry> entries = [];
    
    for (int i = 0; i < count && i < names.length; i++) {
      entries.add(LeaderboardEntry(
        userId: 'user_${i + 1}',
        displayName: names[i],
        score: (95 - (i * 2.5) + (i % 3 == 0 ? 5 : 0)).clamp(0.0, 100.0),
        rank: i + 1,
        totalFocusMinutes: (2400 - (i * 120) + (i % 2 == 0 ? 200 : 0)).clamp(0, 10000),
        sessionsCompleted: (150 - (i * 8) + (i % 4 == 0 ? 20 : 0)).clamp(0, 1000),
        streakDays: (45 - (i * 2) + (i % 5 == 0 ? 10 : 0)).clamp(0, 365),
        lastActive: DateTime.now().subtract(Duration(hours: i % 24)),
        stats: LeaderboardStats(
          weeklyScore: (90 - (i * 1.5)).clamp(0.0, 100.0),
          monthlyScore: (85 - (i * 1.2)).clamp(0.0, 100.0),
          weeklyMinutes: (840 - (i * 35)).clamp(0, 3000),
          monthlyMinutes: (3600 - (i * 150)).clamp(0, 15000),
          perfectSessions: (25 - i).clamp(0, 100),
          averageSessionLength: (25.0 - (i * 0.5)).clamp(5.0, 60.0),
          tasksCompleted: (80 - (i * 3)).clamp(0, 500),
          categoryBreakdown: {
            'Work': (40 - (i * 2)).clamp(0, 100),
            'Study': (35 - (i * 1)).clamp(0, 100),
            'Personal': (20 - i).clamp(0, 100),
          },
        ),
        achievements: _generateMockAchievements(i),
      ));
    }

    return entries;
  }

  static List<String> _generateMockAchievements(int index) {
    List<String> allAchievements = [
      'first_session', 'session_10', 'session_50', 'focus_1hour',
      'streak_3', 'streak_7', 'tasks_10', 'perfect_5', 'early_bird'
    ];
    
    int achievementCount = (9 - (index ~/ 3)).clamp(1, allAchievements.length);
    return allAchievements.take(achievementCount).toList();
  }
}