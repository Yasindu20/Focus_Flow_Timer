import 'package:hive/hive.dart';
import 'enhanced_task.dart';

part 'task_analytics.g.dart';

// Enums for analytics
@HiveType(typeId: 50)
enum ProductivityTrendDirection {
  @HiveField(0)
  increasing,
  @HiveField(1)
  decreasing,
  @HiveField(2)
  stable,
}

@HiveType(typeId: 51)
enum RecommendationType {
  @HiveField(0)
  focusTime,
  @HiveField(1)
  estimation,
  @HiveField(2)
  scheduling,
  @HiveField(3)
  breaks,
  @HiveField(4)
  taskSize,
}

@HiveType(typeId: 52)
enum RecommendationImpact {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
}

@HiveType(typeId: 53)
enum RecommendationEffort {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
}

@HiveType(typeId: 54)
enum ComparisonType {
  @HiveField(0)
  timeOfDay,
  @HiveField(1)
  dayOfWeek,
  @HiveField(2)
  taskCategory,
  @HiveField(3)
  teamAverage,
  @HiveField(4)
  historical,
}

@HiveType(typeId: 55)
enum PatternType {
  @HiveField(0)
  time,
  @HiveField(1)
  category,
  @HiveField(2)
  duration,
  @HiveField(3)
  estimation,
}

// Main Analytics Classes
@HiveType(typeId: 56)
class TaskCompletionData extends HiveObject {
  @HiveField(0)
  String taskId;
  @HiveField(1)
  String userId;
  @HiveField(2)
  String title;
  @HiveField(3)
  String description;
  @HiveField(4)
  TaskCategory category;
  @HiveField(5)
  TaskPriority priority;
  @HiveField(6)
  Duration estimatedDuration;
  @HiveField(7)
  Duration timeSpent;
  @HiveField(8)
  DateTime startTime;
  @HiveField(9)
  DateTime completedAt;
  @HiveField(10)
  bool completed;
  @HiveField(11)
  double difficultyRating;
  @HiveField(12)
  int? interruptions;
  @HiveField(13)
  double complexityScore;
  @HiveField(14)
  Map<String, dynamic> context;

  TaskCompletionData({
    required this.taskId,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.estimatedDuration,
    required this.timeSpent,
    required this.startTime,
    required this.completedAt,
    required this.completed,
    required this.difficultyRating,
    this.interruptions,
    required this.complexityScore,
    Map<String, dynamic>? context,
  }) : context = context ?? {};

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'userId': userId,
        'title': title,
        'description': description,
        'category': category.name,
        'priority': priority.name,
        'estimatedDuration': estimatedDuration.inMilliseconds,
        'timeSpent': timeSpent.inMilliseconds,
        'startTime': startTime.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'completed': completed,
        'difficultyRating': difficultyRating,
        'interruptions': interruptions,
        'complexityScore': complexityScore,
        'context': context,
      };

  factory TaskCompletionData.fromJson(Map<String, dynamic> json) {
    return TaskCompletionData(
      taskId: json['taskId'],
      userId: json['userId'],
      title: json['title'],
      description: json['description'],
      category:
          TaskCategory.values.firstWhere((c) => c.name == json['category']),
      priority:
          TaskPriority.values.firstWhere((p) => p.name == json['priority']),
      estimatedDuration: Duration(milliseconds: json['estimatedDuration']),
      timeSpent: Duration(milliseconds: json['timeSpent']),
      startTime: DateTime.parse(json['startTime']),
      completedAt: DateTime.parse(json['completedAt']),
      completed: json['completed'],
      difficultyRating: json['difficultyRating']?.toDouble() ?? 0.0,
      interruptions: json['interruptions'],
      complexityScore: json['complexityScore']?.toDouble() ?? 0.0,
      context: Map<String, dynamic>.from(json['context'] ?? {}),
    );
  }
}

@HiveType(typeId: 57)
class UserAnalytics extends HiveObject {
  @HiveField(0)
  String userId;
  @HiveField(1)
  int totalTasksCompleted;
  @HiveField(2)
  Duration totalTimeSpent;
  @HiveField(3)
  Duration averageSessionLength;
  @HiveField(4)
  double productivityScore;
  @HiveField(5)
  double focusScore;
  @HiveField(6)
  double estimationAccuracy;
  @HiveField(7)
  List<int> preferredWorkingHours;
  @HiveField(8)
  int mostProductiveDay;
  @HiveField(9)
  Map<TaskCategory, CategoryPerformance> categoryPerformance;
  @HiveField(10)
  ProductivityTrendDirection recentTrend;
  @HiveField(11)
  DateTime lastUpdated;

  UserAnalytics({
    required this.userId,
    required this.totalTasksCompleted,
    required this.totalTimeSpent,
    required this.averageSessionLength,
    required this.productivityScore,
    required this.focusScore,
    required this.estimationAccuracy,
    required this.preferredWorkingHours,
    required this.mostProductiveDay,
    required this.categoryPerformance,
    required this.recentTrend,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'totalTasksCompleted': totalTasksCompleted,
        'totalTimeSpent': totalTimeSpent.inMilliseconds,
        'averageSessionLength': averageSessionLength.inMilliseconds,
        'productivityScore': productivityScore,
        'focusScore': focusScore,
        'estimationAccuracy': estimationAccuracy,
        'preferredWorkingHours': preferredWorkingHours,
        'mostProductiveDay': mostProductiveDay,
        'categoryPerformance': categoryPerformance.map(
          (k, v) => MapEntry(k.name, {
            'category': v.category.name,
            'totalTasks': v.totalTasks,
            'completedTasks': v.completedTasks,
            'averageTime': v.averageTime.inMilliseconds,
            'estimationAccuracy': v.estimationAccuracy,
            'productivityScore': v.productivityScore,
          }),
        ),
        'recentTrend': recentTrend.name,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory UserAnalytics.fromJson(Map<String, dynamic> json) {
    return UserAnalytics(
      userId: json['userId'],
      totalTasksCompleted: json['totalTasksCompleted'],
      totalTimeSpent: Duration(milliseconds: json['totalTimeSpent']),
      averageSessionLength: Duration(milliseconds: json['averageSessionLength']),
      productivityScore: json['productivityScore']?.toDouble() ?? 0.0,
      focusScore: json['focusScore']?.toDouble() ?? 0.0,
      estimationAccuracy: json['estimationAccuracy']?.toDouble() ?? 0.0,
      preferredWorkingHours: List<int>.from(json['preferredWorkingHours'] ?? []),
      mostProductiveDay: json['mostProductiveDay'] ?? 1,
      categoryPerformance: (json['categoryPerformance'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(
          TaskCategory.values.firstWhere((c) => c.name == k),
          CategoryPerformance(
            category: TaskCategory.values.firstWhere((c) => c.name == v['category']),
            totalTasks: v['totalTasks'],
            completedTasks: v['completedTasks'],
            averageTime: Duration(milliseconds: v['averageTime']),
            estimationAccuracy: v['estimationAccuracy']?.toDouble() ?? 0.0,
            productivityScore: v['productivityScore']?.toDouble() ?? 0.0,
          ),
        ),
      ),
      recentTrend: ProductivityTrendDirection.values.firstWhere(
        (t) => t.name == json['recentTrend'],
        orElse: () => ProductivityTrendDirection.stable,
      ),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  factory UserAnalytics.empty(String userId) {
    return UserAnalytics(
      userId: userId,
      totalTasksCompleted: 0,
      totalTimeSpent: Duration.zero,
      averageSessionLength: Duration.zero,
      productivityScore: 0.0,
      focusScore: 0.0,
      estimationAccuracy: 0.0,
      preferredWorkingHours: [],
      mostProductiveDay: 1,
      categoryPerformance: {},
      recentTrend: ProductivityTrendDirection.stable,
      lastUpdated: DateTime.now(),
    );
  }
}

@HiveType(typeId: 58)
class CategoryPerformance extends HiveObject {
  @HiveField(0)
  TaskCategory category;
  @HiveField(1)
  int totalTasks;
  @HiveField(2)
  int completedTasks;
  @HiveField(3)
  Duration averageTime;
  @HiveField(4)
  double estimationAccuracy;
  @HiveField(5)
  double productivityScore;

  CategoryPerformance({
    required this.category,
    required this.totalTasks,
    required this.completedTasks,
    required this.averageTime,
    required this.estimationAccuracy,
    required this.productivityScore,
  });
}

@HiveType(typeId: 59)
class ProductivityRecommendation extends HiveObject {
  @HiveField(0)
  RecommendationType type;
  @HiveField(1)
  String title;
  @HiveField(2)
  String description;
  @HiveField(3)
  RecommendationImpact impact;
  @HiveField(4)
  RecommendationEffort effort;

  ProductivityRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.impact,
    required this.effort,
  });
}

@HiveType(typeId: 60)
class ProductivityPattern extends HiveObject {
  @HiveField(0)
  PatternType type;
  @HiveField(1)
  String description;
  @HiveField(2)
  double strength;
  @HiveField(3)
  double confidence;
  @HiveField(4)
  Map<String, dynamic> data;

  ProductivityPattern({
    required this.type,
    required this.description,
    required this.strength,
    required this.confidence,
    Map<String, dynamic>? data,
  }) : data = data ?? {};

  factory ProductivityPattern.empty() {
    return ProductivityPattern(
      type: PatternType.time,
      description: 'No pattern detected',
      strength: 0.0,
      confidence: 0.0,
    );
  }
}

// Additional classes for analytics
class ProductivityMetrics {
  final int totalTasks;
  final int completedTasks;
  final Duration totalTimeSpent;
  final Duration averageTimePerTask;
  final double tasksPerDay;
  final Duration focusTime;
  final Duration breakTime;
  final double productivityScore;

  ProductivityMetrics({
    required this.totalTasks,
    required this.completedTasks,
    required this.totalTimeSpent,
    required this.averageTimePerTask,
    required this.tasksPerDay,
    required this.focusTime,
    required this.breakTime,
    required this.productivityScore,
  });
}

class ProductivityInsights {
  final String userId;
  final DateRange period;
  final ProductivityMetrics metrics;
  final List<ProductivityPattern> patterns;
  final List<ProductivityRecommendation> recommendations;
  final TimeDistribution timeDistribution;
  final EfficiencyScores efficiency;
  final DateTime lastUpdated;

  ProductivityInsights({
    required this.userId,
    required this.period,
    required this.metrics,
    required this.patterns,
    required this.recommendations,
    required this.timeDistribution,
    required this.efficiency,
    required this.lastUpdated,
  });

  factory ProductivityInsights.empty() {
    return ProductivityInsights(
      userId: '',
      period: DateRange(DateTime.now(), DateTime.now()),
      metrics: ProductivityMetrics(
        totalTasks: 0,
        completedTasks: 0,
        totalTimeSpent: Duration.zero,
        averageTimePerTask: Duration.zero,
        tasksPerDay: 0.0,
        focusTime: Duration.zero,
        breakTime: Duration.zero,
        productivityScore: 0.0,
      ),
      patterns: [],
      recommendations: [],
      timeDistribution: TimeDistribution.empty(),
      efficiency: EfficiencyScores.empty(),
      lastUpdated: DateTime.now(),
    );
  }
}

class TimeDistribution {
  final Map<TaskCategory, Duration> byCategory;
  final Map<int, Duration> byHour;
  final Map<int, Duration> byDay;

  TimeDistribution({
    required this.byCategory,
    required this.byHour,
    required this.byDay,
  });

  factory TimeDistribution.empty() {
    return TimeDistribution(
      byCategory: {},
      byHour: {},
      byDay: {},
    );
  }
}

class EfficiencyScores {
  final double overall;
  final double estimation;
  final double focus;
  final double consistency;
  final double timeManagement;

  EfficiencyScores({
    required this.overall,
    required this.estimation,
    required this.focus,
    required this.consistency,
    required this.timeManagement,
  });

  factory EfficiencyScores.empty() {
    return EfficiencyScores(
      overall: 0.0,
      estimation: 0.0,
      focus: 0.0,
      consistency: 0.0,
      timeManagement: 0.0,
    );
  }
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);
}

// Additional helper classes
class EstimationAccuracy {
  final double accuracy;
  final Duration averageError;
  final double overestimationRate;
  final double underestimationRate;

  EstimationAccuracy({
    required this.accuracy,
    required this.averageError,
    required this.overestimationRate,
    required this.underestimationRate,
  });
}

class TaskEfficiencyAnalysis {
  final String userId;
  final TaskCategory? category;
  final int? period;
  final EstimationAccuracy estimationAccuracy;
  final InterruptionAnalysis interruptionAnalysis;
  final FocusScoreBreakdown focusScores;
  final List<PerformanceBottleneck> bottlenecks;
  final List<OptimizationOpportunity> optimizations;
  final int tasksAnalyzed;

  TaskEfficiencyAnalysis({
    required this.userId,
    this.category,
    this.period,
    required this.estimationAccuracy,
    required this.interruptionAnalysis,
    required this.focusScores,
    required this.bottlenecks,
    required this.optimizations,
    required this.tasksAnalyzed,
  });

  factory TaskEfficiencyAnalysis.empty() {
    return TaskEfficiencyAnalysis(
      userId: '',
      estimationAccuracy: EstimationAccuracy(
        accuracy: 0.0,
        averageError: Duration.zero,
        overestimationRate: 0.0,
        underestimationRate: 0.0,
      ),
      interruptionAnalysis: InterruptionAnalysis.empty(),
      focusScores: FocusScoreBreakdown.empty(),
      bottlenecks: [],
      optimizations: [],
      tasksAnalyzed: 0,
    );
  }
}

class InterruptionAnalysis {
  final double averageInterruptions;
  final int totalInterruptions;
  final double interruptionRate;
  final TaskCategory mostInterruptedCategory;
  final List<InterruptionPattern> patterns;

  InterruptionAnalysis({
    required this.averageInterruptions,
    required this.totalInterruptions,
    required this.interruptionRate,
    required this.mostInterruptedCategory,
    required this.patterns,
  });

  factory InterruptionAnalysis.empty() {
    return InterruptionAnalysis(
      averageInterruptions: 0.0,
      totalInterruptions: 0,
      interruptionRate: 0.0,
      mostInterruptedCategory: TaskCategory.general,
      patterns: [],
    );
  }
}

class InterruptionPattern {
  final String type;
  final double frequency;
  final String description;

  InterruptionPattern({
    required this.type,
    required this.frequency,
    required this.description,
  });
}

class FocusScoreBreakdown {
  final double overall;
  final Map<TaskCategory, double> byCategory;
  final Map<int, double> byTimeOfDay;
  final FocusTrend trend;

  FocusScoreBreakdown({
    required this.overall,
    required this.byCategory,
    required this.byTimeOfDay,
    required this.trend,
  });

  factory FocusScoreBreakdown.empty() {
    return FocusScoreBreakdown(
      overall: 0.0,
      byCategory: {},
      byTimeOfDay: {},
      trend: FocusTrend.stable,
    );
  }
}

enum FocusTrend { improving, declining, stable }

enum BottleneckType { estimation, focus, interruption, consistency }

enum BottleneckSeverity { low, medium, high, critical }

class PerformanceBottleneck {
  final BottleneckType type;
  final BottleneckSeverity severity;
  final String description;
  final String impact;
  final List<String> suggestedActions;

  PerformanceBottleneck({
    required this.type,
    required this.severity,
    required this.description,
    required this.impact,
    required this.suggestedActions,
  });
}

enum OptimizationType { timeEstimation, focus, scheduling, breaks }

enum OpportunityImpact { low, medium, high }

class OptimizationOpportunity {
  final OptimizationType type;
  final TaskCategory? category;
  final OpportunityImpact impact;
  final String description;
  final Duration potentialTimeSaving;

  OptimizationOpportunity({
    required this.type,
    this.category,
    required this.impact,
    required this.description,
    required this.potentialTimeSaving,
  });
}

class ComparativeAnalytics {
  final String userId;
  final ComparisonType type;
  final Map<String, dynamic> comparison;
  final List<String> insights;
  final DateTime generatedAt;

  ComparativeAnalytics({
    required this.userId,
    required this.type,
    required this.comparison,
    required this.insights,
    required this.generatedAt,
  });

  factory ComparativeAnalytics.empty() {
    return ComparativeAnalytics(
      userId: '',
      type: ComparisonType.timeOfDay,
      comparison: {},
      insights: [],
      generatedAt: DateTime.now(),
    );
  }
}

class PredictiveAnalytics {
  final String userId;
  final int forecastDays;
  final List<ProductivityForecast> productivityForecast;
  final List<OptimalWorkTime> optimalWorkTimes;
  final BurnoutRisk burnoutRisk;
  final List<TaskCompletionPrediction> completionPredictions;
  final double confidence;
  final DateTime generatedAt;

  PredictiveAnalytics({
    required this.userId,
    required this.forecastDays,
    required this.productivityForecast,
    required this.optimalWorkTimes,
    required this.burnoutRisk,
    required this.completionPredictions,
    required this.confidence,
    required this.generatedAt,
  });

  factory PredictiveAnalytics.empty() {
    return PredictiveAnalytics(
      userId: '',
      forecastDays: 0,
      productivityForecast: [],
      optimalWorkTimes: [],
      burnoutRisk: BurnoutRisk.low,
      completionPredictions: [],
      confidence: 0.0,
      generatedAt: DateTime.now(),
    );
  }
}

class ProductivityForecast {
  final DateTime date;
  final double predictedScore;
  final double confidence;

  ProductivityForecast({
    required this.date,
    required this.predictedScore,
    required this.confidence,
  });
}

class OptimalWorkTime {
  final int hour;
  final double efficiency;
  final String reason;

  OptimalWorkTime({
    required this.hour,
    required this.efficiency,
    required this.reason,
  });
}

enum BurnoutRisk { low, medium, high, critical }

class TaskCompletionPrediction {
  final String taskId;
  final double completionProbability;
  final DateTime predictedCompletionDate;

  TaskCompletionPrediction({
    required this.taskId,
    required this.completionProbability,
    required this.predictedCompletionDate,
  });
}

class ProductivityTrend {
  final String userId;
  final List<TrendPoint> daily;
  final List<TrendPoint> weekly;
  final List<TrendPoint> monthly;
  final List<TrendPoint> quarterly;
  final DateTime lastUpdated;

  ProductivityTrend({
    required this.userId,
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.quarterly,
    required this.lastUpdated,
  });
}

class TrendPoint {
  final DateTime date;
  final double value;

  TrendPoint({
    required this.date,
    required this.value,
  });
}
