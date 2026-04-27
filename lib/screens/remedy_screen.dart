import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';

class RemedyScreen extends StatefulWidget {
  final Map<String, dynamic> result;
  final String selectedCrop; // ✅ NEW

  const RemedyScreen({
    super.key,
    required this.result,
    required this.selectedCrop, // ✅ NEW
  });

  @override
  State<RemedyScreen> createState() => _RemedyScreenState();
}

class _RemedyScreenState extends State<RemedyScreen> {
  bool _isSaving = false;
  bool _isSaved = false;
  String _savedDistrict = ''; // ✅ NEW

  @override
  void initState() {
    super.initState();
    _saveScanResult();
  }

  Future<void> _saveScanResult() async {
    setState(() => _isSaving = true);
    try {
      // ✅ Get REAL GPS location
      final locationData = await LocationService.getCurrentLocation();

      final double lat = locationData['latitude'] as double;
      final double lng = locationData['longitude'] as double;
      final String district = locationData['district'] as String;
      final bool locationAvailable = locationData['locationAvailable'] as bool;

      await AuthService.saveScanResult(
        disease: widget.result['disease'] ?? 'Unknown',
        crop: widget.selectedCrop, // ✅ REAL CROP from scanner
        severity: widget.result['severity'] ?? 'None',
        confidence: widget.result['confidence'] ?? 'Low',
        lat: lat, // ✅ REAL GPS
        lng: lng, // ✅ REAL GPS
        district: district, // ✅ REAL DISTRICT
        locationAvailable: locationAvailable,
      );

      if (mounted) {
        setState(() {
          _isSaved = true;
          _savedDistrict = district; // ✅ Show district
        });
      }
    } catch (e) {
      debugPrint('Error saving: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disease = widget.result['disease'] ?? 'Unknown';
    final confidence = widget.result['confidence'] ?? 'Low';
    final description = widget.result['description'] ?? '';
    final sinhalaRemedy = widget.result['sinhala_remedy'] ?? '';
    final organicRemedy = widget.result['organic_remedy'] ?? '';
    final chemicalRemedy = widget.result['chemical_remedy'] ?? '';
    final severity = widget.result['severity'] ?? 'None';
    final isHealthy = disease.toLowerCase() == 'healthy';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Diagnosis Result'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.textLight,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_isSaved)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Icon(Icons.cloud_done, color: AppColors.textLight),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultHeader(
                disease,
                confidence,
                widget.selectedCrop, // ✅ REAL CROP
                severity,
                isHealthy,
              ),
              const SizedBox(height: 16),

              // ✅ Saving indicator
              if (_isSaving)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Getting location & saving...',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),

              // ✅ Saved confirmation WITH real district
              if (_isSaved)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.cloud_done,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Saved to community database ✅',
                            style: AppTextStyles.bodyText.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      // ✅ Show real district name
                      if (_savedDistrict.isNotEmpty &&
                          _savedDistrict != 'Unknown District')
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppColors.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$_savedDistrict District',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),
              _buildInfoCard('About Disease', description, Icons.info_outline),
              const SizedBox(height: 12),
              _buildInfoCard('Sinhala උපදෙස්', sinhalaRemedy, Icons.language),
              const SizedBox(height: 12),
              _buildRemedyCard(
                'Organic Treatment',
                organicRemedy,
                AppColors.healthy,
              ),
              const SizedBox(height: 12),
              _buildRemedyCard(
                'Chemical Treatment',
                chemicalRemedy,
                AppColors.warning,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Scan Another'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultHeader(
    String disease,
    String confidence,
    String crop,
    String severity,
    bool isHealthy,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHealthy ? AppColors.healthy : AppColors.danger,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            isHealthy ? Icons.check_circle : Icons.warning_amber_rounded,
            color: AppColors.textLight,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            disease,
            style: AppTextStyles.heading2.copyWith(color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Crop: $crop',
            style: AppTextStyles.bodyText.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadge('Confidence: $confidence'),
              const SizedBox(width: 8),
              if (!isHealthy) _buildBadge('Severity: $severity'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: AppColors.textLight),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.heading3),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: AppTextStyles.bodyText),
        ],
      ),
    );
  }

  Widget _buildRemedyCard(String title, String content, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading3.copyWith(color: color)),
          const SizedBox(height: 8),
          Text(content, style: AppTextStyles.bodyText),
        ],
      ),
    );
  }
}
