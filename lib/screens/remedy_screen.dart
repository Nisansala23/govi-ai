import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RemedyScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const RemedyScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final disease = result['disease'] ?? 'Unknown';
    final confidence = result['confidence'] ?? 'Low';
    final crop = result['crop'] ?? 'Unknown';
    final description = result['description'] ?? '';
    final sinhalaRemedy = result['sinhala_remedy'] ?? '';
    final organicRemedy = result['organic_remedy'] ?? '';
    final chemicalRemedy = result['chemical_remedy'] ?? '';
    final severity = result['severity'] ?? 'None';
    final isHealthy = disease.toLowerCase() == 'healthy';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Diagnosis Result')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultHeader(
                disease,
                confidence,
                crop,
                severity,
                isHealthy,
              ),
              const SizedBox(height: 16),
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
