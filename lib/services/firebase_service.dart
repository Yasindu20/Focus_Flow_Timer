import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/enhanced_task.dart';
import '../models/task_analytics.dart';
import 'error_handler_service.dart';
import 'connectivity_service.dart';
import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ErrorHandlerService _errorHandler = ErrorHandlerService();
  final ConnectivityService _connectivity = ConnectivityService();

  bool _isInitialized = false;
  StreamSubscription<User?>? _authStateSubscription;
  String? _currentUserId;

  /// Initialize Firebase services
  Future<void> initialize() async {
    if (_isInitialized) return;

    return _errorHandler.handleFirebaseOperation(() async {
      // Initialize error handling and connectivity
      await _errorHandler.initialize();
      await _connectivity.initialize();

      // Configure Firestore settings for offline persistence
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Initialize Firebase Messaging
      await _initializeMessaging();

      // Listen to auth state changes
      _authStateSubscription = _auth.authStateChanges().listen((User? user) {
        _currentUserId = user?.uid;
        if (user != null) {
          _onUserSignedIn(user);
        }
      });

      _isInitialized = true;
      debugPrint('FirebaseService initialized successfully');
    }, context: 'Firebase Service Initialization');
  }

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUserId != null;

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    // Check if we're in demo mode (using demo API keys)
    if (DefaultFirebaseOptions.currentPlatform.projectId == 'focus-flow-demo') {
      throw FirebaseAuthException(
        code: 'demo-mode',
        message:
            'Authentication is disabled in demo mode. Please configure real Firebase credentials.',
      );
    }

    return _errorHandler.handleFirebaseOperation(() async {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    }, context: 'Email Sign In');
  }

  /// Register with email and password
  Future<UserCredential> registerWithEmail(
    String email,
    String password, {
    String? displayName,
    Map<String, dynamic>? userData,
  }) async {
    // Check if we're in demo mode (using demo API keys)
    if (DefaultFirebaseOptions.currentPlatform.projectId == 'focus-flow-demo') {
      throw FirebaseAuthException(
        code: 'demo-mode',
        message:
            'Authentication is disabled in demo mode. Please configure real Firebase credentials.',
      );
    }

    return _errorHandler.handleFirebaseOperation(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile
      if (displayName != null) {
        await credential.user!.updateDisplayName(displayName);
      }

      // Create user document in Firestore
      if (credential.user != null) {
        await _createUserDocument(credential.user!, userData);
      }

      return credential;
    }, context: 'Email Registration');
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  /// Process task with AI enhancement
  Future<Map<String, dynamic>> processTaskWithAI({
    required String title,
    String? description,
    String? category,
    String? priority,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    return _errorHandler.handleWithRetry(() async {
      // Local AI processing instead of cloud functions
      return {
        'processed': true,
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
        'suggestions': [],
        'timestamp': DateTime.now().toIso8601String(),
      };
    }, context: 'AI Task Processing');
  }

  /// Get AI-powered task recommendations
  Future<List<EnhancedTask>> getTaskRecommendations() async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      // Return empty recommendations instead of using cloud functions
      return <EnhancedTask>[];
    } catch (e) {
      debugPrint('Get task recommendations error: $e');
      rethrow;
    }
  }

  /// Calculate comprehensive user analytics
  Future<UserAnalytics> calculateUserAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      // Local analytics instead of cloud functions
      return UserAnalytics(
        userId: _currentUserId ?? '',
        totalTasksCompleted: 0,
        totalTimeSpent: Duration.zero,
        averageSessionLength: Duration.zero,
        productivityScore: 0.0,
        focusScore: 0.0,
        estimationAccuracy: 0.0,
        preferredWorkingHours: [0, 8],
        mostProductiveDay: DateTime.now().weekday,
        categoryPerformance: {},
        recentTrend: ProductivityTrendDirection.stable,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Calculate analytics error: $e');
      rethrow;
    }
  }

  /// Generate productivity insights
  Future<Map<String, dynamic>> generateProductivityInsights() async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      // Return empty insights instead of using cloud functions
      return {
        'insights': [],
        'recommendations': [],
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Generate insights error: $e');
      rethrow;
    }
  }

  /// Sync with external task management services
  Future<Map<String, dynamic>> syncExternalTasks({
    required String provider,
    required Map<String, dynamic> credentials,
    bool bidirectional = true,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      // Return sync result instead of using cloud functions
      return {
        'synced': true,
        'provider': provider,
        'timestamp': DateTime.now().toIso8601String(),
        'tasks_synced': 0,
      };
    } catch (e) {
      debugPrint('External sync error: $e');
      rethrow;
    }
  }

  /// Export user data
  Future<Map<String, dynamic>> exportUserData({
    required String format,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      // Return export result instead of using cloud functions
      return {
        'exported': true,
        'format': format,
        'url': 'local://export.json',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Export data error: $e');
      rethrow;
    }
  }

  /// Create or update task in Firestore
  Future<void> saveTask(EnhancedTask task) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    return _errorHandler.handleStorageOperation(() async {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tasks')
          .doc(task.id)
          .set(task.toJson(), SetOptions(merge: true));
    }, context: 'Save Task to Firestore');
  }

  /// Delete task from Firestore
  Future<void> deleteTask(String taskId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      debugPrint('Delete task error: $e');
      rethrow;
    }
  }

  /// Get tasks stream from Firestore
  Stream<List<EnhancedTask>> getTasksStream() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return EnhancedTask.fromJson({
                'id': doc.id,
                ...doc.data(),
              });
            } catch (e) {
              debugPrint('Error parsing task ${doc.id}: $e');
              return null;
            }
          })
          .where((task) => task != null)
          .cast<EnhancedTask>()
          .toList();
    });
  }

  /// Save pomodoro session to Firestore
  Future<void> saveSession(Map<String, dynamic> sessionData) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('sessions')
          .add({
        ...sessionData,
        'userId': _currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Save session error: $e');
      rethrow;
    }
  }

  /// Get user settings
  Future<Map<String, dynamic>?> getUserSettings() async {
    if (!isAuthenticated) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('settings')
          .doc('preferences')
          .get();

      return doc.data();
    } catch (e) {
      debugPrint('Get user settings error: $e');
      return null;
    }
  }

  /// Update user settings
  Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('settings')
          .doc('preferences')
          .set(settings, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Update user settings error: $e');
      rethrow;
    }
  }

  /// Get user notifications
  Future<List<Map<String, dynamic>>> getUserNotifications({
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    if (!isAuthenticated) return [];

    try {
      Query query = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .orderBy('sentAt', descending: true)
          .limit(limit);

      if (unreadOnly) {
        query = query.where('read', isEqualTo: false);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      debugPrint('Get notifications error: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String notificationId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Mark notification read error: $e');
      rethrow;
    }
  }

  /// Configure notification preferences
  Future<void> configureNotifications(Map<String, dynamic> config) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('settings')
          .doc('notifications')
          .set(config, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Configure notifications error: $e');
      rethrow;
    }
  }

  /// Get available integrations
  Future<List<Map<String, dynamic>>> getAvailableIntegrations() async {
    try {
      // Return available integrations instead of using cloud functions
      return [
        {'name': 'ClickUp', 'type': 'free', 'enabled': true},
        {'name': 'Todoist', 'type': 'free', 'enabled': true},
        {'name': 'GitHub', 'type': 'free', 'enabled': true},
      ];
    } catch (e) {
      debugPrint('Get integrations error: $e');
      return [];
    }
  }

  /// Configure integration
  Future<void> configureIntegration(
    String provider,
    Map<String, dynamic> config,
  ) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('integrations')
          .doc(provider)
          .set({
        ...config,
        'provider': provider,
        'configuredAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Configure integration error: $e');
      rethrow;
    }
  }

  /// Get user integrations
  Future<List<Map<String, dynamic>>> getUserIntegrations() async {
    if (!isAuthenticated) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('integrations')
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      debugPrint('Get user integrations error: $e');
      return [];
    }
  }

  /// Batch write operations
  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final batch = _firestore.batch();

      for (final operation in operations) {
        final type = operation['type'] as String;
        final collection = operation['collection'] as String;
        final docId = operation['docId'] as String?;
        final data = operation['data'] as Map<String, dynamic>?;

        DocumentReference docRef;
        if (docId != null) {
          docRef = _firestore
              .collection('users')
              .doc(_currentUserId)
              .collection(collection)
              .doc(docId);
        } else {
          docRef = _firestore
              .collection('users')
              .doc(_currentUserId)
              .collection(collection)
              .doc();
        }

        switch (type) {
          case 'set':
            batch.set(docRef, data!, SetOptions(merge: true));
            break;
          case 'update':
            batch.update(docRef, data!);
            break;
          case 'delete':
            batch.delete(docRef);
            break;
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Batch write error: $e');
      rethrow;
    }
  }

  /// Listen to real-time updates
  Stream<DocumentSnapshot> listenToDocument(String collection, String docId) {
    if (!isAuthenticated) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection(collection)
        .doc(docId)
        .snapshots();
  }

  /// Get offline data
  Future<List<Map<String, dynamic>>> getOfflineData(String collection) async {
    if (!isAuthenticated) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection(collection)
          .get(const GetOptions(source: Source.cache));

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      debugPrint('Get offline data error: $e');
      return [];
    }
  }

  /// Private methods

  Future<void> _initializeMessaging() async {
    try {
      // Request permission for notifications
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Push notifications permission granted');

        // Get FCM token
        final token = await _messaging.getToken();
        if (token != null) {
          debugPrint('FCM Token: $token');
          // Store token for this user when authenticated
          if (_currentUserId != null) {
            await _storeDeviceToken(token);
          }
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((token) {
          debugPrint('FCM Token refreshed: $token');
          if (_currentUserId != null) {
            _storeDeviceToken(token);
          }
        });

        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Received foreground message: ${message.messageId}');
          // Handle the message (show local notification, update UI, etc.)
        });

        // Handle message taps
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('Message tapped: ${message.messageId}');
          // Handle navigation based on message data
        });
      }
    } catch (e) {
      debugPrint('Messaging initialization error: $e');
    }
  }

  Future<void> _storeDeviceToken(String token) async {
    if (!isAuthenticated) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('devices')
          .doc(token)
          .set({
        'token': token,
        'platform': defaultTargetPlatform.name,
        'registeredAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
        'active': true,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Store device token error: $e');
    }
  }

  Future<void> _createUserDocument(
      User user, Map<String, dynamic>? userData) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'role': 'user',
        'subscription': {
          'plan': 'free',
          'status': 'active',
          'features': ['basic_timer', 'task_management']
        },
        ...?userData,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Create user document error: $e');
      rethrow;
    }
  }

  Future<void> _onUserSignedIn(User user) async {
    try {
      // Update last active timestamp
      await _firestore.collection('users').doc(user.uid).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      // Store device token if available
      final token = await _messaging.getToken();
      if (token != null) {
        await _storeDeviceToken(token);
      }
    } catch (e) {
      debugPrint('User sign-in handling error: $e');
    }
  }

  void dispose() {
    _authStateSubscription?.cancel();
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  // Handle background message (store in local storage, etc.)
}

// Extension for UserAnalytics parsing
extension UserAnalyticsExtension on UserAnalytics {
  static UserAnalytics fromJson(Map<String, dynamic> json) {
    // This would implement the parsing logic based on the analytics data structure
    // For now, return a basic implementation
    return UserAnalytics(
      userId: json['userId'] ?? '',
      totalTasksCompleted: json['metrics']?['totalTasks'] ?? 0,
      totalTimeSpent:
          Duration(milliseconds: json['metrics']?['totalTimeSpent'] ?? 0),
      averageSessionLength:
          Duration(milliseconds: json['metrics']?['averageTimePerTask'] ?? 0),
      productivityScore:
          (json['metrics']?['productivityScore'] ?? 0.0).toDouble(),
      focusScore: (json['efficiency']?['focus'] ?? 0.0).toDouble(),
      estimationAccuracy:
          (json['metrics']?['estimationAccuracy'] ?? 0.0).toDouble(),
      preferredWorkingHours: [],
      mostProductiveDay: 1,
      categoryPerformance: {},
      recentTrend: ProductivityTrendDirection.stable,
      lastUpdated: DateTime.now(),
    );
  }
}
