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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final name = _farmerData?['name'] ?? 'Farmer';
    final district = _farmerData?['district'] ?? 'Unknown';
    final phone = _farmerData?['phone'] ?? 'N/A';

    final totalScans = _farmerData?['totalScans'] ?? 0;
    final diseasesFound = _farmerData?['diseasesFound'] ?? 0;
    final healthyScans = _farmerData?['healthyScans'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfile,
          ),
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
                children: [
                  _buildProfileCard(name, district, phone),
                  const SizedBox(height: 16),

                  _buildStatsRow(totalScans, diseasesFound, healthyScans),
                  const SizedBox(height: 16),

                  _buildSectionTitle("Recent Scans"),
                  _buildScanHistory(),

                  const SizedBox(height: 16),

                  _buildSectionTitle("Quick Actions"),
                  _buildQuickActions(),

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

  // ───────────────── PROFILE CARD ─────────────────

  Widget _buildProfileCard(String name, String district, String phone) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : "F";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 24,
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
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text("$district District",
                    style: const TextStyle(color: Colors.white70)),
                Text(phone,
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── STATS ─────────────────

  Widget _buildStatsRow(int total, int disease, int healthy) {
    return Row(
      children: [
        _statCard("Total", total, Icons.camera_alt, AppColors.primary),
        const SizedBox(width: 10),
        _statCard("Disease", disease, Icons.warning, AppColors.danger),
        const SizedBox(width: 10),
        _statCard("Healthy", healthy, Icons.check_circle, AppColors.healthy),
      ],
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(
              "$value",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }

  // ───────────────── SCAN HISTORY (IMPROVED) ─────────────────

  Widget _buildScanHistory() {
    final history = _farmerData?['history'] ?? [];

    if (history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "No scan history available",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Column(
      children: history.map<Widget>((item) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.agriculture),
            title: Text(item['crop'] ?? ''),
            subtitle: Text(item['disease'] ?? ''),
            trailing: Text(item['date'] ?? ''),
          ),
        );
      }).toList(),
    );
  }

  // ───────────────── QUICK ACTIONS ─────────────────

  Widget _buildQuickActions() {
    return Row(
      children: [
        _actionButton(Icons.chat, "AI Chat"),
        _actionButton(Icons.map, "Map"),
        _actionButton(Icons.camera_alt, "Scan"),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────── SECTION TITLE ─────────────────

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ───────────────── LOGOUT ─────────────────

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