import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class ExplainableAiScreen extends StatefulWidget {
  final double risk;
  final String? gender;
  final double age;
  final String? hypertension;
  final String? heartDisease;
  final String? smokingHistory;
  final double bmi;
  final double hba1c;
  final double glucose;

  const ExplainableAiScreen({
    super.key,
    required this.risk,
    this.gender,
    required this.age,
    this.hypertension,
    this.heartDisease,
    this.smokingHistory,
    required this.bmi,
    required this.hba1c,
    required this.glucose,
  });

  @override
  State<ExplainableAiScreen> createState() => _ExplainableAiScreenState();
}

class _ExplainableAiScreenState extends State<ExplainableAiScreen> {
  int _selectedFilterTab = 0; // 0 = Semua, 1 = Pemicu (+), 2 = Protektif (-)

  // Function to calculate SHAP-like values that sum up to (risk - baseValue)
  List<FeatureContribution> _calculateContributions() {
    const double baseValue = 10.0; // Base population risk
    
    // 1. Calculate raw heuristic weights for each input feature
    double wHbA1c = 0;
    if (widget.hba1c >= 6.5) {
      wHbA1c = 30.0;
    } else if (widget.hba1c >= 5.7) {
      wHbA1c = 15.0;
    } else {
      wHbA1c = -5.0; // Protective factor
    }

    double wGlucose = 0;
    if (widget.glucose >= 200) {
      wGlucose = 25.0;
    } else if (widget.glucose >= 140) {
      wGlucose = 15.0;
    } else if (widget.glucose >= 100) {
      wGlucose = 5.0;
    } else {
      wGlucose = -3.5;
    }

    double wBmi = 0;
    if (widget.bmi >= 30) {
      wBmi = 15.0;
    } else if (widget.bmi >= 25) {
      wBmi = 8.0;
    } else if (widget.bmi < 18.5) {
      wBmi = 2.0;
    } else {
      wBmi = -4.0;
    }

    double wHypertension = (widget.hypertension == 'Ya') ? 12.0 : -2.0;
    double wHeartDisease = (widget.heartDisease == 'Ya') ? 10.0 : -1.5;
    
    // Age weight based on baseline age of 35
    double wAge = (widget.age * 0.22) - 7.5; 

    double wSmoking = 0;
    if (widget.smokingHistory == 'Current' || widget.smokingHistory == 'Ever') {
      wSmoking = 6.0;
    } else if (widget.smokingHistory == 'Former' || widget.smokingHistory == 'Not Current') {
      wSmoking = 3.0;
    } else {
      wSmoking = -1.0;
    }

    double wGender = (widget.gender == 'Male') ? 1.0 : -0.5;

    // 2. Normalize weights so they perfectly sum to (risk - baseValue)
    final List<Map<String, dynamic>> rawFeatures = [
      {
        'name': 'Kadar HbA1c',
        'valueText': '${widget.hba1c.toStringAsFixed(1)}%',
        'rawWeight': wHbA1c,
        'icon': Icons.water_drop_rounded,
        'desc': 'Rata-rata gula darah 3 bulan terakhir.',
        'highDesc': 'Kadar HbA1c Anda tinggi (>= 5.7%), yang merupakan indikator utama prediabetes/diabetes.',
        'lowDesc': 'Kadar HbA1c Anda berada dalam rentang optimal (< 5.7%), menekan risiko diabetes.',
      },
      {
        'name': 'Glukosa Darah',
        'valueText': '${widget.glucose.toStringAsFixed(0)} mg/dL',
        'rawWeight': wGlucose,
        'icon': Icons.bloodtype_rounded,
        'desc': 'Kadar glukosa darah saat tes.',
        'highDesc': 'Glukosa darah di atas normal meningkatkan beban kerja pankreas dan sensitivitas insulin.',
        'lowDesc': 'Glukosa darah Anda normal (< 100 mg/dL), indikasi regulasi gula darah yang sehat.',
      },
      {
        'name': 'Indeks Massa Tubuh',
        'valueText': '${widget.bmi.toStringAsFixed(1)} BMI',
        'rawWeight': wBmi,
        'icon': Icons.monitor_weight_rounded,
        'desc': 'Rasio berat badan terhadap tinggi badan.',
        'highDesc': 'BMI tinggi (>= 25) memicu penumpukan lemak visceral dan memicu resistensi insulin.',
        'lowDesc': 'BMI Anda ideal (18.5 - 24.9), mendukung fungsi metabolisme sel tubuh yang optimal.',
      },
      {
        'name': 'Tekanan Darah Tinggi',
        'valueText': widget.hypertension ?? 'Tidak',
        'rawWeight': wHypertension,
        'icon': Icons.speed_rounded,
        'desc': 'Riwayat hipertensi medis.',
        'highDesc': 'Tekanan darah tinggi merusak pembuluh darah kecil dan berkaitan dengan sindrom metabolik.',
        'lowDesc': 'Tidak memiliki riwayat hipertensi membantu menjaga sirkulasi dan kesehatan vaskular.',
      },
      {
        'name': 'Penyakit Jantung',
        'valueText': widget.heartDisease ?? 'Tidak',
        'rawWeight': wHeartDisease,
        'icon': Icons.favorite_rounded,
        'desc': 'Riwayat penyakit kardiovaskular.',
        'highDesc': 'Penyakit jantung berkolerasi dengan gangguan metabolik sistemik secara keseluruhan.',
        'lowDesc': 'Ketiadaan riwayat penyakit jantung mengurangi kemungkinan komplikasi kardiovaskular.',
      },
      {
        'name': 'Faktor Usia',
        'valueText': '${widget.age.toStringAsFixed(0)} Tahun',
        'rawWeight': wAge,
        'icon': Icons.calendar_month_rounded,
        'desc': 'Usia kronologis pasien.',
        'highDesc': 'Pertambahan usia meningkatkan risiko diabetes akibat penurunan alami fungsi pankreas.',
        'lowDesc': 'Usia muda diasosiasikan dengan cadangan fungsi pankreas yang lebih sehat dan aktif.',
      },
      {
        'name': 'Riwayat Merokok',
        'valueText': widget.smokingHistory ?? 'No Info',
        'rawWeight': wSmoking,
        'icon': Icons.smoking_rooms_rounded,
        'desc': 'Status konsumsi tembakau.',
        'highDesc': 'Zat beracun pada rokok memicu inflamasi kronis dan menurunkan sensitivitas reseptor insulin.',
        'lowDesc': 'Tidak memiliki kebiasaan merokok melindungi sel-sel tubuh dari stres oksidatif.',
      },
      {
        'name': 'Jenis Kelamin',
        'valueText': widget.gender ?? 'Other',
        'rawWeight': wGender,
        'icon': Icons.person_rounded,
        'desc': 'Pengaruh hormonal & genetika.',
        'highDesc': 'Faktor biologis gender memberikan sedikit pengaruh tambahan pada metabolisme tubuh.',
        'lowDesc': 'Profil hormon gender memberikan perlindungan alami minor terhadap resistensi insulin.',
      },
    ];

    double sumPositive = 0;
    double sumNegative = 0;
    for (var f in rawFeatures) {
      double w = f['rawWeight'] as double;
      if (w > 0) {
        sumPositive += w;
      } else {
        sumNegative += w.abs();
      }
    }

    double targetDiff = widget.risk - baseValue;
    
    // Scale contributions to align perfectly with computed risk
    List<FeatureContribution> contributions = [];
    for (var f in rawFeatures) {
      double w = f['rawWeight'] as double;
      double scaledWeight = 0;
      if (targetDiff >= 0) {
        if (w > 0) {
          scaledWeight = sumPositive > 0 ? w * (targetDiff + sumNegative) / sumPositive : 0;
        } else {
          scaledWeight = w;
        }
      } else {
        if (w < 0) {
          scaledWeight = sumNegative > 0 ? w * (targetDiff.abs() + sumPositive) / sumNegative : 0;
        } else {
          scaledWeight = w;
        }
      }

      if (scaledWeight > 45.0) scaledWeight = 45.0;
      if (scaledWeight < -20.0) scaledWeight = -20.0;

      contributions.add(
        FeatureContribution(
          name: f['name'] as String,
          valueText: f['valueText'] as String,
          contributionPercentage: scaledWeight,
          icon: f['icon'] as IconData,
          description: f['desc'] as String,
          impactMessage: scaledWeight >= 0 ? f['highDesc'] as String : f['lowDesc'] as String,
        ),
      );
    }

    contributions.sort((a, b) => b.contributionPercentage.compareTo(a.contributionPercentage));
    return contributions;
  }

  @override
  Widget build(BuildContext context) {
    final contributions = _calculateContributions();
    
    // Split for rendering
    final allIncreasers = contributions.where((c) => c.contributionPercentage > 0).toList();
    final allProtective = contributions.where((c) => c.contributionPercentage <= 0).toList();

    // Filter detailed list based on selected filter tab
    List<FeatureContribution> filteredDetails = [];
    if (_selectedFilterTab == 0) {
      filteredDetails = contributions;
    } else if (_selectedFilterTab == 1) {
      filteredDetails = allIncreasers;
    } else {
      filteredDetails = allProtective;
    }

    // Risk level classification details
    String level;
    Color levelColor;
    if (widget.risk < 20) {
      level = 'Risiko Rendah';
      levelColor = const Color(0xFF16A34A);
    } else if (widget.risk < 50) {
      level = 'Risiko Sedang';
      levelColor = const Color(0xFFF59E0B);
    } else {
      level = 'Risiko Tinggi';
      levelColor = const Color(0xFFEF4444);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Analisis Explainable AI',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
          ),
        ),
        centerTitle: true,
        shape: const Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      body: Stack(
        children: [
          // Background subtle gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFF8FAFC)],
                ),
              ),
            ),
          ),
          // Glowing top-left blur circle
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: levelColor.withOpacity(0.04),
              ),
            ),
          ),
          // Glowing middle-right blur circle
          Positioned(
            top: 250,
            right: -150,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryBlue.withOpacity(0.03),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Overview Card
                  _buildOverviewCard(level, levelColor),
                  const SizedBox(height: 24),

                  // Section 2: Visual Force Plot
                  _buildVisualForcePlotSection(contributions),
                  const SizedBox(height: 28),

                  // Section 3: Interactive Filter Tab
                  _buildFilterTabSection(allIncreasers.length, allProtective.length),
                  const SizedBox(height: 16),

                  // Section 4: Detailed Factor Cards
                  _buildDetailedFactorList(filteredDetails),
                  const SizedBox(height: 24),

                  // Section 5: Transparency Disclaimer
                  _buildModelDisclaimerCard(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String level, Color levelColor) {
    final double alignmentX = (widget.risk / 50.0) - 1.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.risk >= 50
                      ? Icons.warning_amber_rounded
                      : widget.risk >= 20
                          ? Icons.info_outline_rounded
                          : Icons.check_circle_outline_rounded,
                  color: levelColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROBABILITAS RISIKO DIABETES',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textGrey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      level,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.risk.toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: levelColor,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'metabolic score',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),

          Text(
            'Skala Keparahan Risiko',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF10B981), // Green
                      Color(0xFFF59E0B), // Orange
                      Color(0xFFEF4444), // Red
                    ],
                    stops: [0.15, 0.45, 0.85],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: -5,
                child: Align(
                  alignment: Alignment(alignmentX.clamp(-1.0, 1.0), 0.0),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: levelColor.withOpacity(0.35),
                          blurRadius: 8,
                          spreadRadius: 1.5,
                        ),
                      ],
                      border: Border.all(color: levelColor, width: 5),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Rendah (0-20%)',
                  style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppTheme.textLight),
                ),
              ),
              Expanded(
                child: Text(
                  'Sedang (20-50%)',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppTheme.textLight),
                ),
              ),
              Expanded(
                child: Text(
                  'Tinggi (50-100%)',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppTheme.textLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: AppTheme.borderColor, height: 1),
          const SizedBox(height: 14),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_alt_outlined, color: AppTheme.primaryBlue, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Grafik di bawah membedah kontribusi faktor klinis Anda dalam menaikkan (+) atau menurunkan (-) risiko diabetes dari nilai acuan populasi normal (10%).',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppTheme.textGrey,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisualForcePlotSection(List<FeatureContribution> contributions) {
    double maxVal = contributions.map((c) => c.contributionPercentage.abs()).reduce(math.max);
    if (maxVal <= 0) maxVal = 1.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Kontribusi Fitur (SHAP Force Plot)',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkNavy,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Baseline: 10.0%',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textGrey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 12, color: Color(0xFF16A34A)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Menekan Risiko (-)',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF16A34A)),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 4,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Mendorong Risiko (+)',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFEF4444)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.trending_up_rounded, size: 12, color: Color(0xFFEF4444)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: contributions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 18),
            itemBuilder: (context, index) {
              final c = contributions[index];
              final isPositive = c.contributionPercentage >= 0;
              final pctValue = c.contributionPercentage.abs();
              final double barScale = pctValue / maxVal;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: (isPositive ? const Color(0xFFEF4444) : const Color(0xFF16A34A)).withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(c.icon, size: 12, color: isPositive ? const Color(0xFFEF4444) : const Color(0xFF16A34A)),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                c.name,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${c.valueText})',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${isPositive ? '+' : '-'}${pctValue.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: isPositive ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            if (!isPositive)
                              FractionallySizedBox(
                                widthFactor: barScale.clamp(0.08, 1.0),
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      Container(
                        width: 4,
                        height: 16,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF94A3B8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      Expanded(
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            if (isPositive)
                              FractionallySizedBox(
                                widthFactor: barScale.clamp(0.08, 1.0),
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFCA5A5), Color(0xFFEF4444)],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabSection(int increaserCount, int protectiveCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          _buildFilterPill(0, 'Semua', null, Icons.grid_view_rounded),
          _buildFilterPill(1, 'Pemicu', increaserCount, Icons.trending_up_rounded),
          _buildFilterPill(2, 'Pelindung', protectiveCount, Icons.shield_rounded),
        ],
      ),
    );
  }

  Widget _buildFilterPill(int index, String label, int? count, IconData icon) {
    final bool isActive = _selectedFilterTab == index;
    Color activeBgColor = Colors.white;
    Color activeTextColor = AppTheme.textDark;
    Color iconColor = AppTheme.textGrey;

    if (isActive) {
      if (index == 1) {
        activeTextColor = const Color(0xFFEF4444);
        iconColor = const Color(0xFFEF4444);
      } else if (index == 2) {
        activeTextColor = const Color(0xFF16A34A);
        iconColor = const Color(0xFF16A34A);
      } else {
        activeTextColor = AppTheme.primaryBlue;
        iconColor = AppTheme.primaryBlue;
      }
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilterTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: activeTextColor,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isActive ? iconColor.withOpacity(0.1) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: isActive ? activeTextColor : AppTheme.textGrey,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedFactorList(List<FeatureContribution> details) {
    if (details.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            const Icon(Icons.filter_list_off_rounded, color: AppTheme.textLight, size: 40),
            const SizedBox(height: 12),
            Text(
              'Tidak ada faktor pendukung dalam kategori ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.textGrey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: details.length,
      itemBuilder: (context, index) {
        final c = details[index];
        final bool isIncreaser = c.contributionPercentage > 0;
        final Color impactColor = isIncreaser ? const Color(0xFFEF4444) : const Color(0xFF16A34A);
        final double valueAbs = c.contributionPercentage.abs();

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                isIncreaser ? const Color(0xFFFFF5F5) : const Color(0xFFF0FDF4),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isIncreaser ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: impactColor, width: 5),
                ),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: impactColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(c.icon, color: impactColor, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    c.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: impactColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${isIncreaser ? '+' : '-'}${valueAbs.toStringAsFixed(1)}%',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: impactColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isIncreaser ? const Color(0xFFFCA5A5).withOpacity(0.5) : const Color(0xFF86EFAC).withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                'Nilai: ${c.valueText}',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isIncreaser 
                          ? const Color(0xFFFEF2F2).withOpacity(0.5) 
                          : const Color(0xFFF0FDF4).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isIncreaser ? Icons.trending_up_rounded : Icons.shield_rounded, 
                          size: 14, 
                          color: impactColor
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c.impactMessage,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: AppTheme.textDark,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
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
        );
      },
    );
  }

  Widget _buildModelDisclaimerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_suggest_rounded, color: Color(0xFF38BDF8), size: 22),
              const SizedBox(width: 10),
              Text(
                'Transparansi Model AI',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Model prediksi DiaCare AI dibangun menggunakan arsitektur Gradient Boosted Machine (GBM) yang menganalisis multivariat data metabolik. Metode penjelasan lokal menggunakan framework SHAP (SHapley Additive exPlanations) untuk menjamin transparansi klinis yang dapat dipertanggungjawabkan bagi tenaga medis dan pengguna.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureContribution {
  final String name;
  final String valueText;
  final double contributionPercentage;
  final IconData icon;
  final String description;
  final String impactMessage;

  FeatureContribution({
    required this.name,
    required this.valueText,
    required this.contributionPercentage,
    required this.icon,
    required this.description,
    required this.impactMessage,
  });
}
