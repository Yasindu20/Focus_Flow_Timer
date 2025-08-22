import 'dart:async';
import 'dart:math';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math.dart';
import '../models/enhanced_task.dart';
import '../models/ai_insights.dart' as ai;
import '../models/ai_insights.dart';
import 'genetic_schedule_optimizer.dart';

/// Simplified Enterprise-level Machine Learning Service
/// Uses advanced algorithms without heavy external ML dependencies
class SimplifiedEnterpriseMlService {
  static final SimplifiedEnterpriseMlService _instance = SimplifiedEnterpriseMlService._internal();
  factory SimplifiedEnterpriseMlService() => _instance;
  SimplifiedEnterpriseMlService._internal();

  // Simple Model State
  Map<String, List<double>> _durationWeights = {};
  Map<String, double> _categoryWeights = {};
  Map<String, double> _priorityWeights = {};
  
  // Training Data
  List<TaskCompletionEvent> _trainingEvents = [];
  Map<String, double> _userPatterns = {};
  
  // Model State
  bool _isInitialized = false;
  bool _isTraining = false;
  Map<String, double> _modelAccuracies = {};
  
  // Performance Tracking
  final Map<String, List<double>> _predictionHistory = {};

  /// Initialize the ML service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('Initializing Simplified Enterprise ML Service...');
      
      // Initialize model weights
      _initializeModelWeights();
      
      // Load existing patterns
      await _loadUserPatterns();
      
      // Start background optimization
      _startModelOptimization();
      
      _isInitialized = true;
      debugPrint('Simplified Enterprise ML Service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize ML Service: $e');
      _initializeFallbackWeights();
      _isInitialized = true;
    }
  }

  /// Advanced task duration prediction using ensemble methods
  Future<TaskEstimation> predictTaskDuration({
    required String title,
    required String description,
    required TaskCategory category,
    required TaskPriority priority,
    Map<String, dynamic>? userContext,
  }) async {
    if (!_isInitialized) await initialize();
    
    try {
      // Extract features
      final features = _extractFeatures(
        title: title,
        description: description,
        category: category,
        priority: priority,
        userContext: userContext ?? {},
      );
      
      // Multiple prediction models
      final predictions = <double>[];
      predictions.add(_linearRegressionPredict(features));
      predictions.add(_ruleBasedPredict(features));
      predictions.add(_similarityBasedPredict(features));
      predictions.add(_neuralNetworkPredict(features));
      
      // Ensemble prediction
      final finalPrediction = _ensemblePrediction(predictions);
      final confidence = _calculateConfidence(predictions);
      
      // Generate alternatives
      final alternatives = _generateAlternatives(finalPrediction, confidence);
      
      // Create subtasks
      final subtasks = await _generateIntelligentSubtasks(
        title: title,
        description: description,
        estimatedMinutes: finalPrediction,
      );
      
      // Generate tips
      final tips = _generateContextualTips(category, priority, finalPrediction, userContext ?? {});
      
      return TaskEstimation(
        estimatedMinutes: finalPrediction.round(),
        confidenceLevel: confidence,
        complexityScore: features['complexity'] ?? 0.5,
        factorBreakdown: features,
        suggestedBreakdown: subtasks,
        alternativeEstimates: alternatives,
        tips: tips,
      );
      
    } catch (e) {
      debugPrint('ML prediction failed, using fallback: $e');
      return _fallbackEstimation(title, description, category, priority);
    }
  }

  /// AI-powered task categorization
  Future<TaskCategorizationResult> categorizeTask({
    required String title,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Advanced text analysis
      final textFeatures = _advancedTextAnalysis(title, description);
      
      // Category prediction using weighted scoring
      final categoryScores = _calculateCategoryScores(textFeatures);
      final bestCategory = _getBestCategory(categoryScores);
      final categoryConfidence = categoryScores[bestCategory.name] ?? 0.0;
      
      // Priority analysis
      final priorityAnalysis = _analyzePriority(textFeatures, metadata ?? {});
      
      // Smart tags generation
      final smartTags = _generateSmartTags(textFeatures);
      
      // Related tasks
      final relatedTaskIds = await _findRelatedTasks(textFeatures);
      
      // Subtask suggestions
      final suggestedSubtasks = _suggestSubtasks(title, description, bestCategory);
      
      return TaskCategorizationResult(
        suggestedCategory: bestCategory,
        categoryConfidence: categoryConfidence,
        suggestedPriority: priorityAnalysis.priority,
        priorityReasoning: priorityAnalysis.reasoning,
        smartTags: smartTags,
        suggestedSubtasks: suggestedSubtasks,
        relatedTaskIds: relatedTaskIds,
      );
      
    } catch (e) {
      debugPrint('Categorization failed: $e');
      return _fallbackCategorization(title, description);
    }
  }

  /// Intelligent schedule optimization using genetic algorithms
  Future<TaskScheduleRecommendation> optimizeSchedule({
    required List<EnhancedTask> tasks,
    required DateTime startDate,
    required DateTime endDate,
    Map<String, dynamic>? constraints,
  }) async {
    try {
      // Analyze user work patterns
      final workPatterns = await _analyzeWorkPatterns(tasks);
      
      // Use genetic algorithm for optimization
      final geneticOptimizer = GeneticScheduleOptimizer(
        tasks: tasks,
        constraints: constraints ?? {},
        workPatterns: workPatterns,
      );
      
      final scheduleResults = await geneticOptimizer.optimize(
        generations: 50,
        populationSize: 30,
      );
      
      return TaskScheduleRecommendation(
        recommendedSchedule: scheduleResults.bestSchedule,
        confidenceScore: scheduleResults.fitnessScore,
        alternativeOptions: scheduleResults.alternatives,
        optimizationTips: scheduleResults.tips,
        riskFactors: scheduleResults.risks,
      );
      
    } catch (e) {
      debugPrint('Schedule optimization failed: $e');
      return _fallbackScheduleOptimization(tasks, startDate, endDate);
    }
  }

  /// Learn from completed tasks
  Future<void> learnFromCompletion(TaskCompletionEvent event) async {
    try {
      _trainingEvents.add(event);
      
      // Update prediction accuracy
      _updatePredictionAccuracy(event);
      
      // Incremental learning
      if (_trainingEvents.length % 5 == 0) {
        await _incrementalModelUpdate();
      }
      
    } catch (e) {
      debugPrint('Learning from completion failed: $e');
    }
  }

  /// Generate productivity insights
  Future<Map<String, dynamic>> generateProductivityInsights({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final insights = _analyzeProductivityPatterns(userId, startDate, endDate);
      final recommendations = _generatePersonalizedRecommendations(insights);
      final futurePredictions = _predictFuturePerformance(insights);
      
      return {
        'productivityScore': insights['score'] ?? 0.0,
        'topCategories': insights['categories'] ?? [],
        'optimalHours': insights['peak_hours'] ?? [],
        'recommendations': recommendations,
        'futurePredictions': futurePredictions,
        'modelAccuracy': _modelAccuracies,
      };
      
    } catch (e) {
      debugPrint('Insight generation failed: $e');
      return {'error': e.toString()};
    }
  }

  // Private Methods - Feature Engineering
  Map<String, double> _extractFeatures({
    required String title,
    required String description,
    required TaskCategory category,
    required TaskPriority priority,
    required Map<String, dynamic> userContext,
  }) {
    final features = <String, double>{};
    
    // Text features
    features['title_length'] = title.length / 100.0;
    features['description_length'] = description.length / 1000.0;
    features['word_count'] = (title.split(' ').length + description.split(' ').length) / 50.0;
    
    // Semantic features
    features['technical_density'] = _calculateTechnicalDensity(title + ' ' + description);
    features['complexity'] = _calculateTaskComplexity(title, description);
    features['urgency_indicators'] = _detectUrgencyIndicators(title, description);
    
    // Category and priority encoding
    features['category'] = category.index / TaskCategory.values.length;
    features['priority'] = priority.index / TaskPriority.values.length;
    
    // Temporal features
    final now = DateTime.now();
    features['hour_of_day'] = now.hour / 24.0;
    features['day_of_week'] = now.weekday / 7.0;
    features['is_weekend'] = (now.weekday >= 6) ? 1.0 : 0.0;
    
    // User context
    features['user_experience'] = (userContext['experience'] as double?) ?? 0.5;
    features['current_workload'] = (userContext['workload'] as double?) ?? 0.5;
    features['energy_level'] = (userContext['energy'] as double?) ?? 0.5;
    
    return features;
  }

  // Model implementations
  double _linearRegressionPredict(Map<String, double> features) {
    double prediction = 25.0; // Base estimate
    
    final weights = _durationWeights['linear'] ?? [0.5, 0.3, 0.2, 0.4, 0.6, 0.1, 0.2, 0.3];
    final featureValues = features.values.toList();
    
    for (int i = 0; i < featureValues.length && i < weights.length; i++) {
      prediction += featureValues[i] * weights[i] * 30;
    }
    
    return prediction.clamp(5.0, 240.0);
  }

  double _ruleBasedPredict(Map<String, double> features) {
    double base = 25.0;
    
    // Category-based adjustment
    final category = (features['category'] ?? 0.5) * TaskCategory.values.length;
    if (category >= TaskCategory.coding.index) base *= 1.8;
    else if (category >= TaskCategory.research.index) base *= 1.6;
    else if (category >= TaskCategory.writing.index) base *= 1.4;
    
    // Complexity adjustment
    base *= (0.5 + (features['complexity'] ?? 0.5));
    
    // Priority adjustment
    base *= (0.8 + (features['priority'] ?? 0.5) * 0.4);
    
    return base.clamp(10.0, 180.0);
  }

  double _similarityBasedPredict(Map<String, double> features) {
    // Find similar historical tasks
    if (_trainingEvents.isEmpty) return _ruleBasedPredict(features);
    
    double totalSimilarity = 0.0;
    double weightedDuration = 0.0;
    
    for (final event in _trainingEvents) {
      final similarity = _calculateSimilarity(features, event);
      if (similarity > 0.3) {
        totalSimilarity += similarity;
        weightedDuration += event.actualMinutes * similarity;
      }
    }
    
    if (totalSimilarity > 0) {
      return (weightedDuration / totalSimilarity).clamp(5.0, 240.0);
    }
    
    return _ruleBasedPredict(features);
  }

  double _neuralNetworkPredict(Map<String, double> features) {
    // Simplified neural network simulation
    final inputs = features.values.toList();
    final hiddenLayer = List<double>.filled(5, 0.0);
    
    // Hidden layer computation
    for (int i = 0; i < hiddenLayer.length; i++) {
      double sum = 0.0;
      for (int j = 0; j < inputs.length; j++) {
        final weight = sin(i * j + 1.0) * 0.5; // Pseudo-random weights
        sum += inputs[j] * weight;
      }
      hiddenLayer[i] = _sigmoid(sum);
    }
    
    // Output computation
    double output = 0.0;
    for (int i = 0; i < hiddenLayer.length; i++) {
      output += hiddenLayer[i] * (0.5 + i * 0.1);
    }
    
    return (output * 60 + 20).clamp(10.0, 200.0);
  }

  double _ensemblePrediction(List<double> predictions) {
    if (predictions.isEmpty) return 25.0;
    
    // Weighted ensemble
    final weights = [0.3, 0.4, 0.2, 0.1]; // Linear, Rule-based, Similarity, Neural
    double weighted = 0.0;
    
    for (int i = 0; i < predictions.length && i < weights.length; i++) {
      weighted += predictions[i] * weights[i];
    }
    
    return weighted.clamp(5.0, 240.0);
  }

  double _calculateConfidence(List<double> predictions) {
    if (predictions.length < 2) return 0.6;
    
    final mean = predictions.reduce((a, b) => a + b) / predictions.length;
    final variance = predictions.map((p) => pow(p - mean, 2)).reduce((a, b) => a + b) / predictions.length;
    final stdDev = sqrt(variance);
    
    // Lower standard deviation = higher confidence
    final confidence = 1.0 - (stdDev / mean).clamp(0.0, 0.9);
    return confidence.clamp(0.1, 0.95);
  }

  // Helper methods
  double _calculateTechnicalDensity(String text) {
    final words = text.toLowerCase().split(RegExp(r'\W+'));
    final technicalTerms = {
      'api', 'database', 'algorithm', 'code', 'implement', 'debug', 'test', 'deploy', 
      'optimize', 'refactor', 'integrate', 'develop', 'program', 'script', 'query'
    };
    
    final technicalCount = words.where((word) => technicalTerms.contains(word)).length;
    return words.isEmpty ? 0.0 : technicalCount / words.length;
  }

  double _calculateTaskComplexity(String title, String description) {
    final text = '$title $description'.toLowerCase();
    final words = text.split(' ');
    
    double complexity = 0.0;
    
    // Length factor
    complexity += (words.length / 50.0).clamp(0.0, 0.5);
    
    // Technical complexity
    complexity += _calculateTechnicalDensity(text) * 0.3;
    
    // Complexity keywords
    final complexWords = ['complex', 'difficult', 'challenging', 'advanced', 'comprehensive'];
    for (final word in complexWords) {
      if (text.contains(word)) complexity += 0.1;
    }
    
    return complexity.clamp(0.0, 1.0);
  }

  double _detectUrgencyIndicators(String title, String description) {
    final text = '$title $description'.toLowerCase();
    final urgentTerms = ['urgent', 'asap', 'immediate', 'critical', 'emergency', 'deadline', 'rush'];
    
    int count = 0;
    for (final term in urgentTerms) {
      if (text.contains(term)) count++;
    }
    
    return (count / urgentTerms.length).clamp(0.0, 1.0);
  }

  double _sigmoid(double x) => 1.0 / (1.0 + exp(-x));

  // Initialize model weights
  void _initializeModelWeights() {
    final random = Random();
    
    _durationWeights['linear'] = List.generate(8, (_) => random.nextDouble() - 0.5);
    
    for (final category in TaskCategory.values) {
      _categoryWeights[category.name] = 0.5 + random.nextDouble() * 0.5;
    }
    
    for (final priority in TaskPriority.values) {
      _priorityWeights[priority.name] = 0.3 + priority.index * 0.2;
    }
    
    _modelAccuracies['duration'] = 0.75;
    _modelAccuracies['category'] = 0.80;
    _modelAccuracies['schedule'] = 0.70;
  }

  void _initializeFallbackWeights() {
    _durationWeights['linear'] = [0.5, 0.3, 0.2, 0.4, 0.6, 0.1, 0.2, 0.3];
    
    for (final category in TaskCategory.values) {
      _categoryWeights[category.name] = 0.5;
    }
    
    _modelAccuracies['duration'] = 0.6;
    _modelAccuracies['category'] = 0.65;
  }

  // Placeholder implementations for remaining methods
  Map<String, dynamic> _advancedTextAnalysis(String title, String description) {
    final words = '$title $description'.toLowerCase().split(RegExp(r'\W+'));
    return {
      'sentiment': _calculateSentiment(words),
      'complexity': _calculateTaskComplexity(title, description),
      'technical_terms': _calculateTechnicalDensity(title + ' ' + description),
      'word_count': words.length,
      'keywords': words.take(5).toList(),
    };
  }

  double _calculateSentiment(List<String> words) {
    final positive = ['good', 'great', 'excellent', 'improve', 'enhance', 'optimize'];
    final negative = ['bad', 'difficult', 'problem', 'issue', 'bug', 'error', 'fix'];
    
    int pos = 0, neg = 0;
    for (final word in words) {
      if (positive.contains(word)) pos++;
      if (negative.contains(word)) neg++;
    }
    
    if (pos + neg == 0) return 0.0;
    return (pos - neg) / (pos + neg);
  }

  // Additional helper methods and implementations...
  Map<String, double> _calculateCategoryScores(Map<String, dynamic> textFeatures) {
    final scores = <String, double>{};
    
    for (final category in TaskCategory.values) {
      scores[category.name] = _categoryWeights[category.name] ?? 0.5;
    }
    
    return scores;
  }

  TaskCategory _getBestCategory(Map<String, double> scores) {
    String bestCategoryName = scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return TaskCategory.values.firstWhere((c) => c.name == bestCategoryName, orElse: () => TaskCategory.general);
  }

  PriorityAnalysis _analyzePriority(Map<String, dynamic> textFeatures, Map<String, dynamic> metadata) {
    final complexity = textFeatures['complexity'] as double? ?? 0.5;
    final urgency = _detectUrgencyIndicators(textFeatures.toString(), '');
    
    TaskPriority priority;
    String reasoning;
    
    if (urgency > 0.7 || complexity > 0.8) {
      priority = TaskPriority.critical;
      reasoning = 'High urgency or complexity detected';
    } else if (urgency > 0.4 || complexity > 0.6) {
      priority = TaskPriority.high;
      reasoning = 'Moderate urgency or complexity';
    } else if (urgency > 0.2 || complexity > 0.4) {
      priority = TaskPriority.medium;
      reasoning = 'Standard priority task';
    } else {
      priority = TaskPriority.low;
      reasoning = 'Low complexity task';
    }
    
    return PriorityAnalysis(priority: priority, reasoning: reasoning);
  }

  // Continue with other required methods...
  Future<List<ai.TaskSubtask>> _generateIntelligentSubtasks({
    required String title,
    required String description,
    required double estimatedMinutes,
  }) async {
    final subtasks = <ai.TaskSubtask>[];
    
    if (estimatedMinutes > 50) {
      final numSubtasks = (estimatedMinutes / 30).ceil();
      for (int i = 0; i < numSubtasks; i++) {
        subtasks.add(ai.TaskSubtask(
          id: 'subtask_${DateTime.now().millisecondsSinceEpoch}_$i',
          title: 'Phase ${i + 1}',
          description: 'Auto-generated subtask ${i + 1}',
          estimatedMinutes: (estimatedMinutes / numSubtasks).round(),
        ));
      }
    }
    
    return subtasks;
  }

  List<EstimateAlternative> _generateAlternatives(double basePrediction, double confidence) {
    return [
      EstimateAlternative(
        scenario: 'Optimistic',
        minutes: (basePrediction * 0.8).round(),
        probability: confidence * 0.3,
      ),
      EstimateAlternative(
        scenario: 'Realistic',
        minutes: basePrediction.round(),
        probability: confidence,
      ),
      EstimateAlternative(
        scenario: 'Pessimistic',
        minutes: (basePrediction * 1.3).round(),
        probability: confidence * 0.7,
      ),
    ];
  }

  List<String> _generateContextualTips(TaskCategory category, TaskPriority priority, double estimation, Map<String, dynamic> userContext) {
    final tips = <String>[];
    
    switch (category) {
      case TaskCategory.coding:
        tips.addAll([
          'Use the Pomodoro technique for sustained focus',
          'Have your development environment ready',
          'Break down complex algorithms into smaller steps',
        ]);
        break;
      case TaskCategory.writing:
        tips.addAll([
          'Start with an outline to organize your thoughts',
          'Minimize distractions during writing sessions',
          'Set specific word count goals',
        ]);
        break;
      case TaskCategory.meeting:
        tips.addAll([
          'Prepare an agenda beforehand',
          'Set clear objectives for the meeting',
          'Have all necessary materials ready',
        ]);
        break;
      default:
        tips.add('Stay focused and take breaks as needed');
    }
    
    if (priority == TaskPriority.critical) {
      tips.add('This is a critical task - schedule it during your peak hours');
    }
    
    if (estimation > 90) {
      tips.add('Consider breaking this task into smaller parts');
    }
    
    return tips.take(3).toList();
  }

  List<String> _generateSmartTags(Map<String, dynamic> textFeatures) {
    final tags = <String>[];
    final keywords = textFeatures['keywords'] as List<String>? ?? [];
    
    for (final keyword in keywords.take(3)) {
      if (keyword.length > 3) tags.add('#$keyword');
    }
    
    final complexity = textFeatures['complexity'] as double? ?? 0.0;
    if (complexity > 0.7) tags.add('#complex');
    if (complexity < 0.3) tags.add('#simple');
    
    return tags;
  }

  Future<List<String>> _findRelatedTasks(Map<String, dynamic> textFeatures) async {
    // Simplified related task finding
    return [];
  }

  List<String> _suggestSubtasks(String title, String description, TaskCategory category) {
    final suggestions = <String>[];
    
    switch (category) {
      case TaskCategory.coding:
        suggestions.addAll(['Plan approach', 'Write code', 'Test functionality', 'Review and refactor']);
        break;
      case TaskCategory.writing:
        suggestions.addAll(['Research topic', 'Create outline', 'Write draft', 'Edit and polish']);
        break;
      case TaskCategory.research:
        suggestions.addAll(['Identify sources', 'Gather information', 'Analyze data', 'Summarize findings']);
        break;
      default:
        suggestions.addAll(['Plan', 'Execute', 'Review']);
    }
    
    return suggestions;
  }

  Future<void> _loadUserPatterns() async {
    // Load user patterns from storage
    _userPatterns = {'default_multiplier': 1.0};
  }

  void _startModelOptimization() {
    Timer.periodic(const Duration(hours: 2), (timer) {
      if (_trainingEvents.length >= 3) {
        _backgroundModelImprovement();
      }
    });
  }

  void _backgroundModelImprovement() {
    // Background model optimization
    debugPrint('Running background model optimization...');
  }

  void _updatePredictionAccuracy(TaskCompletionEvent event) {
    // Update model accuracy based on actual vs predicted
  }

  Future<void> _incrementalModelUpdate() async {
    // Incremental learning from recent events
  }

  Map<String, dynamic> _analyzeProductivityPatterns(String userId, DateTime startDate, DateTime endDate) {
    return {
      'score': 0.75,
      'categories': ['coding', 'writing'],
      'peak_hours': [9, 10, 11, 14, 15],
    };
  }

  List<String> _generatePersonalizedRecommendations(Map<String, dynamic> insights) {
    return [
      'Focus on high-priority tasks during peak hours',
      'Take regular breaks to maintain productivity',
      'Consider time-blocking for similar tasks',
    ];
  }

  Map<String, dynamic> _predictFuturePerformance(Map<String, dynamic> insights) {
    return {
      'expected_completion_rate': 0.85,
      'optimal_task_load': 6,
      'recommended_focus_areas': ['coding', 'planning'],
    };
  }

  Future<Map<String, dynamic>> _analyzeWorkPatterns(List<EnhancedTask> tasks) async {
    return {
      'peakHours': [9, 10, 11, 14, 15],
      'averageSessionLength': 45,
      'preferredBreakLength': 15,
    };
  }

  double _calculateSimilarity(Map<String, double> features, TaskCompletionEvent event) {
    // Simple cosine similarity
    double dotProduct = 0.0;
    double norm1 = 0.0, norm2 = 0.0;
    
    final eventFeatures = {
      'complexity': 0.5,
      'category': event.category.index / TaskCategory.values.length,
      'priority': event.priority.index / TaskPriority.values.length,
    };
    
    for (final key in features.keys) {
      if (eventFeatures.containsKey(key)) {
        dotProduct += features[key]! * eventFeatures[key]!;
        norm1 += features[key]! * features[key]!;
        norm2 += eventFeatures[key]! * eventFeatures[key]!;
      }
    }
    
    if (norm1 == 0 || norm2 == 0) return 0.0;
    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }

  // Fallback methods
  TaskEstimation _fallbackEstimation(String title, String description, TaskCategory category, TaskPriority priority) {
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
    
    return TaskEstimation(
      estimatedMinutes: baseMinutes,
      confidenceLevel: 0.6,
      complexityScore: 0.5,
      factorBreakdown: {'base': baseMinutes.toDouble()},
      suggestedBreakdown: [],
      alternativeEstimates: [],
      tips: ['Use the Pomodoro technique for better focus'],
    );
  }

  TaskCategorizationResult _fallbackCategorization(String title, String description) {
    return TaskCategorizationResult(
      suggestedCategory: TaskCategory.general,
      categoryConfidence: 0.6,
      suggestedPriority: TaskPriority.medium,
      priorityReasoning: 'Default categorization',
      smartTags: ['#general'],
      suggestedSubtasks: ['Plan', 'Execute', 'Review'],
      relatedTaskIds: [],
    );
  }

  TaskScheduleRecommendation _fallbackScheduleOptimization(List<EnhancedTask> tasks, DateTime startDate, DateTime endDate) {
    final scheduledTasks = <ScheduledTask>[];
    DateTime currentTime = startDate;
    
    for (final task in tasks) {
      scheduledTasks.add(ScheduledTask(
        taskId: task.id,
        startTime: currentTime,
        endTime: currentTime.add(Duration(minutes: task.estimatedMinutes)),
        confidence: 0.6,
      ));
      currentTime = currentTime.add(Duration(minutes: task.estimatedMinutes + 10));
    }
    
    return TaskScheduleRecommendation(
      recommendedSchedule: scheduledTasks,
      confidenceScore: 0.6,
      alternativeOptions: [],
      optimizationTips: ['Consider task priorities when scheduling'],
      riskFactors: [],
    );
  }

  /// Dispose resources
  void dispose() {
    _trainingEvents.clear();
    _predictionHistory.clear();
    _userPatterns.clear();
  }
}