import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/ai_fab.dart';

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
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
        ],
      ),

      floatingActionButton: const AiFab(),

      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/img.jpg"),
            fit: BoxFit.cover,
          ),
        ),

        child: Container(
          color: Colors.black.withOpacity(0.35), 

          child: SafeArea(
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
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$district District',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(phone,
                    style: const TextStyle(color: Colors.white70)),
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
        _buildStatCard('Total', totalScans.toString(), Icons.camera_alt, AppColors.primary),
        const SizedBox(width: 12),
        _buildStatCard('Diseases', diseasesFound.toString(), Icons.warning_amber, AppColors.danger),
        const SizedBox(width: 12),
        _buildStatCard('Healthy', healthyScans.toString(), Icons.check_circle, AppColors.healthy),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildCropFields() => const SizedBox();

  Widget _buildScanHistory(List<Map<String, dynamic>> scanHistory) =>
      const SizedBox();

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          await AuthService.logout();
        },
        child: const Text('Logout'),
      ),
    );
  }
}