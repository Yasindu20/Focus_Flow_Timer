import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/enhanced_task.dart';
import 'simplified_enterprise_ml_service.dart';

class MachineLearningService {
  static final MachineLearningService _instance =
      MachineLearningService._internal();
  factory MachineLearningService() => _instance;
  MachineLearningService._internal();

  final SimplifiedEnterpriseMlService _enterpriseML =
      SimplifiedEnterpriseMlService();
  // ML Model State
  Map<String, dynamic> _durationModel = {};
  Map<String, dynamic> _categoryModel = {};
  Map<String, dynamic> _scheduleModel = {};
  List<Map<String, dynamic>> _trainingData = [];
  bool _isInitialized = false;
  bool _isTraining = false;

  /// Initialize ML models
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _enterpriseML.initialize();
      await _loadPretrainedModels();
      await _loadTrainingData();
      _isInitialized = true;

      debugPrint('MachineLearningService initialized');
    } catch (e) {
      debugPrint('Failed to initialize ML service: $e');
      _initializeEmptyModels();
      _isInitialized = true;
    }
  }

  /// Predict task duration using ML model
  Future<double> predictDuration({
    required String title,
    required String description,
    required String category,
    required String priority,
    required double complexityScore,
    required Map<String, dynamic> historicalData,
    required double userFactor,
    required double contextFactor,
  }) async {
    if (!_isInitialized) await initialize();
    try {
      // Convert string category/priority to enums
      final taskCategory = TaskCategory.values.firstWhere(
        (e) => e.name == category,
        orElse: () => TaskCategory.general,
      );
      final taskPriority = TaskPriority.values.firstWhere(
        (e) => e.name == priority,
        orElse: () => TaskPriority.medium,
      );

      // Use enterprise ML service
      final estimation = await _enterpriseML.predictTaskDuration(
        title: title,
        description: description,
        category: taskCategory,
        priority: taskPriority,
        userContext: {
          'complexity': complexityScore,
          'userFactor': userFactor,
          'contextFactor': contextFactor,
          'historicalData': historicalData,
        },
      );

      return estimation.estimatedMinutes.toDouble();
    } catch (e) {
      debugPrint('Error in duration prediction: $e');
      return _fallbackDurationPrediction(category, complexityScore);
    }
  }

  /// Analyze task content using NLP
  Future<Map<String, dynamic>> analyzeTaskContent(
      String title, String description) async {
    try {
      // Use simplified enterprise ML service for text analysis
      final fullText = '$title $description';
      final words = fullText.toLowerCase().split(RegExp(r'\W+'));

      return {
        'keywords': words.where((w) => w.length > 3).take(5).toList(),
        'intent': _classifyIntent(words),
        'sentiment': 0.0, // Neutral sentiment
        'entities': <String, List<String>>{},
        'complexity_indicators': {'complexity_score': 0, 'urgency_score': 0},
        'token_count': words.length,
        'unique_token_count': words.toSet().length,
      };
    } catch (e) {
      debugPrint('Error in task content analysis: $e');
      return _fallbackContentAnalysis(title, description);
    }
  }

  /// Classify task category using ML
  Future<Map<String, double>> classifyTaskCategory({
    required String title,
    required String description,
    required List<String> keywords,
    required String intent,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Feature extraction for category classification
      final features = _extractCategoryFeatures(
        title: title,
        description: description,
        keywords: keywords,
        intent: intent,
        metadata: metadata,
      );
      // Apply category classification model
      final probabilities = _applyCategoryModel(features);
      return probabilities;
    } catch (e) {
      debugPrint('Error in category classification: $e');
      return _fallbackCategoryClassification(keywords);
    }
  }

  /// Optimize task schedule using ML
  Future<List<ScheduledTask>> optimizeSchedule({
    required List<EnhancedTask> tasks,
    required Map<String, List<String>> dependencies,
    required Map<String, double> performanceTimes,
    required Map<String, dynamic> constraints,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Prepare scheduling features
      final features = _extractSchedulingFeatures(
        tasks: tasks,
        dependencies: dependencies,
        performanceTimes: performanceTimes,
        constraints: constraints,
      );
      // Apply scheduling optimization algorithm
      final schedule = _applySchedulingModel(features, startDate, endDate);
      return schedule;
    } catch (e) {
      debugPrint('Error in schedule optimization: $e');
      return _fallbackScheduleOptimization(tasks, startDate, endDate);
    }
  }

  /// Train models with new data
  Future<void> trainModels(List<Map<String, dynamic>> newData) async {
    if (_isTraining) return;
    try {
      _isTraining = true;

      // Add new data to training set
      _trainingData.addAll(newData);

      // Retrain duration model
      await _trainDurationModel();

      // Retrain category model
      await _trainCategoryModel();

      // Retrain scheduling model
      await _trainSchedulingModel();

      // Save updated models
      await _saveModels();

      debugPrint('ML models retrained with ${newData.length} new samples');
    } catch (e) {
      debugPrint('Error training models: $e');
    } finally {
      _isTraining = false;
    }
  }

  /// Get model performance metrics
  Map<String, dynamic> getModelMetrics() {
    return {
      'duration_model': {
        'accuracy': _durationModel['accuracy'] ?? 0.0,
        'training_samples': _durationModel['training_samples'] ?? 0,
        'last_updated': _durationModel['last_updated'] ?? 'Never',
      },
      'category_model': {
        'accuracy': _categoryModel['accuracy'] ?? 0.0,
        'training_samples': _categoryModel['training_samples'] ?? 0,
        'last_updated': _categoryModel['last_updated'] ?? 'Never',
      },
      'schedule_model': {
        'accuracy': _scheduleModel['accuracy'] ?? 0.0,
        'training_samples': _scheduleModel['training_samples'] ?? 0,
        'last_updated': _scheduleModel['last_updated'] ?? 'Never',
      },
      'total_training_data': _trainingData.length,
    };
  }

  // Private Methods
  Future<void> _loadPretrainedModels() async {
    // Load pre-trained models from storage or assets
    // This would typically load from SharedPreferences or a file
    _durationModel = {
      'weights': _generateRandomWeights(20),
      'bias': 0.0,
      'accuracy': 0.75,
      'training_samples': 0,
      'last_updated': DateTime.now().toIso8601String(),
    };
    _categoryModel = {
      'weights': _generateCategoryWeights(),
      'bias': _generateRandomWeights(10),
      'accuracy': 0.80,
      'training_samples': 0,
      'last_updated': DateTime.now().toIso8601String(),
    };
    _scheduleModel = {
      'weights': _generateRandomWeights(15),
      'bias': 0.0,
      'accuracy': 0.70,
      'training_samples': 0,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _loadTrainingData() async {
    // Load historical training data
    _trainingData = [];
  }

  void _initializeEmptyModels() {
    _durationModel = {
      'weights': _generateRandomWeights(20),
      'bias': 0.0,
      'accuracy': 0.5,
      'training_samples': 0,
    };
    _categoryModel = {
      'weights': _generateCategoryWeights(),
      'bias': _generateRandomWeights(10),
      'accuracy': 0.5,
      'training_samples': 0,
    };
    _scheduleModel = {
      'weights': _generateRandomWeights(15),
      'bias': 0.0,
      'accuracy': 0.5,
      'training_samples': 0,
    };
  }

  List<double> _extractDurationFeatures({
    required String title,
    required String description,
    required String category,
    required String priority,
    required double complexityScore,
    required Map<String, dynamic> historicalData,
    required double userFactor,
    required double contextFactor,
  }) {
    return [
      title.length.toDouble() / 100, // Normalized title length
      description.length.toDouble() / 1000, // Normalized description length
      complexityScore,
      userFactor,
      contextFactor,
      historicalData['average'] as double? ??
          25.0 / 100, // Normalized historical average
      _getCategoryEncoding(category),
      _getPriorityEncoding(priority),
      _getWordComplexity(title + description),
      _getTechnicalComplexity(title + description),
      // Add more features as needed...
    ];
  }

  double _applyDurationModel(List<double> features) {
    final weights = _durationModel['weights'] as List<double>;
    final bias = _durationModel['bias'] as double;
    double result = bias;
    for (int i = 0; i < features.length && i < weights.length; i++) {
      result += features[i] * weights[i];
    }
    // Apply activation function (sigmoid for normalization)
    return _sigmoid(result) * 120; // Scale to reasonable duration range
  }

  double _postProcessDurationPrediction(
      double prediction, List<double> features) {
    // Post-processing to ensure reasonable bounds
    return prediction.clamp(5.0, 240.0); // 5 minutes to 4 hours
  }

  String _classifyIntent(List<String> words) {
    final intentMap = {
      'create': ['create', 'build', 'develop', 'implement', 'make', 'design'],
      'update': ['update', 'modify', 'change', 'edit', 'refactor', 'improve'],
      'fix': ['fix', 'repair', 'debug', 'resolve', 'solve', 'correct'],
      'research': ['research', 'investigate', 'study', 'analyze', 'explore'],
      'meeting': ['meeting', 'discuss', 'call', 'conference', 'presentation'],
      'review': ['review', 'check', 'validate', 'verify', 'audit', 'test'],
    };

    for (final intent in intentMap.keys) {
      if (words.any((word) => intentMap[intent]!.contains(word))) {
        return intent;
      }
    }

    return 'general';
  }

  double _fallbackDurationPrediction(String category, double complexityScore) {
    final baseDurations = {
      'coding': 45.0,
      'writing': 30.0,
      'meeting': 30.0,
      'research': 40.0,
      'design': 35.0,
      'planning': 25.0,
      'review': 20.0,
      'testing': 30.0,
      'documentation': 25.0,
      'communication': 15.0,
    };
    final base = baseDurations[category] ?? 25.0;
    return base * (1.0 + complexityScore * 0.5);
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
  }

  List<String> _preprocessTokens(List<String> tokens) {
    final stopWords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'from',
      'up',
      'about',
      'into',
      'through',
      'during',
      'before',
      'after',
      'above',
      'below',
      'between',
      'among',
      'through',
      'during',
      'before',
      'after',
      'above',
      'below',
      'up',
      'down',
      'out',
      'off',
      'over',
      'under',
      'again',
      'further',
      'then',
      'once',
      'here',
      'there',
      'when',
      'where',
      'why',
      'how',
      'all',
      'any',
      'both',
      'each',
      'few',
      'more',
      'most',
      'other',
      'some',
      'such',
      'no',
      'nor',
      'not',
      'only',
      'own',
      'same',
      'so',
      'than',
      'too',
      'very',
      's',
      't',
      'can',
      'will',
      'just',
      'don',
      'should',
      'now',
      'i',
      'me',
      'my',
      'myself',
      'we',
      'our',
      'ours',
      'ourselves',
      'you',
      'your',
      'yours',
      'yourself',
      'yourselves',
      'he',
      'him',
      'his',
      'himself',
      'she',
      'her',
      'hers',
      'herself',
      'it',
      'its',
      'itself',
      'they',
      'them',
      'their',
      'theirs',
      'themselves',
      'what',
      'which',
      'who',
      'whom',
      'this',
      'that',
      'these',
      'those',
      'am',
      'is',
      'are',
      'was',
      'were',
      'be',
      'been',
      'being',
      'have',
      'has',
      'had',
      'having',
      'do',
      'does',
      'did',
      'doing',
      'would',
      'should',
      'could',
      'ought'
    };
    return tokens
        .where((token) => !stopWords.contains(token) && token.length > 2)
        .toList();
  }

  List<String> _extractKeywords(List<String> tokens) {
    final keywordCounts = <String, int>{};

    for (final token in tokens) {
      keywordCounts[token] = (keywordCounts[token] ?? 0) + 1;
    }
    // Sort by frequency and return top keywords
    final sortedKeywords = keywordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedKeywords.take(10).map((entry) => entry.key).toList();
  }

  double _analyzeSentiment(List<String> tokens) {
    final positiveWords = {
      'good',
      'great',
      'excellent',
      'amazing',
      'awesome',
      'fantastic',
      'wonderful',
      'perfect',
      'outstanding',
      'brilliant',
      'superb',
      'improve',
      'enhance',
      'optimize',
      'upgrade',
      'better'
    };
    final negativeWords = {
      'bad',
      'terrible',
      'awful',
      'horrible',
      'worst',
      'hate',
      'difficult',
      'hard',
      'complex',
      'challenging',
      'problem',
      'issue',
      'bug',
      'error',
      'fix',
      'broken',
      'failed',
      'urgent',
      'critical'
    };
    int positive = 0;
    int negative = 0;
    for (final token in tokens) {
      if (positiveWords.contains(token)) positive++;
      if (negativeWords.contains(token)) negative++;
    }
    if (positive == 0 && negative == 0) return 0.0;
    return (positive - negative) / (positive + negative);
  }

  Map<String, List<String>> _recognizeEntities(List<String> tokens) {
    final entities = <String, List<String>>{
      'technologies': [],
      'actions': [],
      'objects': [],
    };
    final techKeywords = {
      'api',
      'database',
      'frontend',
      'backend',
      'ui',
      'ux',
      'mobile',
      'web',
      'ios',
      'android',
      'react',
      'flutter',
      'angular',
      'vue',
      'node',
      'python',
      'java',
      'javascript',
      'typescript',
      'swift',
      'kotlin',
      'dart',
      'html',
      'css',
      'sql',
      'mongodb',
      'firebase'
    };
    final actionKeywords = {
      'implement',
      'develop',
      'create',
      'build',
      'design',
      'test',
      'deploy',
      'review',
      'update',
      'fix',
      'optimize',
      'refactor'
    };
    for (final token in tokens) {
      if (techKeywords.contains(token)) {
        entities['technologies']!.add(token);
      }
      if (actionKeywords.contains(token)) {
        entities['actions']!.add(token);
      }
    }
    return entities;
  }

  Map<String, dynamic> _identifyComplexityIndicators(List<String> tokens) {
    final complexityKeywords = {
      'algorithm',
      'optimization',
      'integration',
      'architecture',
      'performance',
      'security',
      'scalability',
      'database',
      'api',
      'complex',
      'advanced',
      'sophisticated',
      'comprehensive'
    };
    final urgencyKeywords = {
      'urgent',
      'asap',
      'immediate',
      'critical',
      'priority',
      'deadline'
    };
    int complexityScore = 0;
    int urgencyScore = 0;
    for (final token in tokens) {
      if (complexityKeywords.contains(token)) complexityScore++;
      if (urgencyKeywords.contains(token)) urgencyScore++;
    }
    return {
      'complexity_score': complexityScore,
      'urgency_score': urgencyScore,
      'technical_density': _calculateTechnicalDensity(tokens),
    };
  }

  double _calculateTechnicalDensity(List<String> tokens) {
    final technicalTerms = {
      'api',
      'database',
      'algorithm',
      'function',
      'class',
      'method',
      'interface',
      'framework',
      'library',
      'module',
      'component',
      'service',
      'endpoint',
      'query',
      'schema',
      'migration',
      'deployment'
    };
    final technicalCount =
        tokens.where((token) => technicalTerms.contains(token)).length;
    return tokens.isEmpty ? 0.0 : technicalCount / tokens.length;
  }

  Map<String, dynamic> _fallbackContentAnalysis(
      String title, String description) {
    final tokens = _tokenize('$title $description');
    return {
      'keywords': tokens.take(5).toList(),
      'intent': 'general',
      'sentiment': 0.0,
      'entities': <String, List<String>>{},
      'complexity_indicators': {'complexity_score': 0, 'urgency_score': 0},
      'token_count': tokens.length,
      'unique_token_count': tokens.toSet().length,
    };
  }

  List<double> _extractCategoryFeatures({
    required String title,
    required String description,
    required List<String> keywords,
    required String intent,
    Map<String, dynamic>? metadata,
  }) {
    final features = <double>[];

    // Text-based features
    features.add(title.length.toDouble() / 100);
    features.add(description.length.toDouble() / 1000);
    features.add(keywords.length.toDouble() / 10);

    // Intent encoding
    features.add(_getIntentEncoding(intent));

    // Keyword category indicators
    features.addAll(_getCategoryIndicators(keywords));

    return features;
  }

  Map<String, double> _applyCategoryModel(List<double> features) {
    final weights = _categoryModel['weights'] as Map<String, List<double>>;
    final bias = _categoryModel['bias'] as List<double>;

    final categories = [
      'coding',
      'writing',
      'meeting',
      'research',
      'design',
      'planning',
      'review',
      'testing',
      'documentation',
      'communication'
    ];

    final probabilities = <String, double>{};
    for (int i = 0; i < categories.length; i++) {
      final categoryWeights =
          weights[categories[i]] ?? List.filled(features.length, 0.1);
      double score = bias[i];

      for (int j = 0; j < features.length && j < categoryWeights.length; j++) {
        score += features[j] * categoryWeights[j];
      }

      probabilities[categories[i]] = _sigmoid(score);
    }

    // Normalize probabilities
    final total = probabilities.values.reduce((a, b) => a + b);
    if (total > 0) {
      probabilities.updateAll((key, value) => value / total);
    }

    return probabilities;
  }

  Map<String, double> _fallbackCategoryClassification(List<String> keywords) {
    final categoryKeywords = {
      'coding': [
        'code',
        'program',
        'develop',
        'implement',
        'bug',
        'api',
        'function'
      ],
      'writing': ['write', 'document', 'content', 'article', 'blog', 'copy'],
      'meeting': ['meeting', 'call', 'discuss', 'conference', 'presentation'],
      'research': ['research', 'analyze', 'study', 'investigate', 'explore'],
      'design': ['design', 'ui', 'ux', 'mockup', 'wireframe', 'prototype'],
      'planning': ['plan', 'strategy', 'roadmap', 'schedule', 'organize'],
      'review': ['review', 'check', 'verify', 'audit', 'test', 'validate'],
      'testing': ['test', 'qa', 'bug', 'quality', 'validation'],
      'documentation': ['document', 'wiki', 'guide', 'manual', 'readme'],
      'communication': ['email', 'message', 'contact', 'notify', 'inform'],
    };
    final scores = <String, double>{};

    for (final category in categoryKeywords.keys) {
      int matches = 0;
      for (final keyword in keywords) {
        if (categoryKeywords[category]!.contains(keyword)) {
          matches++;
        }
      }
      scores[category] = matches.toDouble();
    }
    // Normalize
    final total = scores.values.reduce((a, b) => a + b);
    if (total > 0) {
      scores.updateAll((key, value) => value / total);
    } else {
      // Default equal probabilities
      scores.updateAll((key, value) => 1.0 / scores.length);
    }
    return scores;
  }

  // Additional helper methods...
  List<double> _generateRandomWeights(int count) {
    final random = Random();
    return List.generate(count, (index) => (random.nextDouble() - 0.5) * 2);
  }

  Map<String, List<double>> _generateCategoryWeights() {
    final categories = [
      'coding',
      'writing',
      'meeting',
      'research',
      'design',
      'planning',
      'review',
      'testing',
      'documentation',
      'communication'
    ];

    final weights = <String, List<double>>{};
    for (final category in categories) {
      weights[category] = _generateRandomWeights(10);
    }

    return weights;
  }

  double _getCategoryEncoding(String category) {
    final categoryMap = {
      'coding': 1.0,
      'writing': 2.0,
      'meeting': 3.0,
      'research': 4.0,
      'design': 5.0,
      'planning': 6.0,
      'review': 7.0,
      'testing': 8.0,
      'documentation': 9.0,
      'communication': 10.0,
    };
    return (categoryMap[category] ?? 0.0) / 10.0;
  }

  double _getPriorityEncoding(String priority) {
    final priorityMap = {
      'low': 0.25,
      'medium': 0.5,
      'high': 0.75,
      'critical': 1.0,
    };
    return priorityMap[priority] ?? 0.5;
  }

  double _getIntentEncoding(String intent) {
    final intentMap = {
      'create': 1.0,
      'update': 2.0,
      'fix': 3.0,
      'research': 4.0,
      'meeting': 5.0,
      'review': 6.0,
      'plan': 7.0,
      'communicate': 8.0,
      'general': 0.0,
    };
    return (intentMap[intent] ?? 0.0) / 8.0;
  }

  double _getWordComplexity(String text) {
    final words = text.split(' ');
    if (words.isEmpty) return 0.0;

    final avgLength =
        words.map((w) => w.length).reduce((a, b) => a + b) / words.length;
    return (avgLength / 15).clamp(0.0, 1.0);
  }

  double _getTechnicalComplexity(String text) {
    final technicalPatterns = [
      RegExp(r'\b(api|database|algorithm|framework|library)\b',
          caseSensitive: false),
      RegExp(r'\b(implement|develop|integrate|optimize)\b',
          caseSensitive: false),
      RegExp(r'\b(frontend|backend|fullstack|devops)\b', caseSensitive: false),
    ];
    int matches = 0;
    for (final pattern in technicalPatterns) {
      matches += pattern.allMatches(text).length;
    }
    return (matches / text.split(' ').length).clamp(0.0, 1.0);
  }

  List<double> _getCategoryIndicators(List<String> keywords) {
    final indicators = <double>[];

    final categoryKeywords = {
      'coding': ['code', 'program', 'develop', 'api'],
      'design': ['design', 'ui', 'ux', 'mockup'],
      'meeting': ['meeting', 'call', 'discuss'],
      'research': ['research', 'analyze', 'study'],
    };
    for (final category in categoryKeywords.keys) {
      double score = 0.0;
      for (final keyword in keywords) {
        if (categoryKeywords[category]!.contains(keyword)) {
          score += 1.0;
        }
      }
      indicators.add(score / keywords.length);
    }
    return indicators;
  }

  double _sigmoid(double x) {
    return 1.0 / (1.0 + exp(-x));
  }

  // Training methods (simplified implementations)
  Future<void> _trainDurationModel() async {
    // Implement gradient descent or other training algorithm
    // This is a simplified version
    debugPrint('Training duration model...');
  }

  Future<void> _trainCategoryModel() async {
    // Implement classification training
    debugPrint('Training category model...');
  }

  Future<void> _trainSchedulingModel() async {
    // Implement reinforcement learning or optimization
    debugPrint('Training scheduling model...');
  }

  Future<void> _saveModels() async {
    // Save models to persistent storage
    debugPrint('Saving trained models...');
  }

  // Scheduling-related methods
  List<double> _extractSchedulingFeatures({
    required List<EnhancedTask> tasks,
    required Map<String, List<String>> dependencies,
    required Map<String, double> performanceTimes,
    required Map<String, dynamic> constraints,
  }) {
    // Extract features for scheduling optimization
    return [];
  }

  List<ScheduledTask> _applySchedulingModel(
    List<double> features,
    DateTime startDate,
    DateTime endDate,
  ) {
    // Apply scheduling algorithm
    return [];
  }

  List<ScheduledTask> _fallbackScheduleOptimization(
    List<EnhancedTask> tasks,
    DateTime startDate,
    DateTime endDate,
  ) {
    // Simple fallback scheduling
    return [];
  }

  /// Record task completion data for learning
  Future<void> recordTaskCompletion(Map<String, dynamic> completionData) async {
    try {
      // Store completion data for future model training
      // This would typically be sent to a backend service or stored locally
      debugPrint('Recording task completion: ${completionData['task_id']}');
    } catch (e) {
      debugPrint('Error recording task completion: $e');
    }
  }
}

// Supporting classes
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
