import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/enhanced_task.dart';
import '../../models/task_analytics.dart';
import '../../models/ai_insights.dart';
import '../../services/machine_learning_service.dart';
import '../../services/api_integration_service.dart';

class TaskIntelligenceEngine {
  static final TaskIntelligenceEngine _instance = TaskIntelligenceEngine._internal();
  factory TaskIntelligenceEngine() => _instance;
  TaskIntelligenceEngine._internal();

  final MachineLearningService _mlService = MachineLearningService();
  final ApiIntegrationService _apiService = ApiIntegrationService();
  
  // AI Model State
  final Map<String, dynamic> _userBehaviorModel = {};
  final Map<String, double> _taskComplexityWeights = {};
  final Map<String, int> _historicalDurations = {};
  final Map<String, double> _accuracyScores = {};
  
  // Real-time Learning
  Timer? _modelUpdateTimer;
  final List<TaskCompletionData> _recentEvents = [];
  
  bool _isInitialized = false;

  /// Initialize the AI engine with historical data
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _loadHistoricalData();
      await _initializeMLModels();
      _startRealTimeLearning();
      _isInitialized = true;
      
      debugPrint('TaskIntelligenceEngine initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize TaskIntelligenceEngine: $e');
      throw AIEngineException('Initialization failed: $e');
    }
  }

  /// AI-Powered Task Duration Estimation
  Future<TaskEstimation> estimateTaskDuration({
    required String title,
    required String description,
    required TaskCategory category,
    required TaskPriority priority,
    String? userId,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Analyze task complexity using NLP
      final complexityScore = await _analyzeTaskComplexity(title, description);
      
      // Get historical patterns for similar tasks
      final historicalPattern = _getHistoricalPattern(category, complexityScore);
      
      // Factor in user-specific behavior
      final userFactor = _getUserPerformanceFactor(userId ?? 'default');
      
      // Consider external context (time of day, workload, etc.)
      final contextFactor = _analyzeContextualFactors(context);
      
      // Apply ML model for final estimation
      final baseEstimate = await _mlService.predictDuration(
        title: title,
        description: description,
        category: category.name,
        priority: priority.name,
        complexityScore: complexityScore,
        historicalData: historicalPattern,
        userFactor: userFactor,
        contextFactor: contextFactor,
      );
      
      // Generate confidence intervals
      final confidence = _calculateConfidenceLevel(baseEstimate, historicalPattern);
      
      // Create estimation with breakdown
      return TaskEstimation(
        estimatedMinutes: baseEstimate.round(),
        confidenceLevel: confidence,
        complexityScore: complexityScore,
        factorBreakdown: {
          'base': baseEstimate,
          'user_factor': userFactor,
          'context_factor': contextFactor,
          'historical_factor': historicalPattern['average'] ?? 25.0,
        },
        suggestedBreakdown: _generateTaskBreakdown(title, description, baseEstimate),
        alternativeEstimates: _generateAlternativeEstimates(baseEstimate, confidence),
        tips: _generateProductivityTips(category, complexityScore, userFactor),
      );
      
    } catch (e) {
      debugPrint('Error in task duration estimation: $e');
      
      // Fallback to rule-based estimation
      return _fallbackEstimation(title, description, category, priority);
    }
  }

  /// Smart Task Categorization
  Future<TaskCategorizationResult> categorizeTask({
    required String title,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Use NLP to analyze task content
      final nlpAnalysis = await _mlService.analyzeTaskContent(title, description);
      
      // Extract keywords and intent
      final keywords = nlpAnalysis['keywords'] as List<String>? ?? [];
      final intent = nlpAnalysis['intent'] as String? ?? 'general';
      
      // Apply ML classification model
      final categoryProbabilities = await _mlService.classifyTaskCategory(
        title: title,
        description: description,
        keywords: keywords,
        intent: intent,
        metadata: metadata,
      );
      
      // Determine priority based on content analysis
      final priorityAnalysis = await _analyzePriority(title, description, keywords);
      
      // Generate tags automatically
      final smartTags = _generateSmartTags(keywords, intent, nlpAnalysis);
      
      return TaskCategorizationResult(
        suggestedCategory: _getBestCategory(categoryProbabilities),
        categoryConfidence: categoryProbabilities.values.isNotEmpty ? 
            categoryProbabilities.values.reduce(max) : 0.0,
        suggestedPriority: priorityAnalysis.priority,
        priorityReasoning: priorityAnalysis.reasoning,
        smartTags: smartTags,
        suggestedSubtasks: _generateSubtaskSuggestions(title, description, intent),
        relatedTaskIds: await _findRelatedTasks(keywords, intent),
      );
      
    } catch (e) {
      debugPrint('Error in task categorization: $e');
      return _fallbackCategorization(title, description);
    }
  }

  /// Adaptive Learning from Task Completion
  Future<void> learnFromCompletion(TaskCompletionData event) async {
    try {
      _recentEvents.add(event);
      
      // Update user behavior model
      _updateUserBehaviorModel(event);
      
      // Update task complexity weights
      _updateComplexityWeights(event);
      
      // Calculate estimation accuracy
      _updateAccuracyScores(event);
      
      // Store for batch processing
      await _storeCompletionEvent(event);
      
      // Real-time model adjustment
      if (_recentEvents.length >= 10) {
        await _performRealTimeModelUpdate();
        _recentEvents.clear();
      }
      
    } catch (e) {
      debugPrint('Error learning from task completion: $e');
    }
  }

  /// Generate AI Insights and Recommendations
  Future<AIInsights> generateInsights({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Analyze productivity patterns
      final productivityAnalysis = await _analyzeProductivityPatterns(
        userId, startDate, endDate
      );
      
      // Identify time optimization opportunities
      final optimizationOpps = await _identifyOptimizationOpportunities(
        userId, productivityAnalysis
      );
      
      // Generate personalized recommendations
      final recommendations = await _generatePersonalizedRecommendations(
        userId, productivityAnalysis, optimizationOpps
      );
      
      // Predict future performance
      final futurePredictions = await _predictFuturePerformance(
        userId, productivityAnalysis
      );
      
      return AIInsights(
        userId: userId,
        analysisDate: DateTime.now(),
        productivityScore: productivityAnalysis['overallScore'] ?? 0.0,
        productivityTrend: productivityAnalysis['trend'] ?? ProductivityTrendDirection.stable,
        strengths: List<String>.from(productivityAnalysis['strengths'] ?? []),
        improvementAreas: List<String>.from(productivityAnalysis['weaknesses'] ?? []),
        recommendations: recommendations,
        optimizationOpportunities: optimizationOpps,
        futurePredictions: futurePredictions,
        personalizedTips: _generatePersonalizedTips(userId, productivityAnalysis),
      );
      
    } catch (e) {
      debugPrint('Error generating AI insights: $e');
      return _fallbackInsights(userId);
    }
  }

  /// Smart Task Scheduling
  Future<TaskScheduleRecommendation> recommendSchedule({
    required List<EnhancedTask> tasks,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> constraints,
  }) async {
    try {
      // Analyze task dependencies
      final dependencies = _analyzeDependencies(tasks);
      
      // Consider user's optimal performance times
      final performanceTimes = await _getUserOptimalTimes(constraints['userId']);
      
      // Apply scheduling algorithm
      final schedule = await _mlService.optimizeSchedule(
        tasks: tasks,
        dependencies: dependencies,
        performanceTimes: performanceTimes,
        constraints: constraints,
        startDate: startDate,
        endDate: endDate,
      );
      
      return TaskScheduleRecommendation(
        recommendedSchedule: schedule,
        confidenceScore: _calculateScheduleConfidence(schedule, tasks),
        alternativeOptions: _generateAlternativeSchedules(tasks, constraints),
        optimizationTips: _generateSchedulingTips(schedule, performanceTimes),
        riskFactors: _identifyScheduleRisks(schedule, tasks),
      );
      
    } catch (e) {
      debugPrint('Error in schedule recommendation: $e');
      return _fallbackScheduleRecommendation(tasks);
    }
  }

  // Private Methods
  Future<void> _loadHistoricalData() async {
    // Load user behavior patterns, task completion history, etc.
    // Implementation details for data loading
  }

  Future<void> _initializeMLModels() async {
    await _mlService.initialize();
    // Load pre-trained models or initialize new ones
  }

  void _startRealTimeLearning() {
    _modelUpdateTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _performScheduledModelUpdate();
    });
  }

  Future<double> _analyzeTaskComplexity(String title, String description) async {
    // NLP analysis for task complexity
    final textLength = (title + description).length;
    final keywordCount = _extractKeywords(title + description).length;
    final technicalWords = _countTechnicalWords(title + description);
    
    // Weighted complexity score (0.0 to 1.0)
    final complexity = (textLength * 0.1 + keywordCount * 0.3 + technicalWords * 0.6) / 100;
    return complexity.clamp(0.0, 1.0);
  }

  Map<String, dynamic> _getHistoricalPattern(TaskCategory category, double complexity) {
    final categoryKey = category.name;
    final complexityBucket = (complexity * 10).round();
    final key = '${categoryKey}_$complexityBucket';
    
    return _historicalDurations[key] != null
        ? {
            'average': _historicalDurations[key]!.toDouble(),
            'confidence': _accuracyScores[key] ?? 0.7,
            'count': _getPatternCount(key),
          }
        : {'average': 25.0, 'confidence': 0.5, 'count': 0};
  }

  double _getUserPerformanceFactor(String userId) {
    final userKey = 'user_$userId';
    return _userBehaviorModel[userKey]?['performance_factor'] ?? 1.0;
  }

  double _analyzeContextualFactors(Map<String, dynamic>? context) {
    if (context == null) return 1.0;
    
    double factor = 1.0;
    
    // Time of day factor
    if (context.containsKey('hour')) {
      final hour = context['hour'] as int;
      if (hour >= 9 && hour <= 11) {
        factor *= 1.2; // Peak morning
      } else if (hour >= 14 && hour <= 16) {
        factor *= 1.1; // Afternoon peak
      } else if (hour >= 20 || hour <= 6) {
        factor *= 0.8; // Low energy times
      }
    }
    
    // Workload factor
    if (context.containsKey('current_tasks')) {
      final currentTasks = context['current_tasks'] as int;
      factor *= (1.0 - (currentTasks * 0.05)).clamp(0.7, 1.0);
    }
    
    return factor;
  }

  double _calculateConfidenceLevel(double estimate, Map<String, dynamic> historical) {
    final count = historical['count'] as int? ?? 0;
    final baseConfidence = historical['confidence'] as double? ?? 0.5;
    
    // More data = higher confidence
    final dataConfidence = (count / (count + 10)).clamp(0.0, 0.9);
    
    return (baseConfidence + dataConfidence) / 2;
  }

  List<TaskSubtask> _generateTaskBreakdown(String title, String description, double totalMinutes) {
    // AI-powered task breakdown logic
    final subtasks = <TaskSubtask>[];
    
    // Simple rule-based breakdown for now
    if (totalMinutes > 45) {
      final numSubtasks = (totalMinutes / 25).ceil();
      for (int i = 0; i < numSubtasks; i++) {
        subtasks.add(TaskSubtask(
          id: 'subtask_$i',
          title: 'Phase ${i + 1}',
          estimatedMinutes: (totalMinutes / numSubtasks).round(),
          description: 'Generated subtask ${i + 1}',
        ));
      }
    }
    
    return subtasks;
  }

  List<EstimateAlternative> _generateAlternativeEstimates(double base, double confidence) {
    return [
      EstimateAlternative(
        scenario: 'Optimistic',
        minutes: (base * 0.8).round(),
        probability: confidence > 0.8 ? 0.3 : 0.2,
      ),
      EstimateAlternative(
        scenario: 'Realistic',
        minutes: base.round(),
        probability: confidence,
      ),
      EstimateAlternative(
        scenario: 'Pessimistic',
        minutes: (base * 1.5).round(),
        probability: confidence > 0.7 ? 0.2 : 0.3,
      ),
    ];
  }

  List<String> _generateProductivityTips(TaskCategory category, double complexity, double userFactor) {
    final tips = <String>[];
    
    if (complexity > 0.7) {
      tips.add('Consider breaking this complex task into smaller parts');
      tips.add('Take regular breaks every 25 minutes');
    }
    
    if (userFactor < 0.9) {
      tips.add('This might take longer than usual - plan accordingly');
      tips.add('Consider tackling this when you\'re most focused');
    }
    
    switch (category) {
      case TaskCategory.coding:
        tips.add('Use the Pomodoro technique for sustained focus');
        tips.add('Have your development environment ready');
        break;
      case TaskCategory.writing:
        tips.add('Start with an outline to organize your thoughts');
        tips.add('Minimize distractions during writing sessions');
        break;
      case TaskCategory.meeting:
        tips.add('Prepare an agenda beforehand');
        tips.add('Set clear objectives for the meeting');
        break;
      default:
        tips.add('Stay focused and take breaks as needed');
    }
    
    return tips;
  }

  TaskEstimation _fallbackEstimation(String title, String description, TaskCategory category, TaskPriority priority) {
    // Rule-based fallback estimation
    int baseMinutes = 25;
    
    switch (category) {
      case TaskCategory.coding:
        baseMinutes = 45;
        break;
      case TaskCategory.meeting:
        baseMinutes = 30;
        break;
      case TaskCategory.writing:
        baseMinutes = 35;
        break;
      case TaskCategory.research:
        baseMinutes = 40;
        break;
      default:
        baseMinutes = 25;
    }
    
    // Adjust for priority
    switch (priority) {
      case TaskPriority.high:
        baseMinutes = (baseMinutes * 1.2).round();
        break;
      case TaskPriority.low:
        baseMinutes = (baseMinutes * 0.8).round();
        break;
      default:
        break;
      case TaskPriority.critical:
        baseMinutes = (baseMinutes * 1.5).round();
        break;
    }
    
    return TaskEstimation(
      estimatedMinutes: baseMinutes,
      confidenceLevel: 0.6,
      complexityScore: 0.5,
      factorBreakdown: {'base': baseMinutes.toDouble()},
      suggestedBreakdown: [],
      alternativeEstimates: [],
      tips: ['This is a fallback estimation'],
    );
  }

  // Implementation of missing methods
  Future<PriorityAnalysis> _analyzePriority(String title, String description, List<String> keywords) async {
    // Analyze urgency keywords
    final urgencyKeywords = ['urgent', 'asap', 'critical', 'deadline', 'emergency'];
    final lowPriorityKeywords = ['later', 'someday', 'optional', 'nice-to-have'];
    
    int urgencyScore = 0;
    int lowPriorityScore = 0;
    
    for (final keyword in keywords) {
      if (urgencyKeywords.contains(keyword.toLowerCase())) {
        urgencyScore++;
      }
      if (lowPriorityKeywords.contains(keyword.toLowerCase())) {
        lowPriorityScore++;
      }
    }
    
    TaskPriority priority;
    String reasoning;
    
    if (urgencyScore > 0) {
      priority = TaskPriority.high;
      reasoning = 'Contains urgency indicators';
    } else if (lowPriorityScore > 0) {
      priority = TaskPriority.low;
      reasoning = 'Contains low priority indicators';
    } else {
      priority = TaskPriority.medium;
      reasoning = 'No clear priority indicators found';
    }
    
    return PriorityAnalysis(priority: priority, reasoning: reasoning);
  }

  List<String> _generateSmartTags(List<String> keywords, String intent, Map<String, dynamic> nlpAnalysis) {
    final tags = <String>[];
    
    // Add intent as tag
    if (intent != 'general') {
      tags.add(intent);
    }
    
    // Add relevant keywords as tags
    tags.addAll(keywords.take(3));
    
    // Add complexity-based tags
    final complexity = nlpAnalysis['complexity_indicators'];
    if (complexity != null) {
      final complexityScore = complexity['complexity_score'] as int? ?? 0;
      if (complexityScore > 2) {
        tags.add('complex');
      }
      
      final urgencyScore = complexity['urgency_score'] as int? ?? 0;
      if (urgencyScore > 0) {
        tags.add('urgent');
      }
    }
    
    return tags.toSet().toList(); // Remove duplicates
  }

  TaskCategory _getBestCategory(Map<String, double> categoryProbabilities) {
    if (categoryProbabilities.isEmpty) return TaskCategory.general;
    
    final bestEntry = categoryProbabilities.entries.reduce(
      (a, b) => a.value > b.value ? a : b
    );
    
    return TaskCategory.values.firstWhere(
      (cat) => cat.name == bestEntry.key,
      orElse: () => TaskCategory.general,
    );
  }

  List<String> _generateSubtaskSuggestions(String title, String description, String intent) {
    final suggestions = <String>[];
    
    switch (intent) {
      case 'create':
        suggestions.addAll(['Plan and design', 'Implement core functionality', 'Test and refine']);
        break;
      case 'fix':
        suggestions.addAll(['Identify root cause', 'Implement fix', 'Verify solution']);
        break;
      case 'research':
        suggestions.addAll(['Gather initial information', 'Deep dive analysis', 'Compile findings']);
        break;
      default:
        suggestions.addAll(['Preparation phase', 'Main execution', 'Review and finalize']);
    }
    
    return suggestions;
  }

  Future<List<String>> _findRelatedTasks(List<String> keywords, String intent) async {
    // In a real implementation, this would search existing tasks
    // For now, return empty list
    return [];
  }

  TaskCategorizationResult _fallbackCategorization(String title, String description) {
    return TaskCategorizationResult(
      suggestedCategory: TaskCategory.general,
      categoryConfidence: 0.5,
      suggestedPriority: TaskPriority.medium,
      priorityReasoning: 'Default fallback categorization',
      smartTags: ['general'],
      suggestedSubtasks: [],
      relatedTaskIds: [],
    );
  }

  Future<Map<String, dynamic>> _analyzeProductivityPatterns(String userId, DateTime startDate, DateTime endDate) async {
    // Mock implementation
    return {
      'overallScore': 75.0,
      'trend': ProductivityTrendDirection.increasing,
      'strengths': ['Consistent work schedule', 'Good estimation accuracy'],
      'weaknesses': ['Too many interruptions', 'Low focus during afternoons'],
    };
  }

  Future<List<OptimizationOpportunity>> _identifyOptimizationOpportunities(String userId, Map<String, dynamic> analysis) async {
    return [
      OptimizationOpportunity(
        type: OptimizationType.focus,
        impact: OpportunityImpact.high,
        description: 'Schedule complex tasks during morning hours',
        potentialTimeSaving: const Duration(minutes: 30),
      ),
    ];
  }

  Future<List<ProductivityRecommendation>> _generatePersonalizedRecommendations(
    String userId, 
    Map<String, dynamic> analysis, 
    List<OptimizationOpportunity> opportunities
  ) async {
    return [
      ProductivityRecommendation(
        type: RecommendationType.focusTime,
        title: 'Optimize Focus Sessions',
        description: 'Try longer focus sessions in the morning',
        impact: RecommendationImpact.high,
        effort: RecommendationEffort.low,
      ),
    ];
  }

  Future<PredictiveAnalytics> _predictFuturePerformance(String userId, Map<String, dynamic> analysis) async {
    return PredictiveAnalytics.empty();
  }

  List<String> _generatePersonalizedTips(String userId, Map<String, dynamic> analysis) {
    return [
      'Schedule important tasks during your peak hours (9-11 AM)',
      'Take breaks every 25 minutes to maintain focus',
      'Batch similar tasks together for better efficiency',
    ];
  }

  AIInsights _fallbackInsights(String userId) {
    return AIInsights.empty(userId);
  }

  Map<String, List<String>> _analyzeDependencies(List<EnhancedTask> tasks) {
    final dependencies = <String, List<String>>{};
    
    for (final task in tasks) {
      dependencies[task.id] = task.dependencies;
    }
    
    return dependencies;
  }

  Future<Map<String, double>> _getUserOptimalTimes(String? userId) async {
    // Mock optimal times - in real implementation, analyze user's historical performance
    return {
      '9': 0.9,
      '10': 0.95,
      '11': 0.85,
      '14': 0.7,
      '15': 0.75,
      '16': 0.6,
    };
  }

  double _calculateScheduleConfidence(List<ScheduledTask> schedule, List<EnhancedTask> tasks) {
    if (schedule.isEmpty) return 0.0;
    
    final avgConfidence = schedule.map((s) => s.confidence).reduce((a, b) => a + b) / schedule.length;
    return avgConfidence;
  }

  List<ScheduledTask> _generateAlternativeSchedules(List<EnhancedTask> tasks, Map<String, dynamic> constraints) {
    // Mock alternative schedules
    return [];
  }

  List<String> _generateSchedulingTips(List<ScheduledTask> schedule, Map<String, double> performanceTimes) {
    return [
      'Consider scheduling complex tasks during high-performance hours',
      'Leave buffer time between tasks for transitions',
      'Group similar tasks together when possible',
    ];
  }

  List<String> _identifyScheduleRisks(List<ScheduledTask> schedule, List<EnhancedTask> tasks) {
    return [
      'Tight schedule with little buffer time',
      'Back-to-back meetings may cause fatigue',
    ];
  }

  TaskScheduleRecommendation _fallbackScheduleRecommendation(List<EnhancedTask> tasks) {
    return TaskScheduleRecommendation(
      recommendedSchedule: [],
      confidenceScore: 0.5,
      alternativeOptions: [],
      optimizationTips: ['Use standard time blocking techniques'],
      riskFactors: ['Limited AI data for personalized scheduling'],
    );
  }

  // Helper methods
  List<String> _extractKeywords(String text) {
    // Simple keyword extraction
    return text.toLowerCase()
        .split(RegExp(r'\W+'))
        .where((word) => word.length > 3)
        .toList();
  }

  int _countTechnicalWords(String text) {
    final technicalWords = [
      'algorithm', 'api', 'database', 'code', 'function', 'variable',
      'implement', 'refactor', 'optimize', 'debug', 'test', 'deploy'
    ];
    
    final words = text.toLowerCase().split(RegExp(r'\W+'));
    return words.where((word) => technicalWords.contains(word)).length;
  }

  int _getPatternCount(String key) {
    // Implementation to get pattern count from storage
    return 5; // Placeholder
  }

  void _performScheduledModelUpdate() {
    // Scheduled model updates
  }

  Future<void> _performRealTimeModelUpdate() async {
    // Real-time model updates based on recent events
  }

  void _updateUserBehaviorModel(TaskCompletionData event) {
    // Update user behavior patterns
  }

  void _updateComplexityWeights(TaskCompletionData event) {
    // Update complexity scoring weights
  }

  void _updateAccuracyScores(TaskCompletionData event) {
    // Update estimation accuracy tracking
  }

  Future<void> _storeCompletionEvent(TaskCompletionData event) async {
    // Store event for batch processing
  }
}

class AIEngineException implements Exception {
  final String message;
  AIEngineException(this.message);
  
  @override
  String toString() => 'AIEngineException: $message';
}