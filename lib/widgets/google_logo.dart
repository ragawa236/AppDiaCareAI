import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double rectSize = size.width;
    final double strokeWidth = rectSize * 0.22;
    final double radius = (rectSize - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final bounds = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // 1. Draw Red (top segment)
    canvas.drawArc(
      bounds,
      -2.35, // starts at -135 degrees
      1.50,  // sweeps 86 degrees to -49 degrees
      false,
      paint..color = const Color(0xFFEA4335), // Google Red
    );

    // 2. Draw Yellow (left segment)
    canvas.drawArc(
      bounds,
      2.35,  // starts at 135 degrees
      1.58,  // sweeps 90 degrees to 225 degrees (-135 degrees)
      false,
      paint..color = const Color(0xFFFBBC05), // Google Yellow
    );

    // 3. Draw Green (bottom segment)
    canvas.drawArc(
      bounds,
      0.85,  // starts at 49 degrees
      1.50,  // sweeps 86 degrees to 135 degrees
      false,
      paint..color = const Color(0xFF34A853), // Google Green
    );

    // 4. Draw Blue (right segment)
    canvas.drawArc(
      bounds,
      -0.85, // starts at -49 degrees
      1.70,  // sweeps 98 degrees to 49 degrees
      false,
      paint..color = const Color(0xFF4285F4), // Google Blue
    );

    // 5. Draw Blue horizontal crossbar
    final crossbarPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF4285F4);
    
    final crossbarRect = Rect.fromLTWH(
      center.dx,
      center.dy - strokeWidth / 2,
      radius + strokeWidth / 2,
      strokeWidth,
    );
    canvas.drawRect(crossbarRect, crossbarPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
