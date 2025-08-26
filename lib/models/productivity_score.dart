import 'package:json_annotation/json_annotation.dart';

part 'productivity_score.g.dart';

@JsonSerializable()
class ProductivityScore {
  final String userId;
  final DateTime date;
  final double dailyScore;
  final double weeklyScore;
  final double monthlyScore;
  final ProductivityMetrics metrics;
  final Map<String, double> categoryScores;
  final int rank;
  final ScoreDetails details;

  ProductivityScore({
    required this.userId,
    required this.date,
    required this.dailyScore,
    required this.weeklyScore,
    required this.monthlyScore,
    required this.metrics,
    required this.categoryScores,
    this.rank = 0,
    required this.details,
  });

  factory ProductivityScore.fromJson(Map<String, dynamic> json) =>
      _$ProductivityScoreFromJson(json);

  Map<String, dynamic> toJson() => _$ProductivityScoreToJson(this);

  String get scoreGrade {
    if (dailyScore >= 90) return 'A+';
    if (dailyScore >= 80) return 'A';
    if (dailyScore >= 70) return 'B+';
    if (dailyScore >= 60) return 'B';
    if (dailyScore >= 50) return 'C+';
    if (dailyScore >= 40) return 'C';
    return 'D';
  }

  String get scoreDescription {
    if (dailyScore >= 90) return 'Outstanding Performance!';
    if (dailyScore >= 80) return 'Excellent Work!';
    if (dailyScore >= 70) return 'Good Progress!';
    if (dailyScore >= 60) return 'Making Progress';
    if (dailyScore >= 50) return 'Keep Going!';
    if (dailyScore >= 40) return 'Room for Improvement';
    return 'Let\'s Get Started!';
  }

  ProductivityTrend get trend {
    // This would be calculated based on historical data
    // For now, simplified logic
    if (dailyScore > weeklyScore) return ProductivityTrend.improving;
    if (dailyScore < weeklyScore) return ProductivityTrend.declining;
    return ProductivityTrend.stable;
  }
}

@JsonSerializable()
class ProductivityMetrics {
  final int totalSessions;
  final int completedSessions;
  final int totalFocusMinutes;
  final int tasksCompleted;
  final int perfectSessions;
  final double averageSessionLength;
  final double consistencyScore;
  final double efficiencyScore;
  final int streakDays;
  final int interruptionCount;

  ProductivityMetrics({
    required this.totalSessions,
    required this.completedSessions,
    required this.totalFocusMinutes,
    required this.tasksCompleted,
    required this.perfectSessions,
    required this.averageSessionLength,
    required this.consistencyScore,
    required this.efficiencyScore,
    required this.streakDays,
    required this.interruptionCount,
  });

  factory ProductivityMetrics.fromJson(Map<String, dynamic> json) =>
      _$ProductivityMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$ProductivityMetricsToJson(this);

  double get completionRate =>
      totalSessions > 0 ? (completedSessions / totalSessions) * 100 : 0;

  double get perfectSessionRate =>
      completedSessions > 0 ? (perfectSessions / completedSessions) * 100 : 0;
}

@JsonSerializable()
class ScoreDetails {
  final double baseScore;
  final double consistencyBonus;
  final double streakBonus;
  final double efficiencyBonus;
  final double taskCompletionBonus;
  final double perfectSessionBonus;
  final double penaltyReduction;
  final List<ScoreComponent> components;

  ScoreDetails({
    required this.baseScore,
    required this.consistencyBonus,
    required this.streakBonus,
    required this.efficiencyBonus,
    required this.taskCompletionBonus,
    required this.perfectSessionBonus,
    required this.penaltyReduction,
    required this.components,
  });

  factory ScoreDetails.fromJson(Map<String, dynamic> json) =>
      _$ScoreDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$ScoreDetailsToJson(this);
}

@JsonSerializable()
class ScoreComponent {
  final String name;
  final double value;
  final String description;
  final ComponentType type;

  ScoreComponent({
    required this.name,
    required this.value,
    required this.description,
    required this.type,
  });

  factory ScoreComponent.fromJson(Map<String, dynamic> json) =>
      _$ScoreComponentFromJson(json);

  Map<String, dynamic> toJson() => _$ScoreComponentToJson(this);
}

@JsonEnum()
enum ProductivityTrend { improving, declining, stable }

@JsonEnum()
enum ComponentType { base, bonus, penalty }

class ProductivityCalculator {
  static ProductivityScore calculateScore({
    required String userId,
    required DateTime date,
    required ProductivityMetrics metrics,
    required Map<String, double> categoryScores,
  }) {
    // Base score calculation (0-100)
    double baseScore = _calculateBaseScore(metrics);
    
    // Bonus calculations
    double consistencyBonus = _calculateConsistencyBonus(metrics);
    double streakBonus = _calculateStreakBonus(metrics.streakDays);
    double efficiencyBonus = _calculateEfficiencyBonus(metrics);
    double taskBonus = _calculateTaskCompletionBonus(metrics);
    double perfectBonus = _calculatePerfectSessionBonus(metrics);
    
    // Penalty calculation
    double penaltyReduction = _calculatePenalties(metrics);
    
    // Final score calculation
    double finalScore = (baseScore + consistencyBonus + streakBonus + 
                        efficiencyBonus + taskBonus + perfectBonus - penaltyReduction)
                        .clamp(0.0, 100.0);

    List<ScoreComponent> components = [
      ScoreComponent(
        name: 'Base Score',
        value: baseScore,
        description: 'Based on completed sessions',
        type: ComponentType.base,
      ),
      if (consistencyBonus > 0)
        ScoreComponent(
          name: 'Consistency Bonus',
          value: consistencyBonus,
          description: 'Regular daily usage',
          type: ComponentType.bonus,
        ),
      if (streakBonus > 0)
        ScoreComponent(
          name: 'Streak Bonus',
          value: streakBonus,
          description: '${metrics.streakDays}-day streak',
          type: ComponentType.bonus,
        ),
      if (efficiencyBonus > 0)
        ScoreComponent(
          name: 'Efficiency Bonus',
          value: efficiencyBonus,
          description: 'High completion rate',
          type: ComponentType.bonus,
        ),
      if (taskBonus > 0)
        ScoreComponent(
          name: 'Task Completion Bonus',
          value: taskBonus,
          description: 'Tasks completed during sessions',
          type: ComponentType.bonus,
        ),
      if (perfectBonus > 0)
        ScoreComponent(
          name: 'Perfect Session Bonus',
          value: perfectBonus,
          description: 'Uninterrupted sessions',
          type: ComponentType.bonus,
        ),
      if (penaltyReduction > 0)
        ScoreComponent(
          name: 'Interruption Penalty',
          value: -penaltyReduction,
          description: 'Frequent interruptions',
          type: ComponentType.penalty,
        ),
    ];

    ScoreDetails details = ScoreDetails(
      baseScore: baseScore,
      consistencyBonus: consistencyBonus,
      streakBonus: streakBonus,
      efficiencyBonus: efficiencyBonus,
      taskCompletionBonus: taskBonus,
      perfectSessionBonus: perfectBonus,
      penaltyReduction: penaltyReduction,
      components: components,
    );

    return ProductivityScore(
      userId: userId,
      date: date,
      dailyScore: finalScore,
      weeklyScore: finalScore, // Would be calculated from weekly data
      monthlyScore: finalScore, // Would be calculated from monthly data
      metrics: metrics,
      categoryScores: categoryScores,
      details: details,
    );
  }

  static double _calculateBaseScore(ProductivityMetrics metrics) {
    if (metrics.totalSessions == 0) return 0.0;
    
    // Base score from session completion (0-60 points)
    double completionScore = (metrics.completedSessions / metrics.totalSessions) * 60;
    
    // Time-based score (0-20 points)
    double timeScore = (metrics.totalFocusMinutes / 480.0).clamp(0.0, 1.0) * 20; // Max 8 hours
    
    // Average session length bonus (0-20 points)
    double lengthScore = (metrics.averageSessionLength / 25.0).clamp(0.0, 1.0) * 20;
    
    return completionScore + timeScore + lengthScore;
  }

  static double _calculateConsistencyBonus(ProductivityMetrics metrics) {
    return metrics.consistencyScore * 10; // Max 10 bonus points
  }

  static double _calculateStreakBonus(int streakDays) {
    if (streakDays < 3) return 0;
    if (streakDays < 7) return 5;
    if (streakDays < 14) return 10;
    if (streakDays < 30) return 15;
    return 20; // Max streak bonus
  }

  static double _calculateEfficiencyBonus(ProductivityMetrics metrics) {
    return metrics.efficiencyScore * 8; // Max 8 bonus points
  }

  static double _calculateTaskCompletionBonus(ProductivityMetrics metrics) {
    if (metrics.tasksCompleted == 0) return 0;
    // Bonus for completing tasks during sessions
    return (metrics.tasksCompleted / metrics.completedSessions.clamp(1, 50)) * 10;
  }

  static double _calculatePerfectSessionBonus(ProductivityMetrics metrics) {
    if (metrics.completedSessions == 0) return 0;
    double perfectRate = metrics.perfectSessions / metrics.completedSessions;
    return perfectRate * 12; // Max 12 bonus points
  }

  static double _calculatePenalties(ProductivityMetrics metrics) {
    if (metrics.completedSessions == 0) return 0;
    
    // Penalty for interruptions
    double interruptionRate = metrics.interruptionCount / metrics.totalSessions;
    return interruptionRate * 15; // Max 15 penalty points
  }
}