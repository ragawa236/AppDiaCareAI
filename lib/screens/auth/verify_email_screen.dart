import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'dart:math' as math;

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
  bool _canResendEmail = false;
  int _secondsRemaining = 30;
  Timer? _countdownTimer;
  Timer? _autoCheckTimer;
  bool _isResending = false;
  bool _isChecking = false;
  
  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Slide-up and fade animations
    _animController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();

    _startCountdown();

    // Periodically check email verification status automatically (every 5 seconds)
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkEmailVerified(isAuto: true);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _autoCheckTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _canResendEmail = false;
      _secondsRemaining = 30;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResendEmail = true;
        });
        _countdownTimer?.cancel();
      }
    });
  }

  Future<void> _checkEmailVerified({bool isAuto = false}) async {
    if (!mounted) return;
    
    if (!isAuto) {
      setState(() => _isChecking = true);
    }

    final authProvider = context.read<AuthProvider>();
    await authProvider.reloadUser();

    if (mounted) {
      if (!isAuto) {
        setState(() => _isChecking = false);
      }
      
      // If user has successfully verified, AuthWrapper will automatically
      // redirect them. If manual check is done and still not verified, show snackbar.
      if (!isAuto && authProvider.firebaseUser != null && !authProvider.firebaseUser!.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Email belum diverifikasi. Silakan periksa kembali email Anda.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _handleResendEmail() async {
    if (!_canResendEmail) return;

    setState(() => _isResending = true);
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendEmailVerification();
    
    if (mounted) {
      setState(() => _isResending = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Email verifikasi baru berhasil dikirim!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _startCountdown();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Gagal mengirim email verifikasi.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Batal Registrasi', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin keluar? Anda dapat memverifikasi email Anda nanti.', style: GoogleFonts.inter()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kembali', style: GoogleFonts.inter(color: AppTheme.textGrey, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().signOut();
            },
            child: Text('Keluar', style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final authProvider = context.watch<AuthProvider>();
    final email = authProvider.firebaseUser?.email ?? 'email Anda';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: screenHeight,
          ),
          child: IntrinsicHeight(
            child: Stack(
              children: [
                // Top Wave Header with Topographical Lines
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: screenHeight * 0.32,
                  child: ClipPath(
                    clipper: VerifyEmailWaveClipper(),
                    child: Container(
                      color: AppTheme.primaryBlue,
                      child: CustomPaint(
                        painter: VerifyEmailTopographyPainter(
                          lineColor: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                  ),
                ),

                // Content Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenHeight * 0.35), // Position below header

                      // Slide transition for verification details
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(_slideAnimation),
                        child: FadeTransition(
                          opacity: _slideAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verifikasi Email',
                                style: GoogleFonts.inter(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textDark,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 45,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Informational Card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundLight,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.mark_email_read_rounded,
                                        color: AppTheme.primaryBlue,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Verifikasi Terkirim',
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          RichText(
                                            text: TextSpan(
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: AppTheme.textGrey,
                                                height: 1.4,
                                              ),
                                              children: [
                                                const TextSpan(text: 'Tautan verifikasi telah dikirimkan ke '),
                                                TextSpan(
                                                  text: email,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.primaryBlue,
                                                  ),
                                                ),
                                                const TextSpan(text: '. Silakan periksa folder kotak masuk atau spam Anda dan verifikasi akun Anda untuk melanjutkan.'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Actions section (Buttons)
                      Expanded(
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(_slideAnimation),
                          child: FadeTransition(
                            opacity: _slideAnimation,
                            child: Column(
                              children: [
                                // Refresh Status Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isChecking ? null : () => _checkEmailVerified(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryBlue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isChecking
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Text(
                                            'Saya Sudah Verifikasi / Refresh',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Resend verification email button
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: OutlinedButton(
                                    onPressed: (_canResendEmail && !_isResending)
                                        ? _handleResendEmail
                                        : null,
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: _canResendEmail
                                            ? AppTheme.primaryBlue
                                            : Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      foregroundColor: AppTheme.primaryBlue,
                                      disabledForegroundColor: Colors.grey.shade400,
                                    ),
                                    child: _isResending
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            _canResendEmail
                                                ? 'Kirim Ulang Email Verifikasi'
                                                : 'Kirim Ulang dalam ${_secondsRemaining}s',
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                                const Spacer(),
                                
                                // Cancel / Exit button
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 32),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Menggunakan email lain? ',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: AppTheme.textGrey,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: _handleSignOut,
                                        child: Text(
                                          'Keluar',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFEF4444),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VerifyEmailWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.82);

    final controlPoint1 = Offset(size.width * 0.28, size.height * 0.62);
    final controlPoint2 = Offset(size.width * 0.72, size.height * 1.05);
    final endPoint = Offset(size.width, size.height * 0.85);

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

class VerifyEmailTopographyPainter extends CustomPainter {
  final Color lineColor;
  VerifyEmailTopographyPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = Offset(size.width * 0.55, size.height * 0.35);

    for (int i = 1; i <= 8; i++) {
      final double radius = i * 22.0;
      final path = Path();

      for (int angle = 0; angle <= 360; angle += 8) {
        final double rad = angle * math.pi / 180;
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
