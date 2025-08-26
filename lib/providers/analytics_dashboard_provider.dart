import 'package:flutter/material.dart';
import '../models/analytics_data.dart';
import '../models/session_analytics.dart';
import '../models/user_goals.dart';
import '../services/analytics_firestore_service.dart';

class AnalyticsDashboardProvider with ChangeNotifier {
  DashboardData? _dashboardData;
  bool _isLoading = false;
  String? _error;

  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await AnalyticsFirestoreService.getDashboardData();
      
      _dashboardData = DashboardData(
        dailySessions: data['daily'] as List<SessionAnalytics>,
        weeklySessions: data['weekly'] as List<SessionAnalytics>,
        monthlySessions: data['monthly'] as List<SessionAnalytics>,
        goals: data['goals'] as UserGoals?,
        efficiency: data['efficiency'] as double,
        focusPatterns: data['focusPatterns'] as Map<int, int>,
        streak: data['streak'] as int,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateGoals(UserGoals goals) async {
    try {
      await AnalyticsFirestoreService.saveUserGoals(goals);
      if (_dashboardData != null) {
        _dashboardData = DashboardData(
          dailySessions: _dashboardData!.dailySessions,
          weeklySessions: _dashboardData!.weeklySessions,
          monthlySessions: _dashboardData!.monthlySessions,
          goals: goals,
          efficiency: _dashboardData!.efficiency,
          focusPatterns: _dashboardData!.focusPatterns,
          streak: _dashboardData!.streak,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> recordSession(SessionAnalytics session) async {
    try {
      await AnalyticsFirestoreService.createSession(session);
      // Reload dashboard data to reflect the new session
      await loadDashboardData();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}