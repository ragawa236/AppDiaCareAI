import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/privacy_provider.dart';
import '../../repositories/database_repository.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import 'risk_prediction_screen.dart';
import '../../models/sensor_data.dart';
import '../../services/firebase_sensor_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _selectedIndex == 0
            ? _HomeContent(
                key: const ValueKey('home'),
                onNavigateToTab: (index) {
                  setState(() => _selectedIndex = index);
                },
              )
            : _selectedIndex == 1
                ? const HistoryScreen(key: ValueKey('history'))
                : const ProfileScreen(key: ValueKey('profile')),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _buildNavItem(1, Icons.history_rounded, Icons.history_outlined, 'History'),
              _buildNavItem(2, Icons.person_rounded, Icons.person_outlined, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isActive = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primaryBlue.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isActive ? activeIcon : inactiveIcon,
                color: isActive ? AppTheme.primaryBlue : AppTheme.textGrey,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                color: isActive ? AppTheme.primaryBlue : AppTheme.textGrey,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  final Function(int) onNavigateToTab;
  const _HomeContent({super.key, required this.onNavigateToTab});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  int _notificationCount = 3;
  
  final FirebaseSensorService _sensorService = FirebaseSensorService();
  final DatabaseRepository _dbRepository = DatabaseRepository();
  bool _isSimulating = false;
  DateTime? _lastSensorSave;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _sensorService.stopSimulation();
    _animController.dispose();
    super.dispose();
  }

  /// Throttle sensor data saves to once every 5 minutes to avoid RTDB write spam.
  Future<void> _maybeSaveSensorData(SensorData data) async {
    if (!mounted) return;
    final now = DateTime.now();
    if (_lastSensorSave != null &&
        now.difference(_lastSensorSave!) < const Duration(minutes: 5)) return;
    _lastSensorSave = now;

    final privacyProvider = context.read<PrivacyProvider>();
    final storeHistory = privacyProvider.settings?.storeHistory ?? true;
    if (!storeHistory) return;

    final uid = context.read<AuthProvider>().firebaseUser?.uid;
    if (uid == null) return;

    try {
      await _dbRepository.saveSensorDataHistory(uid, {
        'temperature': data.temperature,
        'humidity': data.humidity,
        'glucose': data.glucose,
        'timestamp': data.timestamp.isNotEmpty
            ? data.timestamp
            : DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Dashboard: Failed to save sensor history: $e');
    }
  }

  void _showNotificationBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifikasi Kesehatan',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                      if (_notificationCount > 0)
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _notificationCount = 0;
                            });
                            setState(() {
                              _notificationCount = 0;
                            });
                          },
                          child: Text(
                            'Tandai Terbaca',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_notificationCount == 0)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.notifications_off_outlined,
                              size: 48,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada notifikasi baru',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        _buildNotificationTile(
                          icon: Icons.alarm_rounded,
                          color: const Color(0xFFEF4444),
                          title: 'Jadwal Cek Gula Darah',
                          desc: 'Saatnya melakukan cek gula darah pagi Anda (sebelum makan).',
                          time: '10 menit yang lalu',
                          isNew: true,
                        ),
                        const SizedBox(height: 12),
                        _buildNotificationTile(
                          icon: Icons.auto_awesome_rounded,
                          color: AppTheme.primaryBlue,
                          title: 'Rekomendasi AI Baru',
                          desc: 'Tips kesehatan personal harian Anda telah diperbarui.',
                          time: '1 jam yang lalu',
                          isNew: true,
                        ),
                        const SizedBox(height: 12),
                        _buildNotificationTile(
                          icon: Icons.sync_rounded,
                          color: const Color(0xFF22C55E),
                          title: 'Sinkronisasi Berhasil',
                          desc: 'Data aktivitas harian disinkronkan dengan Google Fit.',
                          time: 'Hari ini, 06:00',
                          isNew: false,
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    required String time,
    required bool isNew,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNew ? color.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNew ? color.withOpacity(0.15) : AppTheme.borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    if (isNew)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textGrey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHealthAdviceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppTheme.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Health Advisory',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Berdasarkan pola gula darah dan aktivitas Anda akhir-akhir ini, asisten AI mendeteksi tren yang sangat positif. Berikut adalah rekomendasi personal Anda:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textGrey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildTipDetailItem(
                icon: Icons.local_fire_department_rounded,
                title: 'Aktivitas Fisik Konsisten',
                desc: 'Aktivitas rata-rata Anda di atas 8,000 langkah berkontribusi besar menurunkan resistensi insulin sel tubuh Anda.',
              ),
              const SizedBox(height: 12),
              _buildTipDetailItem(
                icon: Icons.restaurant_rounded,
                title: 'Waktu Makan Teratur',
                desc: 'Kadar glukosa setelah makan (postprandial) sangat stabil karena jeda makan malam dan tidur yang ideal (minimal 3 jam).',
              ),
              const SizedBox(height: 12),
              _buildTipDetailItem(
                icon: Icons.water_drop_rounded,
                title: 'Hidrasi Optimal',
                desc: 'Tingkatkan asupan air putih di pagi hari untuk membantu ginjal membuang kelebihan gula secara alami.',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Tutup & Lanjutkan',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTipDetailItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textGrey,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final healthProvider = context.watch<HealthProvider>();

    return Container(
      decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 24),
                FadeTransition(opacity: _animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(_animation), child: _buildHeroBanner())),
                const SizedBox(height: 24),
                FadeTransition(opacity: _animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(_animation), child: _buildQuickActionMenu())),
                const SizedBox(height: 24),
                
                StreamBuilder<SensorData>(
                  stream: _sensorService.getSensorDataStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    }
                    
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    }
                    
                    final sensorData = snapshot.data ?? SensorData.initial();

                    // Throttled save of sensor history to RTDB (respects privacy settings)
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _maybeSaveSensorData(sensorData);
                    });
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLiveStatusRow(sensorData),
                        const SizedBox(height: 12),
                        FadeTransition(
                          opacity: _animation,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(_animation),
                            child: _buildRiskCard(sensorData),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeTransition(
                          opacity: _animation,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(_animation),
                            child: _buildMetricsRow(sensorData),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _animation,
                          child: _buildMedicalSummaryCard(healthProvider),
                        ),
                        const SizedBox(height: 24),
                        FadeTransition(opacity: _animation, child: _buildRecentActivitySection(sensorData)),
                        const SizedBox(height: 24),
                        FadeTransition(opacity: _animation, child: _buildAIRecommendationsCard(sensorData)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalSummaryCard(HealthProvider provider) {
    final latest = provider.latestRecord;
    final total = provider.totalRecordsCount;
    final latestLog = provider.latestActivityLog;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ringkasan Medis (Manual)',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$total Catatan',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (latest == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Belum ada riwayat rekam medis manual. Tambahkan catatan kesehatan di tab Riwayat.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textGrey,
                  height: 1.4,
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem('Gula Darah', '${latest.glucoseLevel.toInt()} mg/dL', latest.glucoseStatus == 'Normal' ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                    _buildSummaryItem('Tekanan Darah', latest.bloodPressure.isNotEmpty ? latest.bloodPressure : '--', AppTheme.textDark),
                    _buildSummaryItem('Denyut Jantung', '${latest.heartRate.toInt()} bpm', AppTheme.textDark),
                  ],
                ),
                const Divider(color: AppTheme.borderColor, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem('Berat Badan', '${latest.weight} kg', AppTheme.textDark),
                    _buildSummaryItem('BMI (Status)', '${latest.bmi.toStringAsFixed(1)} (${latest.bmiStatus})', latest.bmiStatus == 'Normal' ? const Color(0xFF16A34A) : const Color(0xFFD97706)),
                  ],
                ),
                if (latest.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Catatan: "${latest.notes}"',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textGrey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]
              ],
            ),
          if (latestLog != null) ...[
            const Divider(color: AppTheme.borderColor, height: 20),
            Row(
              children: [
                const Icon(Icons.history_toggle_off_rounded, color: AppTheme.textLight, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Aktivitas Terakhir: ${latestLog.action} (${latestLog.description})',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textGrey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveStatusRow(SensorData data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const _LivePulseIndicator(),
            const SizedBox(width: 8),
            Text(
              'LIVE MONITORING',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.textGrey,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '•',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            const SizedBox(width: 6),
            Text(
              _formatTimestamp(data.timestamp),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isSimulating = !_isSimulating;
              if (_isSimulating) {
                _sensorService.startSimulation();
              } else {
                _sensorService.stopSimulation();
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isSimulating 
                    ? 'Simulasi data sensor IoT dimulai!' 
                    : 'Simulasi data sensor IoT dihentikan.',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                backgroundColor: _isSimulating ? AppTheme.accentGreen : AppTheme.darkNavy,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _isSimulating 
                ? AppTheme.accentGreen.withOpacity(0.1) 
                : AppTheme.primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isSimulating 
                  ? AppTheme.accentGreen.withOpacity(0.3) 
                  : AppTheme.primaryBlue.withOpacity(0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isSimulating ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  size: 14,
                  color: _isSimulating ? AppTheme.accentGreen : AppTheme.primaryBlue,
                ),
                const SizedBox(width: 2),
                Text(
                  _isSimulating ? 'Stop Simulasi' : 'Simulasi IoT',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _isSimulating ? AppTheme.accentGreen : AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(String timestamp) {
    if (timestamp.isEmpty) return 'Menunggu data...';
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final second = dateTime.second.toString().padLeft(2, '0');
      return 'Aktif: $hour:$minute:$second';
    } catch (_) {
      return 'Baru Saja';
    }
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              color: AppTheme.primaryBlue,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Menghubungkan ke sensor IoT...',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mengambil data dari Firebase Realtime Database',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 24),
              const SizedBox(width: 8),
              Text(
                'Koneksi Gagal',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF991B1B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Gagal sinkronisasi dengan database IoT: $error',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF7F1D1D),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Coba Lagi'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isSimulating = true;
                    _sensorService.startSimulation();
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7F1D1D),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Gunakan Simulasi'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.userProfile;
    final String name = profile?.fullName ?? 'Alex';
    final String initialLetter = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    final String subtitle = profile != null 
        ? _formatLastLogin(profile.lastLogin)
        : 'Kondisi metabolisme Anda stabil.';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              GestureDetector(
                onTap: () => widget.onNavigateToTab(2),
                child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFF4A90D9), Color(0xFF1A56DB)]),
                    boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Center(child: Text(initialLetter, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Halo, $name 👋', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark, letterSpacing: -0.5)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: _showNotificationBottomSheet,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppTheme.borderColor), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
                    child: const Icon(Icons.notifications_outlined, color: AppTheme.textDark, size: 20),
                  ),
                  if (_notificationCount > 0)
                    Positioned(
                      top: -2, right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Center(child: Text('$_notificationCount', style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800), textAlign: TextAlign.center)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Keluar Akun', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    content: Text('Apakah Anda yakin ingin keluar dari akun DiaCareAI Anda?', style: GoogleFonts.inter()),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Batal', style: GoogleFonts.inter(color: AppTheme.textGrey, fontWeight: FontWeight.w600)),
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
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppTheme.borderColor), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
                child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatLastLogin(String lastLoginStr) {
    if (lastLoginStr.isEmpty) return 'Kondisi metabolisme Anda stabil.';
    try {
      final dateTime = DateTime.parse(lastLoginStr).toLocal();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return 'Masuk terakhir: $hour:$minute WIB';
    } catch (_) {
      return 'Masuk: Baru saja';
    }
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E40AF), Color(0xFF1D4ED8), Color(0xFF10B981)], stops: [0.0, 0.7, 1.0]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(right: -20, bottom: -20, child: Opacity(opacity: 0.1, child: const Icon(Icons.health_and_safety_rounded, size: 160, color: Colors.white))),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: Text('DiaCare AI Health', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      ),
                      const SizedBox(height: 12),
                      Text('Asisten AI Pintar Untuk Kesehatan Anda', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.3)),
                      const SizedBox(height: 6),
                      Text('Dapatkan rekomendasi & prediksi metabolic secara realtime.', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w500, height: 1.4)),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _showPredictionDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)]),
                          child: Text('Mulai Analisis', style: GoogleFonts.inter(color: AppTheme.primaryBlue, fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)),
                  child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 44),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Menu Akses Cepat', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _buildQuickActionCard(icon: Icons.analytics_rounded, color: AppTheme.primaryBlue, title: 'Cek Risiko AI', subtitle: 'Prediksi diabetes', onTap: _showPredictionDialog),
            _buildQuickActionCard(icon: Icons.bar_chart_rounded, color: const Color(0xFF22C55E), title: 'Riwayat Gula', subtitle: 'Lihat tren grafik', onTap: () => widget.onNavigateToTab(1)),
            _buildQuickActionCard(icon: Icons.contact_page_rounded, color: const Color(0xFFF59E0B), title: 'Profil Medis', subtitle: 'Data kesehatan', onTap: () => widget.onNavigateToTab(2)),
            _buildQuickActionCard(icon: Icons.lightbulb_outline_rounded, color: const Color(0xFFEC4899), title: 'Tips AI', subtitle: 'Rekomendasi harian', onTap: _showHealthAdviceBottomSheet),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: color.withOpacity(0.08),
        highlightColor: color.withOpacity(0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.borderColor)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
              const SizedBox(height: 10),
              Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.textGrey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskCard(SensorData data) {
    double riskProgress = 0.0;
    String riskLabel = 'Tidak Ada Data';
    Color riskColor = AppTheme.textGrey;
    Color badgeBgColor = AppTheme.borderColor;
    Color badgeTextColor = AppTheme.textGrey;
    IconData badgeIcon = Icons.help_outline_rounded;

    if (data.glucose > 0) {
      if (data.glucose <= 100) {
        riskProgress = 0.05 + ((data.glucose / 100) * 0.10); // 5% to 15%
        riskLabel = 'Risiko Rendah';
        riskColor = const Color(0xFF16A34A);
        badgeBgColor = const Color(0xFFDCFCE7);
        badgeTextColor = const Color(0xFF166534);
        badgeIcon = Icons.check_circle_rounded;
      } else if (data.glucose <= 140) {
        riskProgress = 0.15 + (((data.glucose - 100) / 40) * 0.10); // 15% to 25%
        riskLabel = 'Risiko Rendah';
        riskColor = const Color(0xFF16A34A);
        badgeBgColor = const Color(0xFFDCFCE7);
        badgeTextColor = const Color(0xFF166534);
        badgeIcon = Icons.check_circle_rounded;
      } else if (data.glucose <= 200) {
        riskProgress = 0.30 + (((data.glucose - 140) / 60) * 0.35); // 30% to 65%
        riskLabel = 'Risiko Sedang';
        riskColor = const Color(0xFFD97706);
        badgeBgColor = const Color(0xFFFEF3C7);
        badgeTextColor = const Color(0xFF92400E);
        badgeIcon = Icons.warning_amber_rounded;
      } else {
        riskProgress = 0.70 + (((data.glucose - 200) / 150) * 0.25).clamp(0.0, 0.25); // 70% to 95%
        riskLabel = 'Risiko Tinggi';
        riskColor = const Color(0xFFDC2626);
        badgeBgColor = const Color(0xFFFEE2E2);
        badgeTextColor = const Color(0xFF991B1B);
        badgeIcon = Icons.error_outline_rounded;
      }
    }

    final String desc = data.glucose > 0 
      ? 'Berdasarkan kadar glukosa harian Anda (${data.glucose.toInt()} mg/dL), tingkat risiko metabolik Anda saat ini tergolong $riskLabel.'
      : 'Menghubungkan ke database IoT untuk menganalisis tingkat risiko metabolik harian Anda secara real-time.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 170, height: 170,
            child: CustomPaint(
              painter: _RiskGaugePainter(progress: riskProgress),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.glucose > 0 ? '${(riskProgress * 100).toInt()}%' : '--%', 
                      style: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w900, color: data.glucose > 0 ? riskColor : AppTheme.textGrey, letterSpacing: -1)
                    ),
                    Text('TINGKAT RISIKO', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textGrey, letterSpacing: 1.2)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: badgeBgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: badgeBgColor.withOpacity(0.8))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, color: riskColor, size: 16),
                const SizedBox(width: 6),
                Text(riskLabel, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: badgeTextColor)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(desc, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textGrey, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(SensorData data) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.water_drop_outlined, 
            iconColor: const Color(0xFF2563EB), 
            label: 'Gula Darah', 
            value: data.glucose > 0 ? data.glucose.toStringAsFixed(0) : '--', 
            unit: 'mg/dL', 
            trend: data.glucose > 0 ? data.glucoseStatus.replaceAll(' (Optimal)', '').replaceAll(' (Hipoglikemia)', '').replaceAll(' (Prediabetes)', '').replaceAll(' (Diabetes)', '') : 'N/A', 
            isPositive: data.glucose >= 70 && data.glucose <= 140
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.thermostat_rounded, 
            iconColor: const Color(0xFFF59E0B), 
            label: 'Suhu Tubuh', 
            value: data.temperature > 0 ? data.temperature.toStringAsFixed(1) : '--', 
            unit: '°C', 
            trend: data.isTemperatureSafe ? 'Normal' : 'Abnormal', 
            isPositive: data.isTemperatureSafe
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.water_drop_rounded, 
            iconColor: const Color(0xFF06B6D4), 
            label: 'Kelembaban', 
            value: data.humidity > 0 ? data.humidity.toStringAsFixed(0) : '--', 
            unit: '%', 
            trend: data.isHumiditySafe ? 'Ideal' : 'Kering', 
            isPositive: data.isHumiditySafe
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({required IconData icon, required Color iconColor, required String label, required String value, required String unit, required String trend, required bool isPositive}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Icon(icon, color: iconColor, size: 14)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label, 
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textGrey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark, letterSpacing: -0.5)),
              const SizedBox(width: 2),
              Padding(padding: const EdgeInsets.only(bottom: 2), child: Text(unit, style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textGrey, fontWeight: FontWeight.w500))),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6)),
            child: Text(
              trend, 
              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: isPositive ? const Color(0xFF166534) : const Color(0xFF991B1B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showPredictionDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RiskPredictionScreen(),
      ),
    );
  }

  Widget _buildRecentActivitySection(SensorData data) {
    final String liveTime = data.timestamp.isNotEmpty 
      ? _formatTimestamp(data.timestamp).replaceAll('Aktif: ', '') 
      : '--:--';
    final Color liveStatusColor = data.glucose >= 70 && data.glucose <= 140 
      ? const Color(0xFF22C55E) 
      : (data.glucose <= 200 ? AppTheme.primaryBlue : const Color(0xFFEF4444));
    final String liveStatusLabel = data.glucose > 0 
      ? data.glucoseStatus.replaceAll(' (Optimal)', '').replaceAll(' (Hipoglikemia)', '').replaceAll(' (Prediabetes)', '').replaceAll(' (Diabetes)', '') 
      : 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Aktivitas Terbaru', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
            GestureDetector(onTap: () => widget.onNavigateToTab(1), child: Text('Lihat Semua', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryBlue))),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.borderColor)),
          child: Column(children: [
            _buildTimelineItem(
              time: '$liveTime WIB', 
              glucose: data.glucose > 0 ? '${data.glucose.toInt()} mg/dL' : '-- mg/dL', 
              type: 'Glukosa Real-Time (Sensor IoT)', 
              statusColor: liveStatusColor, 
              statusLabel: liveStatusLabel, 
              isLast: false
            ),
            _buildTimelineItem(time: '08:30 WIB', glucose: '94 mg/dL', type: 'Glukosa Sebelum Makan', statusColor: const Color(0xFF22C55E), statusLabel: 'Normal', isLast: false),
            _buildTimelineItem(time: 'Kemarin, 15:45 WIB', glucose: '98 mg/dL', type: 'Glukosa Sebelum Makan', statusColor: AppTheme.primaryBlue, statusLabel: 'Optimal', isLast: true),
          ]),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({required String time, required String glucose, required String type, required Color statusColor, required String statusLabel, required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 16),
          Column(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: statusColor.withOpacity(0.4), blurRadius: 4)])),
            if (!isLast) Expanded(child: Container(width: 2, color: AppTheme.borderColor)),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(glucose, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(statusLabel, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(type, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textGrey)),
                Text(time, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textLight)),
                if (!isLast) const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIRecommendationsCard(SensorData data) {
    String recommendationText = 'Menunggu data sensor untuk menganalisis metabolisme Anda...';
    if (data.glucose > 0) {
      if (data.glucose < 70) {
        recommendationText = 'Kadar glukosa Anda tergolong rendah (${data.glucose.toInt()} mg/dL). Rekomendasi AI: Segera konsumsi 15-20 gram karbohidrat cepat serap (seperti jus buah atau permen) dan periksa kembali dalam 15 menit.';
      } else if (data.glucose <= 140) {
        recommendationText = 'Kadar glukosa Anda sangat stabil (${data.glucose.toInt()} mg/dL). Rekomendasi AI: Pola makan dan hidrasi harian Anda sudah optimal. Lanjutkan aktivitas berjalan kaki 10-15 menit setelah makan untuk memelihara insulin sensitivitas.';
      } else if (data.glucose <= 200) {
        recommendationText = 'Kadar glukosa Anda terpantau tinggi (${data.glucose.toInt()} mg/dL). Rekomendasi AI: Kurangi konsumsi karbohidrat olahan dan minuman manis hari ini. Lakukan jalan cepat selama 20 menit untuk membantu otot membakar kelebihan glukosa.';
      } else {
        recommendationText = 'Peringatan: Kadar glukosa Anda sangat tinggi (${data.glucose.toInt()} mg/dL). Rekomendasi AI: Hindari aktivitas fisik berat jika merasa pusing, konsumsi air putih dalam jumlah cukup untuk membantu ginjal, dan segera hubungi dokter jika ada gejala ketosis.';
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.12), shape: BoxShape.circle), child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryBlue, size: 18)),
              const SizedBox(width: 8),
              Text('Rekomendasi AI Hari Ini', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue)),
            ]),
            const SizedBox(height: 10),
            Text(recommendationText, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textDark, height: 1.4)),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _showHealthAdviceBottomSheet,
              child: Row(children: [
                Text('Lihat Tips Selengkapnya', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryBlue)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryBlue, size: 14),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for the risk gauge
class _RiskGaugePainter extends CustomPainter {
  final double progress;

  _RiskGaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 16;
    const strokeWidth = 12.0;
    const startAngle = -math.pi * 0.8;
    const sweepAngle = math.pi * 1.6;

    // Background arc
    final bgPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      progressPaint,
    );

    // Dot at end of progress
    final angle = startAngle + sweepAngle * progress;
    final dotX = center.dx + radius * math.cos(angle);
    final dotY = center.dy + radius * math.sin(angle);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(dotX, dotY), 8, dotBorderPaint);
    canvas.drawCircle(Offset(dotX, dotY), 5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RiskGaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _LivePulseIndicator extends StatefulWidget {
  const _LivePulseIndicator();

  @override
  State<_LivePulseIndicator> createState() => _LivePulseIndicatorState();
}

class _LivePulseIndicatorState extends State<_LivePulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller.drive(
        Tween<double>(begin: 0.3, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF22C55E),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xFF22C55E),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
