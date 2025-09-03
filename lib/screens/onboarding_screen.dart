import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Welcome to ProPlanet',
      description: 'Join millions of eco-warriors making a difference, one action at a time.',
      icon: Icons.eco,
      color: Color(0xFF4CAF50),
    ),
    OnboardingData(
      title: 'Track Your Impact',
      description: 'Monitor your eco-friendly activities and see the real impact you\'re making on our planet.',
      icon: Icons.trending_up,
      color: Color(0xFF2196F3),
    ),
    OnboardingData(
      title: 'Earn Rewards',
      description: 'Complete activities, earn points, unlock badges, and level up your eco game!',
      icon: Icons.emoji_events,
      color: Color(0xFFFF9800),
    ),
    OnboardingData(
      title: 'Stay Motivated',
      description: 'Get personalized notifications and tips to keep your eco journey on track.',
      icon: Icons.notifications_active,
      color: Color(0xFF9C27B0),
    ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _showUserSetupDialog();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showUserSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Let\'s Get Started!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (Optional)',
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: _completeOnboarding,
            child: const Text('Start Journey'),
          ),
        ],
      ),
    );
  }

  void _completeOnboarding() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    Navigator.of(context).pop(); // Close dialog

    // Create user
    final user = User(
      id: 'user_',
      name: name,
      email: _emailController.text.trim(),
      joinDate: DateTime.now(),
      totalPoints: 0,
      level: 1,
      badges: [],
      categoryPoints: {},
    );

    // Update user provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.updateUser(user);

    // Navigate to home
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () => _showUserSetupDialog(),
                  child: const Text('Skip'),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: page.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: Icon(
                            page.icon,
                            size: 60,
                            color: page.color,
                          ),
                        ).animate()
                          .scale(duration: 600.ms, curve: Curves.elasticOut),

                        const SizedBox(height: 40),

                        // Title
                        Text(
                          page.title,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: page.color,
                          ),
                          textAlign: TextAlign.center,
                        ).animate()
                          .fadeIn(delay: 200.ms, duration: 600.ms)
                          .slideY(begin: 0.3, end: 0),

                        const SizedBox(height: 20),

                        // Description
                        Text(
                          page.description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ).animate()
                          .fadeIn(delay: 400.ms, duration: 600.ms)
                          .slideY(begin: 0.3, end: 0),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ).animate()
              .fadeIn(delay: 600.ms, duration: 400.ms),

            const SizedBox(height: 40),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
                  _currentPage > 0
                      ? TextButton(
                          onPressed: _previousPage,
                          child: const Text('Previous'),
                        )
                      : const SizedBox(width: 80),

                  // Next/Get Started button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                    ),
                  ),
                ],
              ),
            ).animate()
              .fadeIn(delay: 800.ms, duration: 400.ms)
              .slideY(begin: 0.3, end: 0),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
