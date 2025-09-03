import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/notification_provider.dart';
import '../services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize notification service
      await NotificationService().initialize();
      await NotificationService().requestPermissions();

      // Initialize providers
      if (mounted) {
        await Provider.of<UserProvider>(context, listen: false).initializeUser();
        await Provider.of<ActivityProvider>(context, listen: false).initializeActivities();
        await Provider.of<NotificationProvider>(context, listen: false).initializeNotifications();
      }

      // Wait for minimum splash duration
      await Future.delayed(const Duration(seconds: 2));

      // Navigate to appropriate screen
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        if (userProvider.isLoggedIn) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pushReplacementNamed('/onboarding');
        }
      }
    } catch (e) {
      debugPrint('Error initializing app: ');
      // Navigate to onboarding on error
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.eco,
                  size: 60,
                  color: Color(0xFF4CAF50),
                ),
              ).animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .then(delay: 200.ms)
                .shimmer(duration: 1000.ms),

              const SizedBox(height: 30),

              // App Name
              Text(
                'ProPlanet',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ).animate()
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 10),

              // App Tagline
              Text(
                'Make Every Action Count',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w400,
                ),
              ).animate()
                .fadeIn(delay: 600.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 60),

              // Loading Indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ).animate()
                .fadeIn(delay: 800.ms, duration: 400.ms),

              const SizedBox(height: 20),

              // Loading Text
              Text(
                'Initializing your eco journey...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ).animate()
                .fadeIn(delay: 1000.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
