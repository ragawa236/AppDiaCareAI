import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'explainable_ai_screen.dart';

class RiskPredictionScreen extends StatefulWidget {
  const RiskPredictionScreen({super.key});

  @override
  State<RiskPredictionScreen> createState() => _RiskPredictionScreenState();
}

class _RiskPredictionScreenState extends State<RiskPredictionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form states
  String? _gender;
  final TextEditingController _ageController = TextEditingController();
  String? _hypertension; // 'Ya' or 'Tidak'
  String? _heartDisease; // 'Ya' or 'Tidak'
  String? _smokingHistory;
  final TextEditingController _bmiController = TextEditingController();
  final TextEditingController _hba1cController = TextEditingController();
  final TextEditingController _glucoseController = TextEditingController();

  // BMI Helper Calculator states
  bool _showBmiHelper = false;
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  // Loading and result states
  bool _isLoading = false;
  String _loadingText = 'Menghubungkan ke AI Engine...';
  double? _computedRisk;
  double? _computedMetabolicScore;
  String? _computedRiskLevel;
  Color? _computedRiskColor;

  final List<String> _smokingOptions = [
    'Never',
    'Former',
    'Current',
    'Not Current',
    'Ever',
    'No Info',
  ];

  @override
  void dispose() {
    _ageController.dispose();
    _bmiController.dispose();
    _hba1cController.dispose();
    _glucoseController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _calculateBmi() {
    final weight = double.tryParse(_weightController.text);
    final heightCm = double.tryParse(_heightController.text);

    if (weight != null && heightCm != null && heightCm > 0) {
      final heightM = heightCm / 100;
      final bmi = weight / (heightM * heightM);
      setState(() {
        _bmiController.text = bmi.toStringAsFixed(1);
        _showBmiHelper = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('BMI berhasil dihitung: ${bmi.toStringAsFixed(1)}'),
          backgroundColor: AppTheme.primaryBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _loadingText = 'Mengumpulkan data klinis...';
      });

      // Run dynamic simulation texts
      Timer(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _loadingText = 'Menganalisis faktor risiko metabolik...';
          });
        }
      });

      Timer(const Duration(milliseconds: 1300), () {
        if (mounted) {
          setState(() {
            _loadingText = 'Mengevaluasi parameter HbA1c & Glukosa...';
          });
        }
      });

      Timer(const Duration(milliseconds: 2000), () {
        if (mounted) {
          setState(() {
            _loadingText = 'Membuat laporan risiko AI...';
          });
        }
      });

      Timer(const Duration(milliseconds: 2600), () {
        if (!mounted) return;

        // Perform calculation
        final age = double.tryParse(_ageController.text) ?? 30.0;
        final bmi = double.tryParse(_bmiController.text) ?? 22.0;
        final hba1c = double.tryParse(_hba1cController.text) ?? 5.5;
        final glucose = double.tryParse(_glucoseController.text) ?? 100.0;
        final isHypertension = _hypertension == 'Ya';
        final isHeartDisease = _heartDisease == 'Ya';

        // Base risk score calculations based on medical heuristics
        double basePoints = 0;

        // Age points (max 15)
        basePoints += math.min(15.0, (age * 0.2));

        // BMI points (max 15)
        if (bmi >= 30) {
          basePoints += 15;
        } else if (bmi >= 25) {
          basePoints += 8;
        } else if (bmi < 18.5) {
          basePoints += 2; // Underweight also minor metabolic disruption
        }

        // Hypertension (12 points)
        if (isHypertension) basePoints += 12;

        // Heart Disease (10 points)
        if (isHeartDisease) basePoints += 10;

        // Smoking history points
        if (_smokingHistory == 'Current' || _smokingHistory == 'Ever') {
          basePoints += 6;
        } else if (_smokingHistory == 'Former' || _smokingHistory == 'Not Current') {
          basePoints += 3;
        }

        // HbA1c points (very strong factor, max 30)
        if (hba1c >= 6.5) {
          basePoints += 30;
        } else if (hba1c >= 5.7) {
          basePoints += 15;
        } else if (hba1c >= 4.0) {
          basePoints += 2;
        }

        // Blood Glucose points (strong factor, max 25)
        if (glucose >= 200) {
          basePoints += 25;
        } else if (glucose >= 140) {
          basePoints += 15;
        } else if (glucose >= 100) {
          basePoints += 5;
        }

        // Final score calculation
        double riskPercentage = basePoints;
        if (riskPercentage < 2) riskPercentage = 2.0;
        if (riskPercentage > 98) riskPercentage = 98.0;

        // Metabolic score out of 100
        double metScore = 100 - (basePoints * 0.7);
        if (metScore < 10) metScore = 10.0;
        if (metScore > 98) metScore = 98.0;

        // Risk Level classification
        String level;
        Color levelColor;
        if (riskPercentage < 20) {
          level = 'Risiko Rendah';
          levelColor = const Color(0xFF16A34A); // Green
        } else if (riskPercentage < 50) {
          level = 'Risiko Sedang';
          levelColor = const Color(0xFFF59E0B); // Orange
        } else {
          level = 'Risiko Tinggi';
          levelColor = const Color(0xFFEF4444); // Red
        }

        setState(() {
          _isLoading = false;
          _computedRisk = riskPercentage;
          _computedMetabolicScore = metScore;
          _computedRiskLevel = level;
          _computedRiskColor = levelColor;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          'Analisis Risiko AI',
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
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFEEF3FF)],
                  stops: [0.3, 1.0],
                ),
              ),
            ),
          ),
          
          if (_computedRisk == null)
            _buildFormView()
          else
            _buildResultView(),

          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E40AF), Color(0xFF1A56DB)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
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
                        Icons.auto_awesome_rounded,
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
                            'Prediksi Akurasi AI',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Masukkan data biologis & klinis Anda untuk menghitung probabilitas risiko diabetes secara personal.',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 1: Demografi & Fisik
              _buildSectionHeader('1. Data Demografi & Fisik'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gender Dropdown
                    _buildFieldLabel('Jenis Kelamin (Gender)'),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(
                        hintText: 'Pilih jenis kelamin',
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textGrey),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (val) => setState(() => _gender = val),
                      validator: (val) => val == null ? 'Jenis kelamin wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // Age Field
                    _buildFieldLabel('Usia (Age)'),
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: 35',
                        suffixText: 'Tahun',
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Usia wajib diisi';
                        final num = int.tryParse(val);
                        if (num == null || num <= 0 || num > 120) {
                          return 'Masukkan usia yang valid (1-120)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // BMI Field
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFieldLabel('Indeks Massa Tubuh (BMI)'),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showBmiHelper = !_showBmiHelper;
                            });
                          },
                          child: Text(
                            _showBmiHelper ? 'Sembunyikan Kalkulator' : 'Hitung BMI?',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_showBmiHelper) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.15)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _weightController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      hintText: 'Berat (kg)',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _heightController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: 'Tinggi (cm)',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: _calculateBmi,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  'Hitung & Terapkan',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _bmiController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: 'Contoh: 24.5',
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'BMI wajib diisi';
                        final num = double.tryParse(val);
                        if (num == null || num <= 5 || num > 70) {
                          return 'Masukkan nilai BMI yang valid (5.0 - 70.0)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 2: Riwayat Medis
              _buildSectionHeader('2. Riwayat Medis & Gaya Hidup'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hypertension Field
                    _buildFieldLabel('Hipertensi (Hypertension)'),
                    _buildRadioGroup(
                      value: _hypertension,
                      onChanged: (val) => setState(() => _hypertension = val),
                    ),
                    const SizedBox(height: 20),

                    // Heart Disease Field
                    _buildFieldLabel('Penyakit Jantung (Heart Disease)'),
                    _buildRadioGroup(
                      value: _heartDisease,
                      onChanged: (val) => setState(() => _heartDisease = val),
                    ),
                    const SizedBox(height: 20),

                    // Smoking History
                    _buildFieldLabel('Riwayat Merokok (Smoking History)'),
                    DropdownButtonFormField<String>(
                      value: _smokingHistory,
                      decoration: const InputDecoration(
                        hintText: 'Pilih riwayat merokok',
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textGrey),
                      items: _smokingOptions
                          .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                          .toList(),
                      onChanged: (val) => setState(() => _smokingHistory = val),
                      validator: (val) => val == null ? 'Riwayat merokok wajib diisi' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 3: Hasil Laboratorium
              _buildSectionHeader('3. Parameter Klinis / Lab'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HbA1c Level
                    _buildFieldLabel('Kadar HbA1c'),
                    TextFormField(
                      controller: _hba1cController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: 'Contoh: 5.7',
                        suffixText: '%',
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Kadar HbA1c wajib diisi';
                        final num = double.tryParse(val);
                        if (num == null || num < 2 || num > 20) {
                          return 'Masukkan nilai HbA1c valid (2.0% - 20.0%)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Blood Glucose Level
                    _buildFieldLabel('Kadar Glukosa Darah (Blood Glucose Level)'),
                    TextFormField(
                      controller: _glucoseController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: 140',
                        suffixText: 'mg/dL',
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Kadar glukosa wajib diisi';
                        final num = int.tryParse(val);
                        if (num == null || num < 30 || num > 600) {
                          return 'Masukkan nilai glukosa valid (30 - 600 mg/dL)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: AppTheme.primaryBlue.withOpacity(0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.analytics_rounded, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Mulai Analisis AI',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final risk = _computedRisk ?? 0.0;
    final metabolic = _computedMetabolicScore ?? 100.0;
    final level = _computedRiskLevel ?? 'Risiko Rendah';
    final color = _computedRiskColor ?? Colors.green;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Top Animation Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Gauge painter
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CustomPaint(
                      painter: _PredictionGaugePainter(progress: risk / 100, color: color),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${risk.toStringAsFixed(0)}%',
                              style: GoogleFonts.inter(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                color: color,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              'RISIKO DIABETES',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textGrey,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Status Indicator Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          risk >= 50
                              ? Icons.warning_rounded
                              : (risk >= 20 ? Icons.info_rounded : Icons.check_circle_rounded),
                          color: color,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          level,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    _getRiskDescription(risk),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textGrey,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Metabolic Score & Key Metrics
            Row(
              children: [
                Expanded(
                  child: _buildResultMetricCard(
                    icon: Icons.favorite_rounded,
                    iconColor: const Color(0xFFEF4444),
                    label: 'Skor Metabolik',
                    value: '${metabolic.toStringAsFixed(0)}',
                    suffix: '/100',
                    desc: 'Kesehatan seluler Anda',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildResultMetricCard(
                    icon: Icons.water_drop_rounded,
                    iconColor: AppTheme.primaryBlue,
                    label: 'HbA1c / Glukosa',
                    value: _hba1cController.text,
                    suffix: '%',
                    desc: 'Rata-rata: ${_glucoseController.text} mg/dL',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Personalized Advice Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryBlue, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rekomendasi AI Personal',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._generateAiTips(risk).map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: AppTheme.primaryBlue, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tip,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textDark,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Explainable AI Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExplainableAiScreen(
                        risk: risk,
                        gender: _gender,
                        age: double.tryParse(_ageController.text) ?? 30.0,
                        hypertension: _hypertension,
                        heartDisease: _heartDisease,
                        smokingHistory: _smokingHistory,
                        bmi: double.tryParse(_bmiController.text) ?? 22.0,
                        hba1c: double.tryParse(_hba1cController.text) ?? 5.5,
                        glucose: double.tryParse(_glucoseController.text) ?? 100.0,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
                label: Text(
                  'Penjelasan Detail AI (Explainable AI)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  shadowColor: AppTheme.darkNavy.withOpacity(0.3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Navigation Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _computedRisk = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Ulangi Analisis',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Kembali ke Home',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildResultMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String suffix,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textGrey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  suffix,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textGrey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppTheme.darkNavy,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  Widget _buildRadioGroup({
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => onChanged('Ya'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: value == 'Ya' ? AppTheme.primaryBlue.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: value == 'Ya' ? AppTheme.primaryBlue : AppTheme.borderColor,
                  width: value == 'Ya' ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: 'Ya',
                    groupValue: value,
                    onChanged: onChanged,
                    activeColor: AppTheme.primaryBlue,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ya',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: value == 'Ya' ? FontWeight.w700 : FontWeight.w500,
                      color: value == 'Ya' ? AppTheme.primaryBlue : AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () => onChanged('Tidak'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: value == 'Tidak' ? AppTheme.primaryBlue.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: value == 'Tidak' ? AppTheme.primaryBlue : AppTheme.borderColor,
                  width: value == 'Tidak' ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: 'Tidak',
                    groupValue: value,
                    onChanged: onChanged,
                    activeColor: AppTheme.primaryBlue,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tidak',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: value == 'Tidak' ? FontWeight.w700 : FontWeight.w500,
                      color: value == 'Tidak' ? AppTheme.primaryBlue : AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 4,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 24),
              Text(
                'Menganalisis Risiko...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _loadingText,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRiskDescription(double risk) {
    if (risk < 20) {
      return 'Bagus sekali! Profil biologis Anda menunjukkan tingkat risiko metabolik yang rendah. Pertahankan pola hidup sehat Anda.';
    } else if (risk < 50) {
      return 'Risiko Anda berada di tingkat sedang. Direkomendasikan untuk memperhatikan pola makan rendah gula, berolahraga minimal 150 menit seminggu, dan cek kesehatan berkala.';
    } else {
      return 'Perhatian. Skor risiko Anda tinggi. Sangat disarankan untuk segera melakukan konsultasi dengan dokter spesialis penyakit dalam dan membatasi konsumsi karbohidrat sederhana.';
    }
  }

  List<String> _generateAiTips(double risk) {
    final List<String> tips = [];
    final bmi = double.tryParse(_bmiController.text) ?? 22.0;
    final glucose = double.tryParse(_glucoseController.text) ?? 100.0;
    final hba1c = double.tryParse(_hba1cController.text) ?? 5.5;

    if (risk < 20) {
      tips.add('Lanjutkan aktivitas fisik teratur Anda.');
      tips.add('Jaga asupan serat harian di atas 25 gram.');
      tips.add('Lakukan pemeriksaan glukosa berkala minimal 6 bulan sekali.');
    } else {
      if (bmi >= 25.0) {
        tips.add('Fokus menurunkan berat badan 5-10% dari berat saat ini untuk meningkatkan sensitivitas insulin.');
      }
      if (glucose >= 126.0 || hba1c >= 6.5) {
        tips.add('Konsultasikan dengan dokter terkait hasil laboratorium yang berada di atas ambang batas normal.');
      }
      if (_smokingHistory == 'Current') {
        tips.add('Kurangi atau hentikan merokok secara bertahap karena meningkatkan komplikasi kardiovaskular secara drastis.');
      }
      if (_hypertension == 'Ya') {
        tips.add('Batasi asupan garam/sodium maksimal 2000mg per hari untuk menjaga tekanan darah stabil.');
      }
      tips.add('Utamakan karbohidrat kompleks (oat, beras merah, sayuran) dibanding karbohidrat sederhana.');
      tips.add('Lakukan olahraga aerobik (seperti jalan cepat) selama 30 menit per hari.');
    }
    return tips.take(3).toList();
  }
}

class _PredictionGaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _PredictionGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 16;
    const strokeWidth = 14.0;
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
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.6), color],
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
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(dotX, dotY), 8, dotBorderPaint);
    canvas.drawCircle(Offset(dotX, dotY), 5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
