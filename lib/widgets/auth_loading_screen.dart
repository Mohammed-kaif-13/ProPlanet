import 'package:flutter/material.dart';
import 'dart:math' as math;

class AuthLoadingScreen extends StatefulWidget {
  final String message;
  final String? subtitle;

  const AuthLoadingScreen({
    super.key,
    required this.message,
    this.subtitle,
  });

  @override
  State<AuthLoadingScreen> createState() => _AuthLoadingScreenState();
}

class _AuthLoadingScreenState extends State<AuthLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _earthController;
  late AnimationController _orbitController;
  late AnimationController _pulseController;
  late AnimationController _textController;

  late Animation<double> _earthRotation;
  late Animation<double> _orbitRotation;
  late Animation<double> _pulseScale;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    // Earth rotation animation - faster
    _earthController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Orbit animation - faster
    _orbitController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Pulse animation - faster
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Text animation - faster
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _earthRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _earthController,
      curve: Curves.linear,
    ));

    _orbitRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _orbitController,
      curve: Curves.linear,
    ));

    _pulseScale = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _textFade = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _earthController.dispose();
    _orbitController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1B5E20), // Deep green
              const Color(0xFF2E7D32), // Medium green
              const Color(0xFF388E3C), // Light green
              const Color(0xFF4CAF50), // Bright green
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Earth with Orbit
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Orbit rings
                      AnimatedBuilder(
                        animation: _orbitRotation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _orbitRotation.value * 2 * 3.14159,
                            child: CustomPaint(
                              size: const Size(200, 200),
                              painter: OrbitPainter(),
                            ),
                          );
                        },
                      ),

                      // Earth
                      AnimatedBuilder(
                        animation: _earthRotation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _earthRotation.value * 2 * 3.14159,
                            child: AnimatedBuilder(
                              animation: _pulseScale,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseScale.value,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          const Color(0xFF4CAF50),
                                          const Color(0xFF2E7D32),
                                          const Color(0xFF1B5E20),
                                        ],
                                        stops: const [0.0, 0.6, 1.0],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF4CAF50)
                                              .withValues(alpha: 0.3),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.eco,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ProPlanet Logo/Title
                AnimatedBuilder(
                  animation: _textFade,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textFade.value,
                      child: Column(
                        children: [
                          Text(
                            'ProPlanet',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Saving Earth, One Activity at a Time',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 60),

                // Loading Message Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Animated loading indicator
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.8),
                          ),
                          strokeWidth: 3,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Main message
                      Text(
                        widget.message,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Animated dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return AnimatedBuilder(
                            animation: _textController,
                            builder: (context, child) {
                              final delay = index * 0.2;
                              final animationValue =
                                  (_textController.value + delay) % 1.0;
                              final opacity = (animationValue < 0.5)
                                  ? (animationValue * 2)
                                  : (2 - animationValue * 2);

                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: opacity),
                                  shape: BoxShape.circle,
                                ),
                              );
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Fun facts about the environment
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getRandomEcoFact(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRandomEcoFact() {
    final facts = [
      "🌱 A single tree can absorb 22kg of CO2 per year",
      "💧 Taking a 5-minute shower saves 25 gallons of water",
      "🚶‍♂️ Walking 1 mile instead of driving saves 0.4kg CO2",
      "♻️ Recycling one aluminum can saves enough energy to power a TV for 3 hours",
      "🌍 The average person can save 2,400 pounds of CO2 annually by going car-free",
      "💡 LED bulbs use 75% less energy than incandescent bulbs",
      "🚲 Cycling 10km to work saves 1.3kg of CO2 emissions",
      "🌿 One acre of forest absorbs 6 tons of CO2 per year",
    ];

    return facts[DateTime.now().millisecond % facts.length];
  }
}

class OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Draw orbit rings
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius - 30, paint);
    canvas.drawCircle(center, radius - 60, paint);

    // Draw small dots on orbits
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 2 * 3.14159) / 8;
      final x = center.dx + (radius - 15) * math.cos(angle);
      final y = center.dy + (radius - 15) * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
