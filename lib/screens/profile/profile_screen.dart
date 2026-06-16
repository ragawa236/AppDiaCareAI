import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_provider.dart';
import '../../models/user_model.dart';
import '../history/report_preview_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  void _showEditProfileSheet(UserModel profile) {
    final nameController = TextEditingController(text: profile.fullName);
    final ageController = TextEditingController(text: profile.age.toString());
    String selectedGender = profile.gender.isNotEmpty ? profile.gender : 'Laki-laki';
    XFile? tempPickedImage = _pickedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ubah Profil Pasien',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Avatar photo selection picker
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            try {
                              final XFile? image = await _picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 512,
                                maxHeight: 512,
                                imageQuality: 85,
                              );
                              if (image != null) {
                                setSheetState(() {
                                  tempPickedImage = image;
                                });
                              }
                            } catch (e) {
                              debugPrint('Error picking image: $e');
                            }
                          },
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 104,
                                height: 104,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                  gradient: tempPickedImage == null
                                      ? const LinearGradient(
                                          colors: [AppTheme.primaryBlue, Color(0xFFEF4444)],
                                        )
                                      : null,
                                  image: tempPickedImage != null
                                      ? DecorationImage(
                                          image: kIsWeb
                                              ? NetworkImage(tempPickedImage!.path)
                                              : FileImage(File(tempPickedImage!.path)) as ImageProvider,
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryBlue.withOpacity(0.12),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: tempPickedImage == null
                                    ? Center(
                                        child: Text(
                                          nameController.text.isNotEmpty ? nameController.text[0].toUpperCase() : 'A',
                                          style: GoogleFonts.inter(
                                            fontSize: 42,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.photo_library_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ketuk untuk memilih foto dari galeri',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        if (tempPickedImage != null) ...[
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                tempPickedImage = null;
                              });
                            },
                            child: Text(
                              'Hapus Foto',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name Field
                  Text(
                    'NAMA LENGKAP',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    onChanged: (val) {
                      setSheetState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Masukkan nama lengkap',
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryBlue),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),

                  // Gender Dropdown
                  Text(
                    'JENIS KELAMIN',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    items: ['Laki-laki', 'Perempuan'].map((g) {
                      return DropdownMenuItem<String>(
                        value: g,
                        child: Text(g, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        selectedGender = val;
                      }
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.people_outline_rounded, color: AppTheme.primaryBlue),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Age Field
                  Text(
                    'UMUR (TAHUN)',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Masukkan umur Anda',
                      prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppTheme.primaryBlue),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: const BorderSide(color: AppTheme.borderColor, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Batal',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textGrey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final newName = nameController.text.trim();
                            final newAgeStr = ageController.text.trim();
                            final newAge = int.tryParse(newAgeStr) ?? profile.age;

                            if (newName.isNotEmpty && newAge > 0) {
                              final success = await context.read<AuthProvider>().updateProfile(
                                    fullName: newName,
                                    age: newAge,
                                    gender: selectedGender,
                                  );
                              if (success) {
                                setState(() {
                                  _pickedImage = tempPickedImage;
                                });
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.read<AuthProvider>().errorMessage ?? 'Gagal memperbarui profil.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          child: Text(
                            'Simpan',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final healthProvider = context.watch<HealthProvider>();
    final profile = authProvider.userProfile ?? UserModel.empty();
    
    final String name = profile.fullName.isNotEmpty ? profile.fullName : 'Pengguna DiaCare';
    final String email = profile.email.isNotEmpty ? profile.email : 'Belum diatur';
    final String initialLetter = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    
    final latestRecord = healthProvider.latestRecord;
    final averageGlucose = healthProvider.averageGlucose;
    
    // Calculate BMI and status
    final double bmiValue = latestRecord != null ? latestRecord.bmi : 0.0;
    final String bmiStatus = latestRecord != null ? latestRecord.bmiStatus : 'N/A';
    
    // Calculate HbA1c
    final double hba1cEst = averageGlucose > 0 ? (averageGlucose + 46.7) / 28.7 : 0.0;
    final String hba1cText = averageGlucose > 0 ? '${hba1cEst.toStringAsFixed(1)}%' : '--';
    final String hba1cStatus = averageGlucose > 0 
        ? (hba1cEst < 5.7 ? 'Optimal' : (hba1cEst < 6.5 ? 'Prediabetes' : 'Diabetes')) 
        : 'N/A';

    return Container(
      color: const Color(0xFFF8FAFC), // Same solid background color as other screens
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Screen Title
                Text(
                  'Profil Pasien',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 28),

                // Profile Header Card (Avatar + Info + Edit trigger)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Editable Avatar Stack (directly picks from gallery on tap)
                      GestureDetector(
                        onTap: () => _showEditProfileSheet(profile),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 108,
                              height: 108,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                gradient: _pickedImage == null
                                    ? const LinearGradient(
                                        colors: [AppTheme.primaryBlue, Color(0xFFEF4444)], // Blue to Red Gradient fallback
                                      )
                                    : null,
                                image: _pickedImage != null
                                    ? DecorationImage(
                                        image: kIsWeb
                                            ? NetworkImage(_pickedImage!.path)
                                            : FileImage(File(_pickedImage!.path)) as ImageProvider,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withOpacity(0.15),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: _pickedImage == null
                                  ? Center(
                                      child: Text(
                                        initialLetter,
                                        style: GoogleFonts.inter(
                                          fontSize: 44,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444), // Red Badge
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded, // Camera badge indicator
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Email
                      Text(
                        email,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Verified Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              color: AppTheme.primaryBlue,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pasien Terverifikasi',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Health Summary (Using Blue, White, and Red stats boxes)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ringkasan Kesehatan',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Age Box (Blue Accent)
                          _buildStatBox(
                            'Umur',
                            profile.age > 0 ? '${profile.age}' : '--',
                            'Tahun',
                            const Color(0xFFEEF3FF),
                            AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: 12),
                          // BMI Box (White/Neutral Accent)
                          _buildStatBox(
                            'BMI',
                            bmiValue > 0 ? bmiValue.toStringAsFixed(1) : '--',
                            bmiStatus,
                            Colors.white,
                            AppTheme.textDark,
                          ),
                          const SizedBox(width: 12),
                          // HbA1c Box (Red Accent)
                          _buildStatBox(
                            'HbA1c',
                            hba1cText,
                            hba1cStatus,
                            const Color(0xFFFEF2F2),
                            const Color(0xFFEF4444),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Settings Group (Alternating Red and Blue setting icons)
                _buildSettingsGroup([
                  _SettingsItem(
                    icon: Icons.picture_as_pdf_outlined,
                    title: 'Laporan Kesehatan',
                    subtitle: 'Unduh laporan riwayat PDF',
                    color: const Color(0xFFEF4444), // Red
                    onTap: () {
                      final warningCountVal = healthProvider.records.where((r) => r.glucoseLevel > 140).length;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportPreviewScreen(
                            name: name,
                            riskLevel: averageGlucose > 140 
                                ? 'Risiko Tinggi' 
                                : (averageGlucose > 110 ? 'Risiko Sedang' : 'Risiko Rendah'),
                            riskPercentage: averageGlucose > 140 ? 55.0 : (averageGlucose > 110 ? 30.0 : 12.0),
                            metabolicScore: averageGlucose > 140 ? 65.0 : (averageGlucose > 110 ? 78.0 : 88.0),
                            averageGlucose: averageGlucose > 0 ? averageGlucose.toStringAsFixed(0) : '0',
                            averageSteps: '8,100',
                            warningCount: warningCountVal,
                            pickedImage: _pickedImage,
                            historyEntries: healthProvider.records.map((r) => {
                              'title': 'Gula Darah: ${r.glucoseLevel.toInt()} mg/dL (${r.bmiStatus})',
                              'time': r.timestamp.isNotEmpty ? r.timestamp.substring(0, 10) : 'Baru saja',
                              'value': '${r.glucoseLevel.toInt()} mg/dL',
                              'status': r.glucoseStatus,
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                  _SettingsItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifikasi',
                    subtitle: 'Kelola peringatan kesehatan',
                    color: AppTheme.primaryBlue, // Blue
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privasi & Data',
                    subtitle: 'Kontrol pembagian data Anda',
                    color: const Color(0xFFEF4444), // Red
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.medical_services_outlined,
                    title: 'Profil Medis',
                    subtitle: 'Perbarui riwayat kesehatan',
                    color: AppTheme.primaryBlue, // Blue
                    onTap: () => _showEditProfileSheet(profile),
                  ),
                  _SettingsItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Bantuan & Dukungan',
                    subtitle: 'Dapatkan bantuan asisten',
                    color: const Color(0xFFEF4444), // Red
                    onTap: () {},
                  ),
                ]),
                const SizedBox(height: 20),

                // Sign Out Button (Styled in Red & White Theme)
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
                              healthProvider.clear();
                              authProvider.signOut();
                            },
                            child: Text('Keluar', style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Keluar dari Akun',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(
    String label,
    String value,
    String subtitle,
    Color bgColor,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor, width: 1),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textGrey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<_SettingsItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                onTap: item.onTap,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                title: Text(
                  item.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                subtitle: Text(
                  item.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textLight,
                  size: 20,
                ),
              ),
              if (i < items.length - 1)
                const Divider(
                  height: 1,
                  indent: 78,
                  endIndent: 20,
                  color: AppTheme.borderColor,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}
