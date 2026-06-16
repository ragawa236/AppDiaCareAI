import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';
import 'dart:math' as math;

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top Wave Header with Topographical Lines
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.58,
            child: ClipPath(
              clipper: WaveClipper(),
              child: Container(
                color: AppTheme.primaryBlue, // Blue background instead of Red
                child: CustomPaint(
                  painter: TopographyPainter(
                    lineColor: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
            ),
          ),
          
          // Welcome and Description Text
          Positioned(
            top: screenHeight * 0.62,
            left: 28,
            right: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang',
                  style: GoogleFonts.inter(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Mitra Anda untuk perawatan diabetes cerdas, akurasi prediktif, dan wawasan kesehatan pribadi.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textGrey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom right Continue Button
          Positioned(
            bottom: 48,
            right: 28,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const LoginScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 500),
                  ),
                );
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lanjutkan',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryBlue,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.85); // Starts lower on the left
    
    // Wave curves up first, then down, then up
    final controlPoint1 = Offset(size.width * 0.28, size.height * 0.65);
    final controlPoint2 = Offset(size.width * 0.72, size.height * 1.05);
    final endPoint = Offset(size.width, size.height * 0.88);
    
    path.cubicTo(
      controlPoint1.dx, controlPoint1.dy,
      controlPoint2.dx, controlPoint2.dy,
      endPoint.dx, endPoint.dy,
    );
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class TopographyPainter extends CustomPainter {
  final Color lineColor;
  TopographyPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Center point for concentric irregular ellipses
    final center = Offset(size.width * 0.55, size.height * 0.35);

    for (int i = 1; i <= 14; i++) {
      final double radius = i * 26.0;
      final path = Path();

      for (int angle = 0; angle <= 360; angle += 6) {
        final double rad = angle * math.pi / 180;
        
        // Organic distortion matching topographic map pattern
        final double distortion = 1.0 + 
            0.12 * math.sin(3.5 * rad) + 
            0.08 * math.cos(5.0 * rad);
            
        final double x = center.dx + radius * distortion * math.cos(rad);
        final double y = center.dy + radius * distortion * 0.8 * math.sin(rad);

        if (angle == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
