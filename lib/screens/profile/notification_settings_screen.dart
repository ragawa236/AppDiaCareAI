import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_settings.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isSaving = false;

  Future<void> _saveSettings(NotificationSettingsModel updated) async {
    setState(() => _isSaving = true);
    final success = await context.read<NotificationProvider>().saveSettings(updated);
    setState(() => _isSaving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Pengaturan notifikasi disimpan.' : 'Gagal menyimpan pengaturan.',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: success ? AppTheme.accentGreen : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickTime(NotificationSettingsModel current, String type) async {
    String currentTimeString = '08:00';
    if (type == 'daily') {
      currentTimeString = current.dailyReminderTime;
    } else if (type == 'medicine') {
      currentTimeString = current.medicineReminderTime;
    } else if (type == 'glucose') {
      currentTimeString = current.glucoseReminderTime;
    }

    final parts = currentTimeString.split(':');
    final initialHour = int.tryParse(parts[0]) ?? 8;
    final initialMinute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      final timeString =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      
      NotificationSettingsModel updated;
      if (type == 'daily') {
        updated = current.copyWith(dailyReminderTime: timeString);
      } else if (type == 'medicine') {
        updated = current.copyWith(medicineReminderTime: timeString);
      } else {
        updated = current.copyWith(glucoseReminderTime: timeString);
      }
      await _saveSettings(updated);
    }
  }

  Widget _buildTimePickerRow({
    required String title,
    required String subtitle,
    required String timeString,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isSaving ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.access_time_rounded,
                  color: AppTheme.primaryBlue, size: 20),
            ),
            const SizedBox(width: 14),
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
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
              ),
              child: Text(
                timeString,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textLight, size: 20),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textDark, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notifikasi',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
          ),
        ),
        centerTitle: true,
        shape: const Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            );
          }

          final settings = provider.settings ?? NotificationSettingsModel.defaultSettings();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E40AF), AppTheme.primaryBlue],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pengaturan Notifikasi',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Atur reminder & peringatan kesehatan Anda',
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Switches Section
                _buildSectionTitle('Pengingat Harian'),
                const SizedBox(height: 12),
                _buildSettingsCard([
                  _buildSwitch(
                    icon: Icons.wb_sunny_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'Notifikasi Harian',
                    subtitle: 'Terima ringkasan kesehatan setiap hari',
                    value: settings.dailyReminder,
                    onChanged: (v) => _saveSettings(settings.copyWith(dailyReminder: v)),
                  ),
                  const Divider(height: 1, indent: 68, color: AppTheme.borderColor),
                  _buildSwitch(
                    icon: Icons.medication_rounded,
                    iconColor: const Color(0xFFEF4444),
                    title: 'Pengingat Minum Obat',
                    subtitle: 'Notifikasi jadwal minum obat harian',
                    value: settings.medicineReminder,
                    onChanged: (v) => _saveSettings(settings.copyWith(medicineReminder: v)),
                  ),
                  const Divider(height: 1, indent: 68, color: AppTheme.borderColor),
                  _buildSwitch(
                    icon: Icons.water_drop_rounded,
                    iconColor: AppTheme.primaryBlue,
                    title: 'Pengingat Cek Gula Darah',
                    subtitle: 'Ingatkan untuk cek glukosa secara rutin',
                    value: settings.glucoseReminder,
                    onChanged: (v) => _saveSettings(settings.copyWith(glucoseReminder: v)),
                  ),
                  const Divider(height: 1, indent: 68, color: AppTheme.borderColor),
                  _buildSwitch(
                    icon: Icons.analytics_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    title: 'Notifikasi Hasil Prediksi Risiko',
                    subtitle: 'Pemberitahuan saat analisis AI selesai',
                    value: settings.riskPredictionNotification,
                    onChanged: (v) => _saveSettings(settings.copyWith(riskPredictionNotification: v)),
                  ),
                ]),
                const SizedBox(height: 24),

                // Time Picker
                _buildSectionTitle('Waktu Reminder'),
                const SizedBox(height: 12),
                _buildSettingsCard([
                  if (settings.dailyReminder) ...[
                    _buildTimePickerRow(
                      title: 'Waktu Pengingat Harian',
                      subtitle: 'Notifikasi harian akan dikirim pukul:',
                      timeString: settings.dailyReminderTime,
                      onTap: () => _pickTime(settings, 'daily'),
                    ),
                    if (settings.medicineReminder || settings.glucoseReminder)
                      const Divider(height: 1, indent: 68, color: AppTheme.borderColor),
                  ],
                  if (settings.medicineReminder) ...[
                    _buildTimePickerRow(
                      title: 'Waktu Pengingat Obat',
                      subtitle: 'Pengingat obat akan dikirim pukul:',
                      timeString: settings.medicineReminderTime,
                      onTap: () => _pickTime(settings, 'medicine'),
                    ),
                    if (settings.glucoseReminder)
                      const Divider(height: 1, indent: 68, color: AppTheme.borderColor),
                  ],
                  if (settings.glucoseReminder) ...[
                    _buildTimePickerRow(
                      title: 'Waktu Pengingat Gula Darah',
                      subtitle: 'Pengingat gula darah akan dikirim pukul:',
                      timeString: settings.glucoseReminderTime,
                      onTap: () => _pickTime(settings, 'glucose'),
                    ),
                  ],
                  if (!settings.dailyReminder && !settings.medicineReminder && !settings.glucoseReminder)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'Aktifkan salah satu pengingat di atas untuk mengatur waktu.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ]),

                const SizedBox(height: 16),

                // Info box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF3FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppTheme.primaryBlue, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pengaturan notifikasi disimpan otomatis ke cloud. Untuk notifikasi aktif, pastikan izin notifikasi aplikasi diaktifkan di pengaturan perangkat Anda.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.primaryBlue,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textLight,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSwitch({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
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
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: _isSaving ? null : onChanged,
            activeThumbColor: AppTheme.primaryBlue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
