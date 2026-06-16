import 'package:flutter/material.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller with an 800ms duration
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Apply a smooth ease-in-out curve to the fade animation
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // 1. Fade in the logo
    _controller.forward().then((_) {
      // 2. Stay fully visible for 1.0 second
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          // 3. Fade out the logo smoothly
          _controller.reverse().then((_) {
            // 4. Navigate to Onboarding page once fade out is complete
            if (mounted) {
              _navigateToOnboarding();
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToOnboarding() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Smooth cross-fade transition to the onboarding screen
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine logo width dynamically based on screen width (35% of width, constrained between 110 and 180)
    final double screenWidth = MediaQuery.of(context).size.width;
    final double logoSize = (screenWidth * 0.35).clamp(110.0, 180.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // White solid background
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Image.asset(
            'assets/images/splashscreen/Logo.png',
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading logo asset: $error');
              // Fallback to a medical icon if image fails to load
              return const Icon(
                Icons.health_and_safety,
                size: 100,
                color: Color(0xFF0D4B6B),
              );
            },
          ),
        ),
      ),
    );
  }
}
