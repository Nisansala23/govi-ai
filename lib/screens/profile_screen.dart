import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
// Import your new drawer and settings screen here
// import 'app_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _farmerData;
  List<Map<String, dynamic>> _scanHistory = [];
  List<Map<String, dynamic>> _myFields = [];
  bool _isLoading = true;
  Uint8List? _profileImageBytes;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        AuthService.getFarmerProfile(),
        AuthService.getScanHistory(),
        AuthService.getFarmerFields(),
      ]);

      if (mounted) {
        setState(() {
          _farmerData = results[0] as Map<String, dynamic>?;
          _scanHistory = results[1] as List<Map<String, dynamic>>;
          _myFields = results[2] as List<Map<String, dynamic>>;
          _profileImageUrl = _farmerData?['profileImageUrl'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _profileImageBytes = bytes);

      try {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Uploading photo...'),
                ],
              ),
              duration: Duration(seconds: 10),
              backgroundColor: AppColors.primary,
            ),
          );
        }

        final url = await CloudinaryService.uploadImage(bytes);

        if (url != null) {
          final uid = FirebaseAuth.instance.currentUser!.uid;
          await FirebaseFirestore.instance
              .collection('farmers')
              .doc(uid)
              .update({'profileImageUrl': url});

          setState(() => _profileImageUrl = url);

          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated! ✅'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error uploading image: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload photo ❌'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(
      text: _farmerData?['name'] ?? '',
    );
    final phoneController = TextEditingController(
      text: _farmerData?['phone'] ?? '',
    );
    String selectedDistrict = _farmerData?['district'] ?? 'Colombo';

    final districts = [
      'Ampara',
      'Anuradhapura',
      'Badulla',
      'Batticaloa',
      'Colombo',
      'Galle',
      'Gampaha',
      'Hambantota',
      'Jaffna',
      'Kalutara',
      'Kandy',
      'Kegalle',
      'Kilinochchi',
      'Kurunegala',
      'Mannar',
      'Matale',
      'Matara',
      'Moneragala',
      'Mullaitivu',
      'Nuwara Eliya',
      'Polonnaruwa',
      'Puttalam',
      'Ratnapura',
      'Trincomalee',
      'Vavuniya',
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Edit Profile'),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: districts.contains(selectedDistrict)
                      ? selectedDistrict
                      : 'Colombo',
                  decoration: InputDecoration(
                    labelText: 'District',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: districts
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null)
                      setDialogState(() => selectedDistrict = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                try {
                  final uid = FirebaseAuth.instance.currentUser!.uid;
                  await FirebaseFirestore.instance
                      .collection('farmers')
                      .doc(uid)
                      .update({
                        'name': nameController.text.trim(),
                        'phone': phoneController.text.trim(),
                        'district': selectedDistrict,
                      });
                  if (mounted) {
                    Navigator.pop(context);
                    await _loadProfile();
                  }
                } catch (e) {
                  debugPrint('Error: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddFieldDialog() async {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    String selectedCropType = 'Paddy';
    bool isSaving = false;
    final cropTypes = ['Paddy', 'Tea', 'Tomato', 'Other'];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_circle, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Add New Field'),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Field Name *',
                    prefixIcon: const Icon(Icons.landscape_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCropType,
                  decoration: InputDecoration(
                    labelText: 'Crop Type *',
                    prefixIcon: const Icon(Icons.eco_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: cropTypes
                      .map(
                        (crop) => DropdownMenuItem(
                          value: crop,
                          child: Text('${_getCropEmoji(crop)} $crop'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null)
                      setDialogState(() => selectedCropType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: 'Location / Area',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (isSaving) const LinearProgressIndicator(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) return;
                      setDialogState(() => isSaving = true);
                      try {
                        await AuthService.addField(
                          name: nameController.text.trim(),
                          cropType: selectedCropType,
                          location: locationController.text.trim(),
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          await _loadProfile();
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Add Field',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteField(String fieldId, String fieldName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Field'),
        content: Text('Are you sure you want to delete "$fieldName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.deleteField(fieldId);
      await _loadProfile();
    }
  }

  String _getCropEmoji(String cropType) {
    switch (cropType.toLowerCase()) {
      case 'paddy':
        return '🌾';
      case 'tea':
        return '🍃';
      case 'tomato':
        return '🍅';
      default:
        return '🌱';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final DateTime d = (date is Timestamp) ? date.toDate() : DateTime.now();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (e) {
      return 'Unknown';
    }
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
    final createdAt = _farmerData?['createdAt'];
    final memberSince = 'Member since ${_formatDate(createdAt)}';

    return Scaffold(
      backgroundColor: AppColors.background,
      // drawer: const AppDrawer(), // Add your custom hamburger menu here
      appBar: AppBar(
        title: const Text('Farmer Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditProfileDialog,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(name, district, phone, memberSince),
              const SizedBox(height: 20),
              _buildStatsRow(totalScans, diseasesFound, healthyScans),
              const SizedBox(height: 20),
              _buildCropFields(),
              const SizedBox(height: 20),
              _buildScanHistory(),
              const SizedBox(height: 30),
              Center(
                child: Text(
                  'Version 1.0.0 • Govi-AI • Sri Lanka',
                  style: AppTextStyles.caption.copyWith(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    String name,
    String district,
    String phone,
    String memberSince,
  ) {
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
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    backgroundImage: _profileImageBytes != null
                        ? MemoryImage(_profileImageBytes!)
                        : (_profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!) as ImageProvider
                              : null),
                    child:
                        (_profileImageUrl == null && _profileImageBytes == null)
                        ? Text(
                            name[0].toUpperCase(),
                            style: AppTextStyles.heading1.copyWith(
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickProfileImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$district, Sri Lanka',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white70,
                  size: 12,
                ),
                const SizedBox(width: 6),
                Text(
                  memberSince,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int total, int diseases, int healthy) {
    return Row(
      children: [
        _buildStatCard(
          'Total',
          total.toString(),
          Icons.camera_alt,
          AppColors.primary,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Diseases',
          diseases.toString(),
          Icons.warning_amber,
          AppColors.danger,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Healthy',
          healthy.toString(),
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.heading2.copyWith(color: color)),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildCropFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('My Fields', style: AppTextStyles.heading3),
            TextButton.icon(
              onPressed: _showAddFieldDialog,
              icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
              label: const Text(
                'Add Field',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_myFields.isEmpty)
          const Center(child: Text('No fields registered yet'))
        else
          ..._myFields.map((field) {
            final isWarning = (field['status'] ?? '').toString().contains(
              'Disease',
            );
            final color = isWarning ? AppColors.danger : AppColors.healthy;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _getCropEmoji(field['cropType'] ?? 'Unknown'),
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field['name'] ?? 'Unnamed Field',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${field['cropType']} • ${field['location']}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () =>
                        _deleteField(field['id'] ?? '', field['name'] ?? ''),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildScanHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Scans', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        if (_scanHistory.isEmpty)
          const Center(child: Text('No scan history yet'))
        else
          ..._scanHistory.take(5).map((scan) {
            final isHealthy = scan['isHealthy'] == true;
            final color = isHealthy ? AppColors.healthy : AppColors.danger;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(
                      isHealthy ? Icons.eco : Icons.bug_report,
                      color: color,
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
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _formatDate(scan['date']),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    isHealthy ? 'Healthy' : 'Infected',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
