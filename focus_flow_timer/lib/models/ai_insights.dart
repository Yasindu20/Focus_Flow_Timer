import 'task_analytics.dart';
import 'enhanced_task.dart' show TaskCategory, TaskPriority;

class AIInsights {
  final String userId;
  final DateTime analysisDate;
  final double productivityScore;
  final ProductivityTrendDirection productivityTrend;
  final List<String> strengths;
  final List<String> improvementAreas;
  final List<ProductivityRecommendation> recommendations;
  final List<OptimizationOpportunity> optimizationOpportunities;
  final PredictiveAnalytics futurePredictions;
  final List<String> personalizedTips;

  AIInsights({
    required this.userId,
    required this.analysisDate,
    required this.productivityScore,
    required this.productivityTrend,
    required this.strengths,
    required this.improvementAreas,
    required this.recommendations,
    required this.optimizationOpportunities,
    required this.futurePredictions,
    required this.personalizedTips,
  });

  factory AIInsights.empty(String userId) {
    return AIInsights(
      userId: userId,
      analysisDate: DateTime.now(),
      productivityScore: 0.0,
      productivityTrend: ProductivityTrendDirection.stable,
      strengths: [],
      improvementAreas: [],
      recommendations: [],
      optimizationOpportunities: [],
      futurePredictions: PredictiveAnalytics.empty(),
      personalizedTips: [],
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'analysisDate': analysisDate.toIso8601String(),
        'productivityScore': productivityScore,
        'productivityTrend': productivityTrend.name,
        'strengths': strengths,
        'improvementAreas': improvementAreas,
        'personalizedTips': personalizedTips,
      };
}

class TaskScheduleRecommendation {
  final List<ScheduledTask> recommendedSchedule;
  final double confidenceScore;
  final List<ScheduledTask> alternativeOptions;
  final List<String> optimizationTips;
  final List<String> riskFactors;

  TaskScheduleRecommendation({
    required this.recommendedSchedule,
    required this.confidenceScore,
    required this.alternativeOptions,
    required this.optimizationTips,
    required this.riskFactors,
  });
}

class ScheduledTask {
  final String taskId;
  final DateTime startTime;
  final DateTime endTime;
  final double confidence;

  ScheduledTask({
    required this.taskId,
    required this.startTime,
    required this.endTime,
    required this.confidence,
  });
}

class TaskCategorizationResult {
  final TaskCategory suggestedCategory;
  final double categoryConfidence;
  final TaskPriority suggestedPriority;
  final String priorityReasoning;
  final List<String> smartTags;
  final List<String> suggestedSubtasks;
  final List<String> relatedTaskIds;

  TaskCategorizationResult({
    required this.suggestedCategory,
    required this.categoryConfidence,
    required this.suggestedPriority,
    required this.priorityReasoning,
    required this.smartTags,
    required this.suggestedSubtasks,
    required this.relatedTaskIds,
  });
}

class TaskEstimation {
  final int estimatedMinutes;
  final double confidenceLevel;
  final double complexityScore;
  final Map<String, double> factorBreakdown;
  final List<TaskSubtask> suggestedBreakdown;
  final List<EstimateAlternative> alternativeEstimates;
  final List<String> tips;

  TaskEstimation({
    required this.estimatedMinutes,
    required this.confidenceLevel,
    required this.complexityScore,
    required this.factorBreakdown,
    required this.suggestedBreakdown,
    required this.alternativeEstimates,
    required this.tips,
  });
}

class TaskSubtask {
  final String id;
  final String title;
  final String description;
  final int estimatedMinutes;

  TaskSubtask({
    required this.id,
    required this.title,
    required this.description,
    required this.estimatedMinutes,
  });
}

class EstimateAlternative {
  final String scenario;
  final int minutes;
  final double probability;

  EstimateAlternative({
    required this.scenario,
    required this.minutes,
    required this.probability,
  });
}

class TaskCompletionEvent {
  final String taskId;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final int estimatedMinutes;
  final int actualMinutes;
  final TaskCategory category;
  final TaskPriority priority;
  final bool completed;
  final double difficultyRating;
  final Map<String, dynamic> context;

  TaskCompletionEvent({
    required this.taskId,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.estimatedMinutes,
    required this.actualMinutes,
    required this.category,
    required this.priority,
    required this.completed,
    required this.difficultyRating,
    required this.context,
  });
}

// Remove duplicate import - already imported at top

class PriorityAnalysis {
  final TaskPriority priority;
  final String reasoning;

  PriorityAnalysis({
    required this.priority,
    required this.reasoning,
  });
}
