import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _farmerData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await AuthService.getFarmerProfile();
    setState(() {
      _farmerData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final name = _farmerData?['name'] ?? 'Farmer';
    final district = _farmerData?['district'] ?? 'Unknown';
    final phone = _farmerData?['phone'] ?? 'N/A';
    final totalScans = _farmerData?['totalScans'] ?? 0;
    final diseasesFound = _farmerData?['diseasesFound'] ?? 0;
    final healthyScans = _farmerData?['healthyScans'] ?? 0;

    final List<Map<String, dynamic>> scanHistory = [
      {
        'crop': 'Paddy',
        'disease': 'Paddy Blast',
        'date': 'Apr 3, 2026',
        'status': 'Disease',
        'color': AppColors.danger,
      },
      {
        'crop': 'Tea',
        'disease': 'Blister Blight',
        'date': 'Apr 1, 2026',
        'status': 'Disease',
        'color': AppColors.danger,
      },
      {
        'crop': 'Paddy',
        'disease': 'Healthy',
        'date': 'Mar 28, 2026',
        'status': 'Healthy',
        'color': AppColors.healthy,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [IconButton(icon: const Icon(Icons.edit), onPressed: () {})],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(name, district, phone),
              const SizedBox(height: 20),
              _buildStatsRow(totalScans, diseasesFound, healthyScans),
              const SizedBox(height: 20),
              _buildCropFields(),
              const SizedBox(height: 20),
              _buildScanHistory(scanHistory),
              const SizedBox(height: 20),
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(String name, String district, String phone) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.textLight,
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: AppTextStyles.heading1.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.textLight,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$district District',
                      style: AppTextStyles.bodyText.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.phone,
                      color: AppColors.textLight,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: AppTextStyles.bodyText.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int totalScans, int diseasesFound, int healthyScans) {
    return Row(
      children: [
        _buildStatCard(
          'Total Scans',
          totalScans.toString(),
          Icons.camera_alt,
          AppColors.primary,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Diseases',
          diseasesFound.toString(),
          Icons.warning_amber,
          AppColors.danger,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Healthy',
          healthyScans.toString(),
          Icons.check_circle,
          AppColors.healthy,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.heading2.copyWith(color: color)),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildCropFields() {
    final crops = [
      {
        'name': 'Tea Estate - North',
        'status': 'Disease Detected',
        'color': AppColors.danger,
        'icon': Icons.warning_amber,
      },
      {
        'name': 'Paddy Field - East',
        'status': 'Healthy',
        'color': AppColors.healthy,
        'icon': Icons.check_circle,
      },
      {
        'name': 'Tomato Garden',
        'status': 'Healthy',
        'color': AppColors.healthy,
        'icon': Icons.check_circle,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('My Fields', style: AppTextStyles.heading3),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Field'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...crops.map(
          (crop) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (crop['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    crop['icon'] as IconData,
                    color: crop['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crop['name'] as String,
                        style: AppTextStyles.bodyText.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        crop['status'] as String,
                        style: AppTextStyles.caption.copyWith(
                          color: crop['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanHistory(List<Map<String, dynamic>> scanHistory) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Scan History', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        ...scanHistory.map(
          (scan) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: (scan['color'] as Color).withValues(
                    alpha: 0.15,
                  ),
                  child: Icon(
                    Icons.eco,
                    color: scan['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${scan['crop']} - ${scan['disease']}',
                        style: AppTextStyles.bodyText.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        scan['date'] as String,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (scan['color'] as Color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    scan['status'] as String,
                    style: AppTextStyles.caption.copyWith(
                      color: scan['color'] as Color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await AuthService.logout();
        },
        icon: const Icon(Icons.logout, color: AppColors.danger),
        label: const Text('Logout', style: TextStyle(color: AppColors.danger)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.danger),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
