import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../providers/admin_provider.dart';
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
        await Provider.of<ActivityProvider>(
          context,
          listen: false,
        ).initializeActivities();
        await Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).initializeNotifications();
      }

      // Wait for minimum splash duration
      await Future.delayed(const Duration(seconds: 3));

      // Navigate to appropriate screen
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        if (authProvider.isAuthenticated && authProvider.currentUser != null) {
          // Check if user is admin
          final adminProvider = Provider.of<AdminProvider>(context, listen: false);
          final isAdmin = await adminProvider.checkAdminStatus(
            authProvider.currentUser!.id,
          );

          if (isAdmin) {
            Navigator.of(context).pushReplacementNamed('/admin');
          } else {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } else {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');
      // Navigate to login on error
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4CAF50),
              Color(0xFF2E7D32),
              Color(0xFF1B5E20),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo/Icon with enhanced animation
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.eco,
                    size: 70,
                    color: Color(0xFF4CAF50),
                  ),
                )
                    .animate()
                    .scale(
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                    )
                    .then(delay: 300.ms)
                    .shimmer(
                      duration: 1500.ms,
                      color: Colors.white.withValues(alpha: 0.3),
                    )
                    .then(delay: 500.ms)
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.1, 1.1),
                      duration: 1000.ms,
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .scale(
                      begin: const Offset(1.1, 1.1),
                      end: const Offset(1.0, 1.0),
                      duration: 1000.ms,
                      curve: Curves.easeInOut,
                    ),

                const SizedBox(height: 40),

                // App Name with enhanced styling
                Text(
                  'ProPlanet',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 42,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 800.ms)
                    .slideY(begin: 0.5, end: 0, curve: Curves.easeOutBack),

                const SizedBox(height: 15),

                // App Tagline with enhanced styling
                Text(
                  'Make Every Action Count',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                    letterSpacing: 1,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 800.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack),

                const SizedBox(height: 80),

                // Enhanced Loading Indicator
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 4,
                  ),
                ).animate().fadeIn(delay: 1000.ms, duration: 600.ms),

                const SizedBox(height: 30),

                // Loading Text with animation
                Text(
                  'Initializing your eco journey...',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                )
                    .animate()
                    .fadeIn(delay: 1200.ms, duration: 600.ms)
                    .then(delay: 200.ms)
                    .shimmer(
                      duration: 2000.ms,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),

                const SizedBox(height: 20),

                // Progress dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .fadeIn(
                          delay: (1400 + (index * 200)).ms,
                          duration: 400.ms,
                        )
                        .then(delay: (index * 200).ms)
                        .fadeOut(duration: 400.ms)
                        .then(delay: 400.ms)
                        .fadeIn(duration: 400.ms);
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
