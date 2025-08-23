import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

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
import 'screens/home_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data
  tz.initializeTimeZones();

  // Initialize Firebase services (includes crash reporting)
  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  // Initialize local storage
  await StorageService.init();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(FocusFlowApp(firebaseService: firebaseService));
}

class FocusFlowApp extends StatelessWidget {
  final FirebaseService firebaseService;
  
  const FocusFlowApp({super.key, required this.firebaseService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: firebaseService),
        ChangeNotifierProvider(create: (_) => AuthProvider(firebaseService)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => EnhancedTimerProvider()),
        ChangeNotifierProvider(create: (context) => FirebaseSmartTaskProvider(
          firebaseService: firebaseService,
        )),
        ChangeNotifierProvider(create: (context) => FirebaseAnalyticsProvider(
          firebaseService: firebaseService,
        )),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Focus Flow Timer - Enterprise',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (!firebaseService.isInitialized) {
                  return const SplashScreen();
                }
                
                return authProvider.isAuthenticated 
                    ? const MainScreen() 
                    : const AuthScreen();
              },
            ),
            routes: {
              '/auth': (context) => const AuthScreen(),
              '/main': (context) => const MainScreen(),
              '/tasks': (context) => const TasksScreen(),
              '/analytics': (context) => const AnalyticsScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
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
