import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/enhanced_task.dart';
import '../models/pomodoro_session.dart';
import '../models/daily_stats.dart';
import '../models/task_analytics.dart';
import '../models/ai_insights.dart';
import '../firebase_options.dart';

/// Enterprise-grade Firebase service for Focus Flow Timer
/// Handles all backend operations including authentication, database, analytics, and AI
class FirebaseService extends ChangeNotifier {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  late FirebaseFunctions _functions;
  late FirebaseStorage _storage;
  late FirebaseAnalytics _analytics;
  late FirebasePerformance _performance;
  late FirebaseMessaging _messaging;
  late FirebaseCrashlytics _crashlytics;
  late RemoteConfig _remoteConfig;

  // State management
  bool _isInitialized = false;
  bool _isOnline = true;
  User? _currentUser;
  StreamSubscription<User?>? _authStateSubscription;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  // Cache for offline functionality
  final Map<String, dynamic> _cache = {};
  final List<Map<String, dynamic>> _pendingOperations = [];

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isOnline => _isOnline;
  User? get currentUser => _currentUser;
  String? get userId => _currentUser?.uid;
  bool get isAuthenticated => _currentUser != null;

  /// Initialize Firebase services and set up enterprise features
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize all Firebase services
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _functions = FirebaseFunctions.instance;
      _storage = FirebaseStorage.instance;
      _analytics = FirebaseAnalytics.instance;
      _performance = FirebasePerformance.instance;
      _messaging = FirebaseMessaging.instance;
      _crashlytics = FirebaseCrashlytics.instance;
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Configure Firestore settings for optimal performance
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        ignoreUndefinedProperties: false,
      );

      // Configure Remote Config
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // Set up connectivity monitoring
      _connectivitySubscription = Connectivity()
          .onConnectivityChanged
          .listen(_onConnectivityChanged);

      // Set up authentication state listener
      _authStateSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);

      // Configure crash reporting in release mode
      if (kReleaseMode) {
        FlutterError.onError = _crashlytics.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          _crashlytics.recordError(error, stack, fatal: true);
          return true;
        };
      }

      // Initialize push notifications
      await _initializePushNotifications();

      // Fetch remote configuration
      await _fetchRemoteConfig();

      _isInitialized = true;
      debugPrint('🚀 Firebase Service initialized successfully');
      
      // Process any pending offline operations
      await _processPendingOperations();
      
    } catch (e, stack) {
      debugPrint('❌ Firebase initialization failed: $e');
      await _crashlytics.recordError(e, stack);
      rethrow;
    }
  }

  /// Authentication Methods

  /// Sign up with email and password
  Future<UserCredential> signUpWithEmailPassword(
    String email, 
    String password, {
    String? displayName,
  }) async {
    try {
      final trace = _performance.newTrace('auth_signup');
      await trace.start();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (displayName != null) {
        await credential.user?.updateDisplayName(displayName);
      }

      // Create user profile in Firestore
      await _createUserProfile(credential.user!);

      await trace.stop();
      
      await _analytics.logSignUp(signUpMethod: 'email');
      debugPrint('✅ User signed up successfully');
      
      return credential;
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack);
      debugPrint('❌ Sign up failed: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      final trace = _performance.newTrace('auth_signin');
      await trace.start();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await trace.stop();
      
      await _analytics.logLogin(loginMethod: 'email');
      debugPrint('✅ User signed in successfully');
      
      return credential;
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack);
      debugPrint('❌ Sign in failed: $e');
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _analytics.logEvent(name: 'user_signout');
      debugPrint('✅ User signed out successfully');
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack);
      debugPrint('❌ Sign out failed: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('✅ Password reset email sent');
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack);
      debugPrint('❌ Password reset failed: $e');
      rethrow;
    }
  }

  /// Task Management Methods

  /// Create a new enhanced task with AI processing
  Future<String> createEnhancedTask(EnhancedTask task) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final trace = _performance.newTrace('create_task');
      await trace.start();

      // Process task with AI if online
      if (_isOnline) {
        final aiResult = await _processTaskWithAI(task);
        task = task.copyWith(aiData: aiResult);
      }

      final taskRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(task.id);

      await taskRef.set(task.toMap());

      // Update analytics
      await _updateTaskAnalytics('task_created', task);

      await trace.stop();
      
      await _analytics.logEvent(
        name: 'task_created',
        parameters: {
          'category': task.category.name,
          'priority': task.priority.name,
          'estimated_duration': task.estimatedDuration.inMinutes,
        },
      );

      debugPrint('✅ Enhanced task created: ${task.title}');
      return task.id;
      
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack);
      
      // Add to pending operations if offline
      if (!_isOnline) {
        _pendingOperations.add({
          'operation': 'create_task',
          'data': task.toMap(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
      
      debugPrint('❌ Create task failed: $e');
      rethrow;
    }
  }

  /// Get user's tasks with real-time updates
  Stream<List<EnhancedTask>> getUserTasks() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EnhancedTask.fromMap(doc.data()))
          .toList();
    }).handleError((error, stack) {
      _crashlytics.recordError(error, stack);
      debugPrint('❌ Get tasks failed: $error');
    });
  }

  /// Update existing task
  Future<void> updateTask(EnhancedTask task) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final taskRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(task.id);

      await taskRef.update(task.toMap());

      await _analytics.logEvent(
        name: 'task_updated',
        parameters: {'task_id': task.id},
      );

      debugPrint('✅ Task updated: ${task.title}');
      
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack);
      debugPrint('❌ Update task failed: $e');
      rethrow;
    }
  }

  /// Delete task
  Future<void> deleteTask(String taskId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .delete();

      await _analytics.logEvent(
        name: 'task_deleted',
        parameters: {'task_id': taskId},
      );

      debugPrint('✅ Task deleted: $taskId');
      
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack);
      debugPrint('❌ Delete task failed: $e');
      rethrow;
    }
  }

  /// Session Management Methods

  /// Create Pomodoro session
  Future<void> createPomodoroSession(PomodoroSession session) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final sessionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .doc(session.id);

      await sessionRef.set(session.toMap());

      // Update task progress
      if (session.taskId != null) {
        await _updateTaskProgress(session.taskId!, session);
      }

      // Update daily stats
      await _updateDailyStats(session);

      await _analytics.logEvent(
        name: 'pomodoro_session_completed',
        parameters: {
          'duration_minutes': session.duration.inMinutes,
          'session_type': session.sessionType.name,
          'interruptions': session.interruptions,
        },
      );

      debugPrint('✅ Pomodoro session created');
      
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack);
      debugPrint('❌ Create session failed: $e');
      rethrow;
    }
  }

  /// Get user's sessions
  Stream<List<PomodoroSession>> getUserSessions({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (!isAuthenticated) {
      return Stream.value([]);
    }

    Query query = _firestore
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .orderBy('createdAt', descending: true);

    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
    }

    if (endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: endDate);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => PomodoroSession.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Analytics Methods

  /// Get comprehensive user analytics
  Future<UserAnalytics> getUserAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final trace = _performance.newTrace('get_user_analytics');
      await trace.start();

      // Use Cloud Function for complex analytics calculation
      final result = await _functions
          .httpsCallable('calculateUserAnalytics')
          .call({
        'userId': userId,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      });

      await trace.stop();

      return UserAnalytics.fromMap(result.data);
      
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack);
      debugPrint('❌ Get analytics failed: $e');
      rethrow;
    }
  }

  /// Get productivity insights using AI
  Future<ProductivityInsights> getProductivityInsights() async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final result = await _functions
          .httpsCallable('generateProductivityInsights')
          .call({'userId': userId});

      return ProductivityInsights.fromMap(result.data);
      
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack);
      debugPrint('❌ Get insights failed: $e');
      rethrow;
    }
  }

  /// AI Integration Methods

  /// Process task with AI for enhanced features
  Future<TaskAIData> _processTaskWithAI(EnhancedTask task) async {
    try {
      final result = await _functions
          .httpsCallable('processTaskWithAI')
          .call({
        'title': task.title,
        'description': task.description,
        'category': task.category.name,
        'priority': task.priority.name,
        'userId': userId,
      });

      return TaskAIData.fromMap(result.data);
      
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack);
      debugPrint('❌ AI processing failed: $e');
      
      // Return default AI data if processing fails
      return TaskAIData(
        estimatedDuration: const Duration(minutes: 25),
        complexityScore: 0.5,
        tags: [],
        suggestedTimeSlots: [],
        optimizationTips: [],
      );
    }
  }

  /// Get AI-powered task recommendations
  Future<List<EnhancedTask>> getTaskRecommendations() async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final result = await _functions
          .httpsCallable('getTaskRecommendations')
          .call({'userId': userId});

      return (result.data as List)
          .map((data) => EnhancedTask.fromMap(data))
          .toList();
          
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack);
      debugPrint('❌ Get recommendations failed: $e');
      return [];
    }
  }

  /// Third-party Integration Methods

  /// Sync with external services (Jira, Asana, etc.)
  Future<Map<String, dynamic>> syncWithExternalService({
    required String provider,
    required Map<String, dynamic> credentials,
    bool bidirectional = true,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final result = await _functions
          .httpsCallable('syncExternalTasks')
          .call({
        'userId': userId,
        'provider': provider,
        'credentials': credentials,
        'bidirectional': bidirectional,
      });

      await _analytics.logEvent(
        name: 'external_sync_completed',
        parameters: {
          'provider': provider,
          'bidirectional': bidirectional,
        },
      );

      return result.data;
      
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack);
      debugPrint('❌ External sync failed: $e');
      rethrow;
    }
  }

  /// Export data to various formats
  Future<String> exportUserData({
    required String format, // 'json', 'csv', 'xlsx'
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final result = await _functions
          .httpsCallable('exportUserData')
          .call({
        'userId': userId,
        'format': format,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      });

      return result.data['downloadUrl'];
      
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack);
      debugPrint('❌ Data export failed: $e');
      rethrow;
    }
  }

  /// Private Helper Methods

  /// Handle authentication state changes
  void _onAuthStateChanged(User? user) {
    _currentUser = user;
    debugPrint('🔐 Auth state changed: ${user?.uid ?? 'null'}');
    notifyListeners();
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;
    
    if (!wasOnline && _isOnline) {
      debugPrint('🌐 Connection restored, processing pending operations');
      _processPendingOperations();
    }
    
    debugPrint('🌐 Connectivity changed: $result (online: $_isOnline)');
    notifyListeners();
  }

  /// Create user profile in Firestore
  Future<void> _createUserProfile(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    
    await userDoc.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
      'preferences': {
        'theme': 'system',
        'notifications': true,
        'soundEnabled': true,
        'defaultPomodoroLength': 25,
        'shortBreakLength': 5,
        'longBreakLength': 15,
      },
      'subscription': {
        'plan': 'free',
        'features': ['basic_timer', 'task_management'],
      },
    });
    
    debugPrint('✅ User profile created for ${user.uid}');
  }

  /// Update task progress based on session completion
  Future<void> _updateTaskProgress(String taskId, PomodoroSession session) async {
    final taskRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId);

    await _firestore.runTransaction((transaction) async {
      final taskDoc = await transaction.get(taskRef);
      if (!taskDoc.exists) return;

      final task = EnhancedTask.fromMap(taskDoc.data()!);
      final updatedTask = task.copyWith(
        completedPomodoros: task.completedPomodoros + 1,
        actualDuration: task.actualDuration + session.duration,
        lastWorkedAt: session.createdAt,
      );

      transaction.update(taskRef, updatedTask.toMap());
    });
  }

  /// Update daily statistics
  Future<void> _updateDailyStats(PomodoroSession session) async {
    final date = DateTime(
      session.createdAt.year,
      session.createdAt.month,
      session.createdAt.day,
    );
    
    final statsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyStats')
        .doc('${date.year}-${date.month}-${date.day}');

    await _firestore.runTransaction((transaction) async {
      final statsDoc = await transaction.get(statsRef);
      
      DailyStats stats;
      if (statsDoc.exists) {
        stats = DailyStats.fromMap(statsDoc.data()!);
      } else {
        stats = DailyStats(
          date: date,
          completedPomodoros: 0,
          totalFocusTime: Duration.zero,
          totalBreakTime: Duration.zero,
          interruptions: 0,
          tasksCompleted: 0,
          averageFocusScore: 0.0,
        );
      }

      final updatedStats = stats.copyWith(
        completedPomodoros: stats.completedPomodoros + 1,
        totalFocusTime: stats.totalFocusTime + session.duration,
        interruptions: stats.interruptions + session.interruptions,
      );

      transaction.set(statsRef, updatedStats.toMap());
    });
  }

  /// Update task-related analytics
  Future<void> _updateTaskAnalytics(String eventType, EnhancedTask task) async {
    // This would be implemented to update various analytics collections
    // for detailed performance tracking
  }

  /// Initialize push notifications
  Future<void> _initializePushNotifications() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final token = await _messaging.getToken();
      if (token != null && isAuthenticated) {
        await _firestore
            .collection('users')
            .doc(userId)
            .update({'fcmToken': token});
      }

      debugPrint('✅ Push notifications initialized');
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack);
      debugPrint('❌ Push notifications setup failed: $e');
    }
  }

  /// Fetch remote configuration
  Future<void> _fetchRemoteConfig() async {
    try {
      await _remoteConfig.fetchAndActivate();
      debugPrint('✅ Remote config fetched successfully');
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack);
      debugPrint('❌ Remote config fetch failed: $e');
    }
  }

  /// Process pending offline operations
  Future<void> _processPendingOperations() async {
    if (_pendingOperations.isEmpty || !_isOnline || !isAuthenticated) return;

    debugPrint('🔄 Processing ${_pendingOperations.length} pending operations');

    final operations = List.from(_pendingOperations);
    _pendingOperations.clear();

    for (final operation in operations) {
      try {
        switch (operation['operation']) {
          case 'create_task':
            final task = EnhancedTask.fromMap(operation['data']);
            await createEnhancedTask(task);
            break;
          // Add other operation types as needed
        }
      } catch (e) {
        debugPrint('❌ Failed to process pending operation: $e');
        // Re-add failed operations to queue
        _pendingOperations.add(operation);
      }
    }

    debugPrint('✅ Processed pending operations');
  }

  /// Cleanup resources
  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}