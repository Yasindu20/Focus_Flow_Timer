import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/leaderboard.dart';
import '../models/productivity_score.dart';
import 'optimized_storage_service.dart';
import 'achievement_service.dart';

class LeaderboardService extends ChangeNotifier {
  static final LeaderboardService _instance = LeaderboardService._internal();
  factory LeaderboardService() => _instance;
  LeaderboardService._internal() {
    _initializeFirestore();
  }

  void _initializeFirestore() {
    // Don't initialize Firestore during construction to avoid web errors
    _firestore = null;
  }

  FirebaseFirestore? get _safeFirestore {
    if (_firestore == null) {
      try {
        _firestore = FirebaseFirestore.instance;
      } catch (e) {
        debugPrint('Firestore initialization failed: $e');
        return null;
      }
    }
    return _firestore;
  }

  FirebaseFirestore? _firestore;
  final OptimizedStorageService _storage = OptimizedStorageService();

  final Map<LeaderboardType, Leaderboard> _leaderboards = {};
  LeaderboardEntry? _userEntry;
  bool _isInitialized = false;
  bool _isOnline = false;

  Map<LeaderboardType, Leaderboard> get leaderboards => _leaderboards;
  LeaderboardEntry? get userEntry => _userEntry;
  bool get isOnline => _isOnline;

  Leaderboard? getLeaderboard(LeaderboardType type) => _leaderboards[type];

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _checkConnectivity();
      await _loadLeaderboards();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Leaderboard service initialization error: $e');
      await _loadMockData(); // Fallback to mock data for development
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      // Simple connectivity check by trying to access Firestore
      final firestore = _safeFirestore;
      if (firestore == null) {
        _isOnline = false;
        return;
      }
      await firestore.collection('test').limit(1).get();
      _isOnline = true;
    } catch (e) {
      _isOnline = false;
      debugPrint('Offline mode: $e');
    }
  }

  Future<void> _loadLeaderboards() async {
    if (_isOnline) {
      await _loadFromFirestore();
    } else {
      await _loadFromLocal();
    }
  }

  Future<void> _loadFromFirestore() async {
    try {
      // Load all leaderboard types
      for (final type in LeaderboardType.values) {
        await _loadLeaderboardByType(type);
      }

      // Load user's position
      await _loadUserPosition();
    } catch (e) {
      debugPrint('Firestore leaderboard load error: $e');
      await _loadFromLocal();
    }
  }

  Future<void> _loadLeaderboardByType(LeaderboardType type) async {
    try {
      final firestore = _safeFirestore;
      if (firestore == null) return;
      
      final query = await firestore
          .collection('leaderboards')
          .doc(type.toString())
          .collection('entries')
          .orderBy(_getSortField(type), descending: true)
          .limit(100)
          .get();

      List<LeaderboardEntry> entries = query.docs.map((doc) {
        return LeaderboardEntry.fromJson({
          ...doc.data(),
          'userId': doc.id,
        });
      }).toList();

      // Calculate rankings
      entries = LeaderboardCalculator.calculateRankings(
        entries: entries,
        type: type,
      );

      _leaderboards[type] = Leaderboard(
        type: type,
        lastUpdated: DateTime.now(),
        entries: entries,
        period: LeaderboardPeriod.weekly, // Default to weekly
        userEntry: _findUserInEntries(entries),
        totalParticipants: entries.length,
      );
    } catch (e) {
      debugPrint('Error loading leaderboard $type: $e');
      await _loadMockLeaderboard(type);
    }
  }

  String _getSortField(LeaderboardType type) {
    switch (type) {
      case LeaderboardType.productivity:
        return 'score';
      case LeaderboardType.focusTime:
        return 'totalFocusMinutes';
      case LeaderboardType.streaks:
        return 'streakDays';
      case LeaderboardType.sessions:
        return 'sessionsCompleted';
      case LeaderboardType.tasks:
        return 'stats.tasksCompleted';
      case LeaderboardType.consistency:
        return 'stats.weeklyScore';
    }
  }

  LeaderboardEntry? _findUserInEntries(List<LeaderboardEntry> entries) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      return entries.firstWhere((entry) => entry.userId == user.uid);
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadUserPosition() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final firestore = _safeFirestore;
      if (firestore == null) return;
      
      final userDoc = await firestore
          .collection('leaderboard_users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        _userEntry = LeaderboardEntry.fromJson({
          ...userDoc.data()!,
          'userId': user.uid,
        });
      }
    } catch (e) {
      debugPrint('Error loading user position: $e');
    }
  }

  Future<void> _loadFromLocal() async {
    try {
      final savedData = await _storage.getLeaderboards();
      for (final entry in savedData.entries) {
        final type = LeaderboardType.values.firstWhere(
          (t) => t.toString() == entry.key,
        );
        _leaderboards[type] = Leaderboard.fromJson(entry.value);
      }

      final userData = await _storage.getUserLeaderboardEntry();
      if (userData != null) {
        _userEntry = LeaderboardEntry.fromJson(userData);
      }
    } catch (e) {
      debugPrint('Local leaderboard load error: $e');
      await _loadMockData();
    }
  }

  Future<void> _loadMockData() async {
    // Load mock data for development/offline use
    for (final type in LeaderboardType.values) {
      await _loadMockLeaderboard(type);
    }
  }

  Future<void> _loadMockLeaderboard(LeaderboardType type) async {
    final mockEntries = MockLeaderboardData.generateMockEntries(20);
    
    _leaderboards[type] = Leaderboard(
      type: type,
      lastUpdated: DateTime.now(),
      entries: mockEntries,
      period: LeaderboardPeriod.weekly,
      userEntry: mockEntries.isNotEmpty ? mockEntries.last : null,
      totalParticipants: mockEntries.length,
    );
  }

  Future<void> updateUserStats({
    required ProductivityScore productivityScore,
    required int totalFocusMinutes,
    required int sessionsCompleted,
    required int streakDays,
    required int tasksCompleted,
    List<String>? newAchievements,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get user's display name
      String displayName = user.displayName ?? 'Anonymous User';
      
      // Get achievements
      final achievementService = AchievementService();
      final achievements = achievementService.unlockedAchievements
          .map((a) => a.id)
          .toList();


      final leaderboardStats = LeaderboardStats(
        weeklyScore: productivityScore.weeklyScore,
        monthlyScore: productivityScore.monthlyScore,
        weeklyMinutes: productivityScore.metrics.totalFocusMinutes,
        monthlyMinutes: productivityScore.metrics.totalFocusMinutes * 4, // Estimate
        perfectSessions: productivityScore.metrics.perfectSessions,
        averageSessionLength: productivityScore.metrics.averageSessionLength,
        tasksCompleted: tasksCompleted,
        categoryBreakdown: productivityScore.categoryScores.map(
          (key, value) => MapEntry(key, value.round()),
        ),
      );

      final userEntry = LeaderboardEntry(
        userId: user.uid,
        displayName: displayName,
        avatar: user.photoURL,
        score: productivityScore.dailyScore,
        rank: 0, // Will be calculated when leaderboard updates
        totalFocusMinutes: totalFocusMinutes,
        sessionsCompleted: sessionsCompleted,
        streakDays: streakDays,
        lastActive: DateTime.now(),
        stats: leaderboardStats,
        achievements: achievements,
      );

      _userEntry = userEntry;

      // Save to storage
      await _saveUserStats(userEntry);

      // Upload to Firestore if online
      if (_isOnline) {
        await _uploadUserStats(userEntry);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user stats: $e');
    }
  }

  Future<void> _saveUserStats(LeaderboardEntry userEntry) async {
    try {
      await _storage.setUserLeaderboardEntry(userEntry.toJson());
    } catch (e) {
      debugPrint('Error saving user stats locally: $e');
    }
  }

  Future<void> _uploadUserStats(LeaderboardEntry userEntry) async {
    try {
      final firestore = _safeFirestore;
      if (firestore == null) return;
      
      final batch = firestore.batch();

      // Update user in main leaderboard collection
      final userRef = firestore
          .collection('leaderboard_users')
          .doc(userEntry.userId);
      batch.set(userRef, userEntry.toJson());

      // Update user in each leaderboard type collection
      for (final type in LeaderboardType.values) {
        final leaderboardRef = firestore
            .collection('leaderboards')
            .doc(type.toString())
            .collection('entries')
            .doc(userEntry.userId);
        batch.set(leaderboardRef, userEntry.toJson());
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error uploading user stats: $e');
    }
  }

  Future<void> refreshLeaderboards() async {
    await _checkConnectivity();
    await _loadLeaderboards();
    notifyListeners();
  }

  // Get user's rank in specific leaderboard
  int? getUserRank(LeaderboardType type) {
    final leaderboard = _leaderboards[type];
    if (leaderboard?.userEntry != null) {
      return leaderboard!.userEntry!.rank;
    }
    return null;
  }

  // Get users around current user's rank
  List<LeaderboardEntry> getNearbyUsers(LeaderboardType type, {int range = 5}) {
    final leaderboard = _leaderboards[type];
    if (leaderboard?.userEntry == null) return [];

    final userRank = leaderboard!.userEntry!.rank;
    final startIndex = (userRank - range - 1).clamp(0, leaderboard.entries.length);
    final endIndex = (userRank + range).clamp(0, leaderboard.entries.length);

    return leaderboard.entries.sublist(startIndex, endIndex);
  }

  // Get top performers
  List<LeaderboardEntry> getTopPerformers(LeaderboardType type, {int count = 10}) {
    final leaderboard = _leaderboards[type];
    if (leaderboard == null) return [];
    
    return leaderboard.entries.take(count).toList();
  }

  // Check if user improved rank
  bool hasImprovedRank(LeaderboardType type, int previousRank) {
    final currentRank = getUserRank(type);
    if (currentRank == null) return false;
    
    return currentRank < previousRank; // Lower rank number = better position
  }

  // Get leaderboard insights
  Map<String, dynamic> getLeaderboardInsights() {
    if (_userEntry == null) {
      return {
        'message': 'Complete some sessions to join the leaderboard!',
        'suggestions': ['Complete your first focus session', 'Set up your profile']
      };
    }

    List<String> insights = [];
    List<String> suggestions = [];

    // Overall performance
    final productivityRank = getUserRank(LeaderboardType.productivity);
    if (productivityRank != null) {
      if (productivityRank <= 10) {
        insights.add('You\'re in the top 10 for productivity! 🏆');
      } else if (productivityRank <= 50) {
        insights.add('You\'re doing well! Top 50 in productivity 📈');
      } else {
        suggestions.add('Focus on consistent daily sessions to climb the leaderboard');
      }
    }

    // Focus time comparison
    final focusRank = getUserRank(LeaderboardType.focusTime);
    final focusLeaderboard = _leaderboards[LeaderboardType.focusTime];
    if (focusRank != null && focusLeaderboard?.champion != null) {
      final championMinutes = focusLeaderboard!.champion!.totalFocusMinutes;
      final userMinutes = _userEntry!.totalFocusMinutes;
      final difference = championMinutes - userMinutes;
      
      if (difference > 0) {
        final hours = difference ~/ 60;
        insights.add('You\'re ${hours}h away from the focus time leader! 🎯');
      }
    }

    // Streak insights
    final streakRank = getUserRank(LeaderboardType.streaks);
    if (streakRank != null) {
      if (_userEntry!.streakDays >= 30) {
        insights.add('Incredible ${_userEntry!.streakDays}-day streak! 🔥');
      } else if (_userEntry!.streakDays >= 7) {
        insights.add('Great ${_userEntry!.streakDays}-day streak going! 📅');
        suggestions.add('Keep it up to reach the monthly milestone!');
      } else {
        suggestions.add('Build a daily habit to improve your streak ranking');
      }
    }

    return {
      'insights': insights,
      'suggestions': suggestions,
      'user_rank': productivityRank,
      'total_participants': _leaderboards[LeaderboardType.productivity]?.totalParticipants ?? 0,
      'is_top_performer': (productivityRank ?? 1000) <= 10,
    };
  }

  Future<void> resetUserStats() async {
    _userEntry = null;
    await _storage.clearUserLeaderboardEntry();
    notifyListeners();
  }

  // Simulate leaderboard updates for development
  Future<void> simulateLeaderboardUpdate() async {
    for (final type in LeaderboardType.values) {
      final mockEntries = MockLeaderboardData.generateMockEntries(25);
      
      // Add some randomness to scores
      final random = Random();
      for (int i = 0; i < mockEntries.length; i++) {
        final variance = random.nextDouble() * 10 - 5; // -5 to +5 points
        mockEntries[i] = LeaderboardEntry(
          userId: mockEntries[i].userId,
          displayName: mockEntries[i].displayName,
          avatar: mockEntries[i].avatar,
          score: (mockEntries[i].score + variance).clamp(0.0, 100.0),
          rank: mockEntries[i].rank,
          totalFocusMinutes: mockEntries[i].totalFocusMinutes + random.nextInt(120),
          sessionsCompleted: mockEntries[i].sessionsCompleted + random.nextInt(5),
          streakDays: mockEntries[i].streakDays + random.nextInt(3),
          lastActive: DateTime.now(),
          stats: mockEntries[i].stats,
          achievements: mockEntries[i].achievements,
        );
      }

      // Recalculate rankings
      final updatedEntries = LeaderboardCalculator.calculateRankings(
        entries: mockEntries,
        type: type,
      );

      _leaderboards[type] = Leaderboard(
        type: type,
        lastUpdated: DateTime.now(),
        entries: updatedEntries,
        period: LeaderboardPeriod.weekly,
        userEntry: _findUserInEntries(updatedEntries),
        totalParticipants: updatedEntries.length,
      );
    }

    notifyListeners();
  }
}