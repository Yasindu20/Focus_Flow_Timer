import 'dart:async';
 import 'dart:convert';
 import 'dart:math';
 import 'package:flutter/foundation.dart';
 import '../models/enhanced_task.dart';
 import '../models/task_analytics.dart';
 import '../models/ai_insights.dart';
 import '../services/machine_learning_service.dart';
 import '../services/api_integration_service.dart';
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
  final List<TaskCompletionEvent> _recentEvents = [];
  
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
          'context_factor': contextFactor
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
        categoryConfidence: categoryProbabilities.values.reduce(max),
suggestedPriority: priorityAnalysis.priority,
        priorityReasoning: priorityAnalysis.reasoning,
        smartTags: smartTags,
        suggestedSubtasks: _generateSubtaskSuggestions(title, description, intent),
        relatedTasks: await _findRelatedTasks(keywords, intent),
      );
      
    } catch (e) {
      debugPrint('Error in task categorization: $e');
      return _fallbackCategorization(title, description);
    }
  }
  /// Adaptive Learning from Task Completion
  Future<void> learnFromCompletion(TaskCompletionEvent event) async {
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
        productivityScore: productivityAnalysis.overallScore,
        productivityTrend: productivityAnalysis.trend,
        strengths: productivityAnalysis.strengths,
        improvementAreas: productivityAnalysis.weaknesses,
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
      } else if (hour >= 14 && hour <= 16) factor *= 1.1; // Afternoon peak
      else if (hour >= 20 || hour <= 6) factor *= 0.8; // Low energy times
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
  // Additional helper methods would be implemented here...
  
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
  void _updateUserBehaviorModel(TaskCompletionEvent event) {
    // Update user behavior patterns
  }
  void _updateComplexityWeights(TaskCompletionEvent event) {
    // Update complexity scoring weights
  }
  void _updateAccuracyScores(TaskCompletionEvent event) {
    // Update estimation accuracy tracking
  }
  Future<void> _storeCompletionEvent(TaskCompletionEvent event) async {
    // Store event for batch processing
  }
  // More private methods would be implemented here...
 }
 // Supporting Classes
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
  final int estimatedMinutes;
  final String description;
  TaskSubtask({
    required this.id,
    required this.title,
    required this.estimatedMinutes,
    required this.description,
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
 class TaskCategorizationResult {
 final TaskCategory suggestedCategory;
  final double categoryConfidence;
  final TaskPriority suggestedPriority;
  final String priorityReasoning;
  final List<String> smartTags;
  final List<String> suggestedSubtasks;
  final List<EnhancedTask> relatedTasks;
  TaskCategorizationResult({
    required this.suggestedCategory,
    required this.categoryConfidence,
    required this.suggestedPriority,
    required this.priorityReasoning,
    required this.smartTags,
    required this.suggestedSubtasks,
    required this.relatedTasks,
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
 class AIEngineException implements Exception {
  final String message;
  AIEngineException(this.message);
  
  @override
  String toString() => 'AIEngineException: $message';
 }
 // Enum definitions
 enum TaskCategory {
  coding,
  writing,
  meeting,
  research,
  design,
  planning,
  review,
  testing,
  documentation,
  communication,
 }
 enum TaskPriority { low, medium, high, critical }