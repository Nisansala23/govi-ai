import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

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
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
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
          _notificationsEnabled = _farmerData?['notificationsEnabled'] ?? true;
          _selectedLanguage = _farmerData?['language'] ?? 'English';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ Profile picture upload
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
        // Show uploading indicator
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

        // Upload to Cloudinary
        final url = await CloudinaryService.uploadImage(bytes);

        if (url != null) {
          // Save URL to Firestore
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

  // ✅ Edit Profile Dialog
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
                // Name
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Phone
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // District
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  items: districts.map((d) {
                    return DropdownMenuItem(value: d, child: Text(d));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedDistrict = val);
                    }
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated! ✅'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('Error: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Add Field Dialog - FULLY WORKING
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
                // Field Name
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Field Name *',
                    hintText: 'e.g. North Paddy Field',
                    prefixIcon: const Icon(Icons.landscape_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Crop Type
                DropdownButtonFormField<String>(
                  value: selectedCropType,
                  decoration: InputDecoration(
                    labelText: 'Crop Type *',
                    prefixIcon: const Icon(Icons.eco_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  items: cropTypes.map((crop) {
                    return DropdownMenuItem(
                      value: crop,
                      child: Row(
                        children: [
                          Text(_getCropEmoji(crop)),
                          const SizedBox(width: 8),
                          Text(crop),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedCropType = val);
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Location
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: 'Location / Area',
                    hintText: 'e.g. Kurunegala North',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),

                // Loading indicator inside dialog
                if (isSaving) ...[
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Saving field...'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: isSaving
                  ? null
                  : () async {
                      // Validate
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a field name!'),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);

                      try {
                        // ✅ Save to Firebase
                        await AuthService.addField(
                          name: nameController.text.trim(),
                          cropType: selectedCropType,
                          location: locationController.text.trim(),
                        );

                        if (mounted) {
                          Navigator.pop(context);

                          // ✅ Refresh profile to show new field
                          await _loadProfile();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${nameController.text.trim()} added! ✅',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.danger,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Add Field'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Delete Field with confirmation
  Future<void> _deleteField(String fieldId, String fieldName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Field'),
        content: Text('Are you sure you want to delete "$fieldName"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      try {
        await AuthService.deleteField(fieldId);
        await _loadProfile(); // Refresh
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$fieldName deleted!'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error deleting field: $e');
      }
    }
  }

  // ✅ Get crop emoji
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

  // ✅ Logout with confirmation
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
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
      appBar: AppBar(
        title: const Text('Farmer Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditProfileDialog, // ✅ WORKS NOW
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
              const SizedBox(height: 20),
              _buildSettings(),
              const SizedBox(height: 20),
              _buildLogoutButton(),
              const SizedBox(height: 12),
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
              mainAxisSize: MainAxisSize.min,
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
              color: Colors.black.withValues(alpha: 0.05),
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

  // ✅ FULLY WORKING My Fields section
  Widget _buildCropFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('My Fields', style: AppTextStyles.heading3),
            TextButton.icon(
              onPressed: _showAddFieldDialog, // ✅ WORKS NOW!
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.landscape_outlined,
                  color: Colors.grey[400],
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  'No fields registered yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap "Add Field" to register your farm',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          )
        else
          ..._myFields.map((field) {
            final isWarning = (field['status'] ?? '').toString().contains(
              'Disease',
            );
            final color = isWarning ? AppColors.danger : AppColors.healthy;
            final cropType = field['cropType'] ?? 'Unknown';
            final location = field['location'] ?? '';
            final fieldId = field['id'] ?? '';

            return Container(
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
                  // Crop emoji
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _getCropEmoji(cropType),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          location.isNotEmpty
                              ? '$cropType • $location'
                              : cropType,
                          style: AppTextStyles.caption,
                        ),
                        // Status badge
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            field['status'] ?? 'Healthy',
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Delete button
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () =>
                        _deleteField(fieldId, field['name'] ?? 'this field'),
                    tooltip: 'Delete field',
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ✅ Real scan history from Firebase
  Widget _buildScanHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Scans', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        if (_scanHistory.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.history, color: Colors.grey[400], size: 40),
                const SizedBox(height: 8),
                Text(
                  'No scan history yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          )
        else
          ..._scanHistory.take(5).map((scan) {
            final isHealthy = scan['isHealthy'] == true;
            final color = isHealthy ? AppColors.healthy : AppColors.danger;
            final disease = scan['disease'] ?? 'Unknown';
            final crop = scan['crop'] ?? 'Unknown';
            final district = scan['district'] ?? '';
            final date = _formatDate(scan['date']);

            return Container(
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
                    backgroundColor: color.withValues(alpha: 0.15),
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
                          '$crop - $disease',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          district.isNotEmpty && district != 'Unknown District'
                              ? '$date • $district'
                              : date,
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
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isHealthy ? 'Healthy' : 'Infected',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ✅ Settings with working toggles
  Widget _buildSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settings', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        Container(
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
              // Notifications
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: const Text('Notifications'),
                subtitle: Text(
                  _notificationsEnabled ? 'Enabled' : 'Disabled',
                  style: AppTextStyles.caption,
                ),
                value: _notificationsEnabled,
                activeColor: AppColors.primary,
                onChanged: (val) async {
                  setState(() => _notificationsEnabled = val);
                  try {
                    final uid = FirebaseAuth.instance.currentUser!.uid;
                    await FirebaseFirestore.instance
                        .collection('farmers')
                        .doc(uid)
                        .update({'notificationsEnabled': val});
                  } catch (e) {
                    debugPrint('Error: $e');
                  }
                },
              ),
              Divider(height: 1, color: Colors.grey[200]),

              // Language
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.language_outlined,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                title: const Text('App Language'),
                trailing: DropdownButton<String>(
                  value: _selectedLanguage,
                  underline: const SizedBox(),
                  items: ['English', 'සිංහල', 'தமிழ்'].map((lang) {
                    return DropdownMenuItem(value: lang, child: Text(lang));
                  }).toList(),
                  onChanged: (val) async {
                    if (val != null) {
                      setState(() => _selectedLanguage = val);
                      try {
                        final uid = FirebaseAuth.instance.currentUser!.uid;
                        await FirebaseFirestore.instance
                            .collection('farmers')
                            .doc(uid)
                            .update({'language': val});
                      } catch (e) {
                        debugPrint('Error: $e');
                      }
                    }
                  },
                ),
              ),
              Divider(height: 1, color: Colors.grey[200]),

              // About
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                title: const Text('About Govi-AI'),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
                onTap: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Row(
                      children: [
                        Icon(Icons.eco, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('About Govi-AI'),
                      ],
                    ),
                    content: const Text(
                      'Version 1.0.0\n\n'
                      'Govi-AI is an intelligent crop disease '
                      'detection system for Sri Lankan farmers. '
                      'Using Gemini AI, it identifies diseases '
                      'instantly and provides local remedies.\n\n'
                      'Developed by Group 08\n'
                      'NSBM Green University',
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout, color: AppColors.danger),
        label: const Text(
          'LOGOUT',
          style: TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
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
