import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/enhanced_task.dart';

class FreeMlService {
  static final FreeMlService _instance = FreeMlService._internal();
  factory FreeMlService() => _instance;
  FreeMlService._internal();

  // Local ML models and data
  Map<String, dynamic> _localModels = {};
  List<Map<String, dynamic>> _trainingData = [];
  bool _isInitialized = false;

  // Free API configurations
  String? _huggingFaceApiKey;
  final String _huggingFaceBaseUrl = 'https://api-inference.huggingface.co';
  final Map<String, List<DateTime>> _apiCallHistory = {};

  /// Initialize the free ML service
  Future<void> initialize({String? huggingFaceApiKey}) async {
    if (_isInitialized) return;

    try {
      _huggingFaceApiKey = huggingFaceApiKey;
      await _loadLocalModels();
      await _loadTrainingData();
      _isInitialized = true;

      debugPrint('FreeMlService initialized');
    } catch (e) {
      debugPrint('Failed to initialize FreeMlService: $e');
      _initializeEmptyModels();
      _isInitialized = true;
    }
  }

  /// Predict task duration using lightweight local ML
  Future<double> predictDuration({
    required String title,
    required String description,
    required TaskCategory category,
    required TaskPriority priority,
    Map<String, dynamic>? userContext,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      // Extract features for prediction
      final features = _extractDurationFeatures(
        title: title,
        description: description,
        category: category,
        priority: priority,
        userContext: userContext ?? {},
      );

      // Use local lightweight model
      final prediction = _applyLocalDurationModel(features);

      // Store for future training
      await _recordPrediction('duration', features, prediction);

      return prediction;
    } catch (e) {
      debugPrint('Error in duration prediction: $e');
      return _fallbackDurationPrediction(category, 0.5);
    }
  }

  /// Analyze task content using free NLP APIs and local processing
  Future<Map<String, dynamic>> analyzeTaskContent(
    String title,
    String description,
  ) async {
    try {
      final fullText = '$title $description';

      // Primary: Local text analysis (always available)
      final localAnalysis = await _analyzeTextLocally(fullText);

      // Secondary: Try free API if available and within limits
      Map<String, dynamic>? apiAnalysis;
      if (_huggingFaceApiKey != null && await _checkApiLimit('huggingface')) {
        try {
          apiAnalysis = await _analyzeWithHuggingFace(fullText);
        } catch (e) {
          debugPrint('HuggingFace API failed, using local analysis: $e');
        }
      }

      // Combine results, preferring API results when available
      return {
        'keywords': apiAnalysis?['keywords'] ?? localAnalysis['keywords'],
        'intent': apiAnalysis?['intent'] ?? localAnalysis['intent'],
        'sentiment': apiAnalysis?['sentiment'] ?? localAnalysis['sentiment'],
        'entities': apiAnalysis?['entities'] ?? localAnalysis['entities'],
        'complexity_indicators': localAnalysis['complexity_indicators'],
        'token_count': localAnalysis['token_count'],
        'unique_token_count': localAnalysis['unique_token_count'],
        'analysis_source': apiAnalysis != null ? 'api_enhanced' : 'local',
      };
    } catch (e) {
      debugPrint('Error in task content analysis: $e');
      return _fallbackContentAnalysis(title, description);
    }
  }

  /// Classify task category using local ML
  Future<Map<String, double>> classifyTaskCategory({
    required String title,
    required String description,
    required List<String> keywords,
    required String intent,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Extract features
      final features = _extractCategoryFeatures(
        title: title,
        description: description,
        keywords: keywords,
        intent: intent,
        metadata: metadata,
      );

      // Apply local classification model
      final probabilities = _applyLocalCategoryModel(features);

      // Store for training
      await _recordPrediction('category', features, probabilities);

      return probabilities;
    } catch (e) {
      debugPrint('Error in category classification: $e');
      return _fallbackCategoryClassification(keywords);
    }
  }

  /// Simple task scheduling optimization using local algorithms
  Future<List<ScheduledTask>> optimizeSchedule({
    required List<EnhancedTask> tasks,
    required Map<String, List<String>> dependencies,
    required Map<String, double> performanceTimes,
    required Map<String, dynamic> constraints,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Use priority-based scheduling with dependency resolution
      final scheduledTasks = <ScheduledTask>[];
      final availableTime = startDate;
      var currentTime = availableTime;

      // Sort tasks by priority and dependencies
      final sortedTasks =
          _sortTasksForScheduling(tasks, dependencies, performanceTimes);

      for (final task in sortedTasks) {
        final estimatedDuration = await predictDuration(
          title: task.title,
          description: task.description,
          category: task.category,
          priority: task.priority,
        );

        final taskEndTime =
            currentTime.add(Duration(minutes: estimatedDuration.round()));

        // Check if task fits within constraints
        if (taskEndTime.isBefore(endDate)) {
          scheduledTasks.add(ScheduledTask(
            taskId: task.id,
            startTime: currentTime,
            endTime: taskEndTime,
            confidence: _calculateSchedulingConfidence(task, performanceTimes),
          ));

          currentTime =
              taskEndTime.add(const Duration(minutes: 5)); // Buffer time
        }
      }

      return scheduledTasks;
    } catch (e) {
      debugPrint('Error in schedule optimization: $e');
      return _fallbackScheduleOptimization(tasks, startDate, endDate);
    }
  }

  /// Train local models with user data
  Future<void> trainModels(List<Map<String, dynamic>> newData) async {
    try {
      _trainingData.addAll(newData);

      // Simple online learning for local models
      await _updateLocalModels(newData);
      await _saveLocalModels();

      debugPrint('Local ML models updated with ${newData.length} samples');
    } catch (e) {
      debugPrint('Error training models: $e');
    }
  }

  /// Get model performance metrics
  Map<String, dynamic> getModelMetrics() {
    return {
      'duration_model': {
        'type': 'local_linear_regression',
        'training_samples': _trainingData.length,
        'last_updated': _localModels['duration']?['last_updated'] ?? 'Never',
      },
      'category_model': {
        'type': 'local_keyword_matching',
        'training_samples': _trainingData.length,
        'last_updated': _localModels['category']?['last_updated'] ?? 'Never',
      },
      'analysis_sources': {
        'local': 'Always available',
        'huggingface_api': _huggingFaceApiKey != null
            ? 'Available (free tier)'
            : 'Not configured',
      },
      'total_training_data': _trainingData.length,
    };
  }

  // Local text analysis implementation
  Future<Map<String, dynamic>> _analyzeTextLocally(String text) async {
    final tokens = _tokenize(text);
    final processedTokens = _preprocessTokens(tokens);

    return {
      'keywords': _extractKeywords(processedTokens).take(5).toList(),
      'intent': _classifyIntent(processedTokens),
      'sentiment': _analyzeSentiment(processedTokens),
      'entities': _recognizeEntities(processedTokens),
      'complexity_indicators': _identifyComplexityIndicators(processedTokens),
      'token_count': tokens.length,
      'unique_token_count': tokens.toSet().length,
    };
  }

  // HuggingFace API integration (free tier: 1000 requests/month)
  Future<Map<String, dynamic>> _analyzeWithHuggingFace(String text) async {
    if (_huggingFaceApiKey == null) {
      throw Exception('HuggingFace API key not configured');
    }

    final headers = {
      'Authorization': 'Bearer $_huggingFaceApiKey',
      'Content-Type': 'application/json',
    };

    try {
      // Sentiment analysis
      final sentimentResponse = await http.post(
        Uri.parse(
            '$_huggingFaceBaseUrl/models/cardiffnlp/twitter-roberta-base-sentiment-latest'),
        headers: headers,
        body: jsonEncode({'inputs': text}),
      );

      // Text classification for intent (placeholder for future use)

      double sentiment = 0.0;
      if (sentimentResponse.statusCode == 200) {
        final sentimentData = jsonDecode(sentimentResponse.body);
        if (sentimentData is List && sentimentData.isNotEmpty) {
          final scores = sentimentData[0] as List;
          for (final score in scores) {
            if (score['label'] == 'LABEL_2') {
              // Positive
              sentiment += score['score'];
            } else if (score['label'] == 'LABEL_0') {
              // Negative
              sentiment -= score['score'];
            }
          }
        }
      }

      // Record API usage
      _recordApiCall('huggingface');

      return {
        'keywords': _extractKeywords(_preprocessTokens(_tokenize(text)))
            .take(5)
            .toList(),
        'intent': _classifyIntent(_preprocessTokens(_tokenize(text))),
        'sentiment': sentiment,
        'entities': _recognizeEntities(_preprocessTokens(_tokenize(text))),
      };
    } catch (e) {
      debugPrint('HuggingFace API error: $e');
      rethrow;
    }
  }

  // Local ML model implementations
  List<double> _extractDurationFeatures({
    required String title,
    required String description,
    required TaskCategory category,
    required TaskPriority priority,
    required Map<String, dynamic> userContext,
  }) {
    return [
      title.length.toDouble() / 100,
      description.length.toDouble() / 1000,
      _getCategoryEncoding(category),
      _getPriorityEncoding(priority),
      _getWordComplexity(title + description),
      _getTechnicalComplexity(title + description),
      userContext['user_factor']?.toDouble() ?? 1.0,
      userContext['context_factor']?.toDouble() ?? 1.0,
    ];
  }

  double _applyLocalDurationModel(List<double> features) {
    final weights = _localModels['duration']?['weights'] as List<double>? ??
        [25.0, 15.0, 10.0, 8.0, 12.0, 20.0, 5.0, 5.0]; // Default weights

    double prediction = 25.0; // Base duration

    for (int i = 0; i < features.length && i < weights.length; i++) {
      prediction += features[i] * weights[i];
    }

    return prediction.clamp(5.0, 240.0); // 5 minutes to 4 hours
  }

  List<double> _extractCategoryFeatures({
    required String title,
    required String description,
    required List<String> keywords,
    required String intent,
    Map<String, dynamic>? metadata,
  }) {
    final features = <double>[
      title.length.toDouble() / 100,
      description.length.toDouble() / 1000,
      keywords.length.toDouble() / 10,
      _getIntentEncoding(intent),
    ];

    // Add keyword-based category indicators
    features.addAll(_getCategoryIndicators(keywords));

    return features;
  }

  Map<String, double> _applyLocalCategoryModel(List<double> features) {
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

    // Simple rule-based classification based on features
    for (int i = 0; i < categories.length; i++) {
      double score = 0.1; // Base score

      // Feature-based scoring
      if (i < features.length) {
        score += features[i] * 0.5;
      }

      // Keyword-based adjustments
      if (features.length > 4) {
        final keywordScore = features.sublist(4).reduce((a, b) => a + b);
        score += keywordScore * 0.3;
      }

      probabilities[categories[i]] = score;
    }

    // Normalize probabilities
    final total = probabilities.values.reduce((a, b) => a + b);
    if (total > 0) {
      probabilities.updateAll((key, value) => value / total);
    }

    return probabilities;
  }

  List<EnhancedTask> _sortTasksForScheduling(
    List<EnhancedTask> tasks,
    Map<String, List<String>> dependencies,
    Map<String, double> performanceTimes,
  ) {
    final sortedTasks = <EnhancedTask>[];
    final processed = <String>{};
    final remaining = List<EnhancedTask>.from(tasks);

    while (remaining.isNotEmpty) {
      // Find tasks with no unprocessed dependencies
      final readyTasks = remaining.where((task) {
        final taskDeps = dependencies[task.id] ?? [];
        return taskDeps.every((dep) => processed.contains(dep));
      }).toList();

      if (readyTasks.isEmpty) {
        // Add remaining tasks anyway to avoid infinite loop
        sortedTasks.addAll(remaining);
        break;
      }

      // Sort ready tasks by priority and performance
      readyTasks.sort((a, b) {
        final priorityCompare = b.priority.index.compareTo(a.priority.index);
        if (priorityCompare != 0) return priorityCompare;

        final perfA = performanceTimes[a.category.name] ?? 1.0;
        final perfB = performanceTimes[b.category.name] ?? 1.0;
        return perfA.compareTo(perfB);
      });

      final nextTask = readyTasks.first;
      sortedTasks.add(nextTask);
      remaining.remove(nextTask);
      processed.add(nextTask.id);
    }

    return sortedTasks;
  }

  double _calculateSchedulingConfidence(
    EnhancedTask task,
    Map<String, double> performanceTimes,
  ) {
    final categoryPerformance = performanceTimes[task.category.name] ?? 0.5;
    final priorityFactor = task.priority.index / 4.0;
    return (categoryPerformance + priorityFactor) / 2.0;
  }

  // Training and model persistence
  Future<void> _updateLocalModels(List<Map<String, dynamic>> newData) async {
    // Simple online learning: adjust weights based on feedback
    for (final data in newData) {
      if (data['type'] == 'duration' && data['actual_duration'] != null) {
        _adjustDurationModel(data);
      }
    }
  }

  void _adjustDurationModel(Map<String, dynamic> data) {
    final predicted = data['predicted_duration']?.toDouble() ?? 0.0;
    final actual = data['actual_duration']?.toDouble() ?? 0.0;
    final features = data['features'] as List<double>? ?? [];

    if (features.isEmpty) return;

    final error = actual - predicted;
    const learningRate = 0.01;

    // Update weights
    final weights = _localModels['duration']?['weights'] as List<double>? ??
        List.filled(features.length, 1.0);

    for (int i = 0; i < features.length && i < weights.length; i++) {
      weights[i] += learningRate * error * features[i];
    }

    _localModels['duration'] = {
      'weights': weights,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _loadLocalModels() async {
    final prefs = await SharedPreferences.getInstance();
    final modelsJson = prefs.getString('ml_local_models') ?? '{}';
    _localModels = jsonDecode(modelsJson);

    if (_localModels.isEmpty) {
      _initializeEmptyModels();
    }
  }

  Future<void> _saveLocalModels() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ml_local_models', jsonEncode(_localModels));
  }

  Future<void> _loadTrainingData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataJson = prefs.getString('ml_training_data') ?? '[]';
    _trainingData = List<Map<String, dynamic>>.from(jsonDecode(dataJson));
  }

  void _initializeEmptyModels() {
    _localModels = {
      'duration': {
        'weights': [25.0, 15.0, 10.0, 8.0, 12.0, 20.0, 5.0, 5.0],
        'last_updated': DateTime.now().toIso8601String(),
      },
      'category': {
        'rules': _getDefaultCategoryRules(),
        'last_updated': DateTime.now().toIso8601String(),
      },
    };
  }

  Map<String, List<String>> _getDefaultCategoryRules() {
    return {
      'coding': ['code', 'program', 'develop', 'implement', 'api', 'function'],
      'writing': ['write', 'document', 'content', 'article', 'blog'],
      'meeting': ['meeting', 'call', 'discuss', 'conference'],
      'research': ['research', 'analyze', 'study', 'investigate'],
      'design': ['design', 'ui', 'ux', 'mockup', 'wireframe'],
      'planning': ['plan', 'strategy', 'roadmap', 'schedule'],
      'review': ['review', 'check', 'verify', 'audit'],
      'testing': ['test', 'qa', 'bug', 'quality'],
      'documentation': ['document', 'wiki', 'guide', 'manual'],
      'communication': ['email', 'message', 'contact', 'notify'],
    };
  }

  // API rate limiting
  Future<bool> _checkApiLimit(String provider) async {
    final now = DateTime.now();
    _apiCallHistory[provider] ??= [];

    // Remove calls older than 30 days (monthly limit)
    _apiCallHistory[provider]!.removeWhere(
      (time) => now.difference(time).inDays >= 30,
    );

    // Check monthly limits
    final monthlyLimits = {
      'huggingface': 1000, // Free tier limit
    };

    final limit = monthlyLimits[provider] ?? 100;
    return _apiCallHistory[provider]!.length < limit;
  }

  void _recordApiCall(String provider) {
    _apiCallHistory[provider] ??= [];
    _apiCallHistory[provider]!.add(DateTime.now());
  }

  Future<void> _recordPrediction(
    String type,
    List<double> features,
    dynamic prediction,
  ) async {
    _trainingData.add({
      'type': type,
      'features': features,
      'prediction': prediction,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 1000 records to manage memory
    if (_trainingData.length > 1000) {
      _trainingData = _trainingData.sublist(_trainingData.length - 1000);
    }
  }

  // Helper methods (similar to original but simplified)
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
      'do',
      'does',
      'did',
      'will',
      'would',
      'could',
      'should',
      'can',
      'may',
      'might',
      'must',
      'shall'
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

    final sortedKeywords = keywordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedKeywords.take(10).map((e) => e.key).toList();
  }

  String _classifyIntent(List<String> tokens) {
    final intentMap = {
      'create': ['create', 'build', 'develop', 'implement', 'make', 'design'],
      'update': ['update', 'modify', 'change', 'edit', 'refactor', 'improve'],
      'fix': ['fix', 'repair', 'debug', 'resolve', 'solve', 'correct'],
      'research': ['research', 'investigate', 'study', 'analyze', 'explore'],
      'meeting': ['meeting', 'discuss', 'call', 'conference', 'presentation'],
      'review': ['review', 'check', 'validate', 'verify', 'audit', 'test'],
    };

    for (final intent in intentMap.keys) {
      if (tokens.any((word) => intentMap[intent]!.contains(word))) {
        return intent;
      }
    }
    return 'general';
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
      'dart'
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
    };
  }

  // Encoding and mapping methods
  double _getCategoryEncoding(TaskCategory category) {
    return category.index.toDouble() / TaskCategory.values.length;
  }

  double _getPriorityEncoding(TaskPriority priority) {
    return priority.index.toDouble() / TaskPriority.values.length;
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
    final words = text.split(' ').where((w) => w.isNotEmpty).toList();
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

    final wordCount = text.split(' ').length;
    return wordCount > 0 ? (matches / wordCount).clamp(0.0, 1.0) : 0.0;
  }

  List<double> _getCategoryIndicators(List<String> keywords) {
    final categoryKeywords = _getDefaultCategoryRules();
    final indicators = <double>[];

    for (final category in categoryKeywords.keys) {
      double score = 0.0;
      for (final keyword in keywords) {
        if (categoryKeywords[category]!.contains(keyword)) {
          score += 1.0;
        }
      }
      indicators.add(keywords.isNotEmpty ? score / keywords.length : 0.0);
    }

    return indicators;
  }

  // Fallback methods
  double _fallbackDurationPrediction(
      TaskCategory category, double complexityScore) {
    final baseDurations = {
      TaskCategory.coding: 45.0,
      TaskCategory.writing: 30.0,
      TaskCategory.meeting: 30.0,
      TaskCategory.research: 40.0,
      TaskCategory.design: 35.0,
      TaskCategory.planning: 25.0,
      TaskCategory.review: 20.0,
      TaskCategory.testing: 30.0,
      TaskCategory.documentation: 25.0,
      TaskCategory.communication: 15.0,
    };

    final base = baseDurations[category] ?? 25.0;
    return base * (1.0 + complexityScore * 0.5);
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

  Map<String, double> _fallbackCategoryClassification(List<String> keywords) {
    final categoryKeywords = _getDefaultCategoryRules();
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

    final total = scores.values.reduce((a, b) => a + b);
    if (total > 0) {
      scores.updateAll((key, value) => value / total);
    } else {
      scores.updateAll((key, value) => 1.0 / scores.length);
    }

    return scores;
  }

  List<ScheduledTask> _fallbackScheduleOptimization(
    List<EnhancedTask> tasks,
    DateTime startDate,
    DateTime endDate,
  ) {
    final scheduledTasks = <ScheduledTask>[];
    var currentTime = startDate;

    for (final task in tasks) {
      if (currentTime.isBefore(endDate)) {
        final duration = _fallbackDurationPrediction(task.category, 0.5);
        final endTime = currentTime.add(Duration(minutes: duration.round()));

        scheduledTasks.add(ScheduledTask(
          taskId: task.id,
          startTime: currentTime,
          endTime: endTime,
          confidence: 0.6,
        ));

        currentTime = endTime.add(const Duration(minutes: 5));
      }
    }

    return scheduledTasks;
  }

  /// Record task completion for model improvement
  Future<void> recordTaskCompletion(Map<String, dynamic> completionData) async {
    try {
      await _recordPrediction('completion', [], completionData);
      debugPrint('Task completion recorded for learning');
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
