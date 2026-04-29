import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/gemini_remedy_service.dart';

class RecommendationScreen extends StatefulWidget {
  final String crop;
  final String disease;

  const RecommendationScreen({
    super.key,
    required this.crop,
    required this.disease,
  });

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  Map<String, dynamic>? data;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAI();
  }

  Future<void> _loadAI() async {
    try {
      final result = await GeminiRemedyService.getRemedy(
        crop: widget.crop,
        disease: widget.disease,
      );

      setState(() {
        data = result;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  // ───────── CARD DESIGN ─────────
  Widget _buildCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    if (value.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────── HEADER ─────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🌾 Crop: ${widget.crop}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "🦠 Disease: ${widget.disease}",
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // ───────── UI ─────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),

      appBar: AppBar(
        title: const Text("🌿 AI Farming Advisor"),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? const Center(child: Text("No recommendations found"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [

                      // HEADER
                      _buildHeader(),

                      const SizedBox(height: 20),

                      // SECTION TITLE
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "🌱 Treatment Plan",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // CARDS
                      _buildCard(
                        title: "🇱🇰 Sinhala Advice",
                        value: data!['sinhala'] ?? '',
                        icon: Icons.language,
                        color: Colors.green,
                      ),

                      _buildCard(
                        title: "🌿 Organic Treatment",
                        value: data!['organic'] ?? '',
                        icon: Icons.eco,
                        color: Colors.teal,
                      ),

                      _buildCard(
                        title: "🧪 Chemical Treatment",
                        value: data!['chemical'] ?? '',
                        icon: Icons.science,
                        color: Colors.orange,
                      ),

                      _buildCard(
                        title: "💊 Dosage Guide",
                        value: data!['dosage'] ?? '',
                        icon: Icons.scale,
                        color: Colors.blue,
                      ),

                      _buildCard(
                        title: "🏪 Agro Shops Advice",
                        value: data!['shop'] ?? '',
                        icon: Icons.store,
                        color: Colors.brown,
                      ),

                      const SizedBox(height: 20),

                      // FOOTER TIP
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lightbulb, color: Colors.green),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Tip: Always apply treatment early morning or evening for best results.",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}