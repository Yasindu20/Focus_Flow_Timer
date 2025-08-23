import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';

import 'core/theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/firebase_service.dart';
import 'providers/enhanced_timer_provider.dart';
import 'providers/smart_task_provider.dart';
import 'providers/firebase_smart_task_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/firebase_analytics_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize Firebase Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Initialize timezone data
  tz.initializeTimeZones();

  // Initialize storage
  await StorageService.initialize();
  
  try {
    // Initialize Firebase services
    await FirebaseService().initialize();
  } catch (e) {
    debugPrint('Firebase Service initialization error: $e');
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
        ChangeNotifierProvider(create: (_) => SmartTaskProvider()),
        ChangeNotifierProvider(create: (_) => FirebaseSmartTaskProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => FirebaseAnalyticsProvider()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, child) {
          return MaterialApp(
            title: 'Focus Flow Timer',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: _getHomeScreen(authProvider),
            routes: {
              '/auth': (context) => const AuthScreen(),
              '/splash': (context) => const SplashScreen(),
              '/tasks': (context) => const TasksScreen(),
              '/analytics': (context) => const AnalyticsScreen(),
              '/settings': (context) => const SettingsScreen(),
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
        ],
      ),
    );
  }
}
