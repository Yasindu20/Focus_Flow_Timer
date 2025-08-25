import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';

import 'core/theme/app_theme.dart';
import 'services/optimized_storage_service.dart';
import 'services/free_ml_service.dart';
import 'services/free_api_integration_service.dart';
import 'services/offline_pwa_service.dart';
import 'services/notification_manager.dart';
import 'providers/enhanced_timer_provider.dart';
import 'providers/task_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/analytics_dashboard_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/achievement_provider.dart';
import 'providers/productivity_score_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/productivity_score_screen.dart';
import 'screens/leaderboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize optimized storage first (critical for app state)
  try {
    await OptimizedStorageService().initialize();
    debugPrint('Optimized storage service initialized');
  } catch (e) {
    debugPrint('Storage initialization error: $e');
  }

  // Initialize timezone data (safe to do early)
  try {
    tz.initializeTimeZones();
    debugPrint('Timezone data initialized');
  } catch (e) {
    debugPrint('Timezone initialization error: $e');
  }

  // Set preferred orientations (web-safe)
  if (!kIsWeb) {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (e) {
      debugPrint('Orientation setting error: $e');
    }
  }

  // Initialize Firebase (may fail on web due to tracking prevention)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (!kIsWeb) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
    }
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint(
        'Firebase initialization error (this is expected on some browsers): $e');
  }

  // Initialize free services (non-blocking)
  Future.microtask(() async {
    try {
      await FreeMlService().initialize();
      await FreeApiIntegrationService().initialize();
      await OfflinePwaService().initialize();
      await NotificationManager().initialize();
      debugPrint('Free services initialized');
    } catch (e) {
      debugPrint('Free services initialization error: $e');
    }
  });

  runApp(const FocusFlowApp());
}

class FocusFlowApp extends StatelessWidget {
  const FocusFlowApp({super.key}); // Fixed: Using super parameter

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EnhancedTimerProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsDashboardProvider()),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
        ChangeNotifierProvider(create: (_) => ProductivityScoreProvider()),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, child) {
          return MaterialApp(
            title: 'Focus Flow Timer',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: ErrorBoundary(
              child: _getHomeScreen(authProvider),
            ),
            routes: {
              '/auth': (context) => const ErrorBoundary(child: AuthScreen()),
              '/splash': (context) =>
                  const ErrorBoundary(child: SplashScreen()),
              '/main': (context) => const ErrorBoundary(child: MainScreen()),
              '/tasks': (context) => const ErrorBoundary(child: TasksScreen()),
              '/analytics': (context) =>
                  const ErrorBoundary(child: AnalyticsScreen()),
              '/settings': (context) =>
                  const ErrorBoundary(child: SettingsScreen()),
              '/achievements': (context) =>
                  const ErrorBoundary(child: AchievementsScreen()),
              '/productivity': (context) =>
                  const ErrorBoundary(child: ProductivityScoreScreen()),
              '/leaderboard': (context) =>
                  const ErrorBoundary(child: LeaderboardScreen()),
            },
          );
        },
      ),
    );
  }

  Widget _getHomeScreen(AuthProvider authProvider) {
    if (authProvider.isLoading) {
      return const SplashScreen();
    }

    if (authProvider.isAuthenticated) {
      return const MainScreen();
    }

    return const AuthScreen();
  }
}

class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Set up global error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      setState(() {
        _hasError = true;
        _errorMessage = details.exception.toString();
      });
      debugPrint('Flutter Error: ${details.exception}');
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFF667eea),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'We\'re working on fixing this issue. Please try refreshing the page.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _errorMessage = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF667eea),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key}); // Fixed: Using super parameter

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TasksScreen(),
    const AnalyticsScreen(),
    const AchievementsScreen(),
    const ProductivityScoreScreen(),
    const LeaderboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Timer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Awards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Score',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Rankings',
          ),
        ],
      ),
    );
  }
}
