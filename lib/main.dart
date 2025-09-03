import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/activities_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/profile_screen.dart';
import 'providers/user_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/notification_provider.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  runApp(const ProPlanetApp());
}

class ProPlanetApp extends StatelessWidget {
  const ProPlanetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'ProPlanet',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/home': (context) => const HomeScreen(),
          '/activities': (context) => const ActivitiesScreen(),
          '/leaderboard': (context) => const LeaderboardScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}
