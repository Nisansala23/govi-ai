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

    final Color statusColor =
        isHealthy ? AppColors.healthy : AppColors.danger;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Diagnosis Result'),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(
                disease,
                crop,
                confidence,
                severity,
                isHealthy,
                statusColor,
              ),

              const SizedBox(height: 16),

              _buildCard(
                "About Disease",
                description,
                Icons.info_outline,
              ),

              const SizedBox(height: 12),

              _buildCard(
                "Sinhala උපදෙස්",
                sinhalaRemedy,
                Icons.language,
              ),

              const SizedBox(height: 12),

              _buildRemedy(
                "Organic Treatment",
                organicRemedy,
                AppColors.healthy,
              ),

              const SizedBox(height: 12),

              _buildRemedy(
                "Chemical Treatment",
                chemicalRemedy,
                AppColors.warning,
              ),

              const SizedBox(height: 20),

              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────── HEADER ─────────────────

  Widget _buildHeader(
    String disease,
    String crop,
    String confidence,
    String severity,
    bool isHealthy,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            isHealthy
                ? Icons.check_circle
                : Icons.warning_amber_rounded,
            color: Colors.white,
            size: 48,
          ),

          const SizedBox(height: 10),

          Text(
            disease,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Crop: $crop",
            style: const TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            children: [
              _badge("Confidence: $confidence"),
              if (!isHealthy) _badge("Severity: $severity"),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────── BADGE ─────────────────

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  // ───────────────── CARD ─────────────────

  Widget _buildCard(String title, String content, IconData icon) {
    if (content.isEmpty) {
      return const SizedBox();
    }

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
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }

  // ───────────────── REMEDY CARD ─────────────────

  Widget _buildRemedy(String title, String content, Color color) {
    if (content.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }

  // ───────────────── ACTION BUTTONS ─────────────────

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text("Scan Another"),
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // future: save result to Firestore for stats
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Result saved (future feature)"),
                ),
              );
            },
            icon: const Icon(Icons.save),
            label: const Text("Save Result"),
          ),
        ),
      ],
    );
  }
}