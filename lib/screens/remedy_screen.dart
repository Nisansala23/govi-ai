import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'recommendation_screen.dart';

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
    final Color statusColor = isHealthy ? AppColors.healthy : AppColors.danger;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Diagnosis Result')),
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

              _buildCard("About Disease", description, Icons.info_outline),
              _buildCard("Sinhala උපදෙස්", sinhalaRemedy, Icons.language),

              _buildRemedy(
                "Organic Treatment",
                organicRemedy,
                AppColors.healthy,
              ),

              _buildRemedy(
                "Chemical Treatment",
                chemicalRemedy,
                AppColors.warning,
              ),

              const SizedBox(height: 20),

              // ✅ NEW BUTTON (IMPORTANT)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.agriculture),
                  label: const Text("Get Recommendations"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => RecommendationScreen(
                              crop: crop,
                              disease: disease,
                            ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

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
            isHealthy ? Icons.check_circle : Icons.warning,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 10),
          Text(
            disease,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text("Crop: $crop", style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildCard(String title, String content, IconData icon) {
    if (content.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(content)),
        ],
      ),
    );
  }

  Widget _buildRemedy(String title, String content, Color color) {
    if (content.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(content),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text("Scan Another"),
      ),
    );
  }
}
