import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _farmerData;
  List<Map<String, dynamic>> _scanHistory = [];
  List<Map<String, dynamic>> _myFields = [];
  bool _isLoading = true;
  Uint8List? _profileImageBytes;
  String? _profileImageUrl;
  late TabController _tabController;

  // ── Same palette as HomeScreen ────────────────────────────────
  static const _headerGreen = Color(0xFF2E7D32);
  static const _accentGreen = Color(0xFF43A047);
  static const _lightGreen = Color(0xFF4CAF50);
  static const _pageBg = Color(0xFFF4F6F8);
  static const _cardBg = Colors.white;
  static const _cardBorder = Color(0xFFEEEEEE);
  static const _textDark = Color(0xFF1A1A2E);
  static const _textMid = Color(0xFF5A6070);
  static const _textLight = Color(0xFF9E9E9E);
  static const _amber = Color(0xFFFF8F00);
  static const _white = Colors.white;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      debugPrint('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    setState(() => _profileImageBytes = bytes);

    try {
      _showSnack('Uploading photo...', isLoading: true);
      final url = await CloudinaryService.uploadImage(bytes);
      if (url != null) {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        await FirebaseFirestore.instance.collection('farmers').doc(uid).update({
          'profileImageUrl': url,
        });
        setState(() => _profileImageUrl = url);
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          _showSnack('Profile photo updated ✅');
        }
      }
    } catch (e) {
      _showSnack('Failed to upload ❌', color: _amber);
    }
  }

  void _showSnack(
    String msg, {
    bool isLoading = false,
    Color color = _headerGreen,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(color: _white, strokeWidth: 2),
              ),
              const SizedBox(width: 12),
            ],
            Text(msg, style: GoogleFonts.poppins(color: _white)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _showEditDialog() async {
    final nameCtrl = TextEditingController(text: _farmerData?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: _farmerData?['phone'] ?? '');
    String district = _farmerData?['district'] ?? 'Colombo';

    const districts = [
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
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setD) => AlertDialog(
                  backgroundColor: _cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    'Edit Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _inputField(
                          nameCtrl,
                          'Full Name',
                          Icons.person_outline,
                        ),
                        const SizedBox(height: 12),
                        _inputField(
                          phoneCtrl,
                          'Phone Number',
                          Icons.phone_outlined,
                          type: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value:
                              districts.contains(district)
                                  ? district
                                  : 'Colombo',
                          style: GoogleFonts.poppins(
                            color: _textDark,
                            fontSize: 14,
                          ),
                          decoration: _inputDeco(
                            'District',
                            Icons.location_on_outlined,
                          ),
                          items:
                              districts
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(
                                        d,
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            if (v != null) setD(() => district = v);
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(color: _textLight),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final uid = FirebaseAuth.instance.currentUser!.uid;
                        await FirebaseFirestore.instance
                            .collection('farmers')
                            .doc(uid)
                            .update({
                              'name': nameCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                              'district': district,
                            });
                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadProfile();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _headerGreen,
                        foregroundColor: _white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _showAddFieldDialog() async {
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    String crop = 'Paddy';
    bool saving = false;
    const crops = ['Paddy', 'Tea', 'Tomato', 'Other'];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setD) => AlertDialog(
                  backgroundColor: _cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    'Add New Field',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _inputField(
                          nameCtrl,
                          'Field Name *',
                          Icons.landscape_outlined,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: crop,
                          style: GoogleFonts.poppins(
                            color: _textDark,
                            fontSize: 14,
                          ),
                          decoration: _inputDeco(
                            'Crop Type *',
                            Icons.eco_outlined,
                          ),
                          items:
                              crops
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        '${_cropEmoji(c)} $c',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            if (v != null) setD(() => crop = v);
                          },
                        ),
                        const SizedBox(height: 12),
                        _inputField(
                          locationCtrl,
                          'Location',
                          Icons.location_on_outlined,
                        ),
                        if (saving)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: LinearProgressIndicator(color: _headerGreen),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: saving ? null : () => Navigator.pop(ctx),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(color: _textLight),
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          saving
                              ? null
                              : () async {
                                if (nameCtrl.text.trim().isEmpty) return;
                                setD(() => saving = true);
                                try {
                                  await AuthService.addField(
                                    name: nameCtrl.text.trim(),
                                    cropType: crop,
                                    location: locationCtrl.text.trim(),
                                  );
                                  if (mounted) {
                                    Navigator.pop(ctx);
                                    _loadProfile();
                                  }
                                } catch (_) {
                                  setD(() => saving = false);
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _headerGreen,
                        foregroundColor: _white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Add Field',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _deleteField(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: _cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Delete Field',
              style: GoogleFonts.poppins(
                color: _textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Delete "$name"? This cannot be undone.',
              style: GoogleFonts.poppins(color: _textMid, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: _textLight),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _amber,
                  foregroundColor: _white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Delete',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
    if (ok == true) {
      await AuthService.deleteField(id);
      _loadProfile();
    }
  }

  // ── helpers ───────────────────────────────────────────────────
  Widget _inputField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) => TextField(
    controller: ctrl,
    keyboardType: type,
    style: GoogleFonts.poppins(color: _textDark, fontSize: 14),
    decoration: _inputDeco(label, icon),
  );

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.poppins(color: _textMid, fontSize: 13),
    prefixIcon: Icon(icon, color: _headerGreen, size: 20),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _headerGreen, width: 2),
    ),
    filled: true,
    fillColor: _pageBg,
  );

  String _cropEmoji(String c) {
    switch (c.toLowerCase()) {
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
      final d = (date is Timestamp) ? date.toDate() : DateTime.now();
      const m = [
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
      return '${d.day} ${m[d.month - 1]} ${d.year}';
    } catch (_) {
      return 'Unknown';
    }
  }

  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    if (_isLoading) {
      return Scaffold(
        backgroundColor: _pageBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: _headerGreen,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: GoogleFonts.poppins(color: _textLight, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final name = _farmerData?['name'] ?? 'Farmer';
    final district = _farmerData?['district'] ?? 'Unknown';
    final phone = _farmerData?['phone'] ?? 'N/A';
    final total = _farmerData?['totalScans'] ?? 0;
    final diseases = _farmerData?['diseasesFound'] ?? 0;
    final healthy = _farmerData?['healthyScans'] ?? 0;
    final since = _formatDate(_farmerData?['createdAt']);

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _headerGreen,
        elevation: 0,
        // ── FIXED back arrow ──────────────────────────────────
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _white,
            size: 20,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            color: _white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _showEditDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, color: _white, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      'Edit',
                      style: GoogleFonts.poppins(
                        color: _white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            color: _headerGreen,
            child: TabBar(
              controller: _tabController,
              labelColor: _white,
              unselectedLabelColor: Colors.white54,
              indicatorColor: _lightGreen,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.normal,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'My Fields'),
                Tab(text: 'History'),
              ],
            ),
          ),
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _overviewTab(name, district, phone, since, total, diseases, healthy),
          _fieldsTab(),
          _historyTab(),
        ],
      ),
    );
  }

  // ── Overview Tab ──────────────────────────────────────────────
  Widget _overviewTab(
    String name,
    String district,
    String phone,
    String since,
    int total,
    int diseases,
    int healthy,
  ) {
    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: _headerGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile card with bg image ────────────────
            _profileCard(name, district, phone, since),
            const SizedBox(height: 16),

            // ── Stats ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    label: 'Total Scans',
                    value: total.toString(),
                    sub: 'All time',
                    icon: Icons.camera_alt_rounded,
                    iconColor: _headerGreen,
                    iconBg: const Color(0xFFE8F5E9),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    label: 'Diseased',
                    value: diseases.toString(),
                    sub: 'Detected',
                    icon: Icons.coronavirus_outlined,
                    iconColor: _amber,
                    iconBg: const Color(0xFFFFF3E0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    label: 'Healthy',
                    value: healthy.toString(),
                    sub: 'Clean',
                    icon: Icons.eco_rounded,
                    iconColor: _lightGreen,
                    iconBg: const Color(0xFFE8F5E9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Health rate ───────────────────────────────
            _healthRateCard(total, healthy),
            const SizedBox(height: 24),

            // ── Recent scans ──────────────────────────────
            _rowHeader(
              'Recent Scans',
              'See All',
              () => _tabController.animateTo(2),
            ),
            const SizedBox(height: 12),

            if (_scanHistory.isEmpty)
              _emptyBox(
                icon: Icons.history_rounded,
                title: 'No scans yet',
                sub: 'Your scan history will appear here',
              )
            else
              ..._scanHistory
                  .take(3)
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _scanRow(s),
                    ),
                  ),

            const SizedBox(height: 24),
            Center(
              child: Text(
                'Govi-AI  •  v1.0.0  •  Sri Lanka 🇱🇰',
                style: GoogleFonts.poppins(color: _textLight, fontSize: 11),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Profile Card with Background Image ───────────────────────
  Widget _profileCard(
    String name,
    String district,
    String phone,
    String since,
  ) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _headerGreen.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── BACKGROUND IMAGE ──────────────────────────
            Image.asset(
              'assets/images/farm_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF1B5E20),
                          Color(0xFF2E7D32),
                          Color(0xFF388E3C),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
            ),

            // ── dark overlay ──────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),

            // decorative circles
            Positioned(right: -20, top: -20, child: _circle(120, 0.07)),
            Positioned(left: -10, bottom: -20, child: _circle(80, 0.06)),

            // ── profile content ───────────────────────────
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // avatar
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _lightGreen,
                                width: 2.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 38,
                              backgroundColor: _white.withValues(alpha: 0.2),
                              backgroundImage:
                                  _profileImageBytes != null
                                      ? MemoryImage(_profileImageBytes!)
                                      : (_profileImageUrl != null
                                          ? NetworkImage(_profileImageUrl!)
                                              as ImageProvider
                                          : null),
                              child:
                                  (_profileImageUrl == null &&
                                          _profileImageBytes == null)
                                      ? Text(
                                        name[0].toUpperCase(),
                                        style: GoogleFonts.poppins(
                                          color: _white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 28,
                                        ),
                                      )
                                      : null,
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: _pickProfileImage,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: _lightGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 12,
                                  color: _white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // name + info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                color: _white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _pInfoRow(
                              Icons.location_on_rounded,
                              '$district, Sri Lanka',
                            ),
                            const SizedBox(height: 2),
                            _pInfoRow(Icons.phone_rounded, phone),
                            const SizedBox(height: 2),
                            _pInfoRow(
                              Icons.calendar_today_rounded,
                              'Member since $since',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pInfoRow(IconData icon, String text) => Row(
    children: [
      Icon(icon, color: Colors.white60, size: 13),
      const SizedBox(width: 5),
      Expanded(
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  Widget _circle(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: _white.withValues(alpha: opacity),
    ),
  );

  // ── Health Rate Card ──────────────────────────────────────────
  Widget _healthRateCard(int total, int healthy) {
    final pct = total > 0 ? healthy / total : 0.0;
    final label = '${(pct * 100).toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Crop Health Rate',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: _textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$label Healthy',
                  style: GoogleFonts.poppins(
                    color: _headerGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: const Color(0xFFF0F0F0),
              valueColor: const AlwaysStoppedAnimation(_lightGreen),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _dot(_lightGreen, 'Healthy ($healthy)'),
              const SizedBox(width: 16),
              _dot(
                _amber,
                'Diseased (${total - healthy < 0 ? 0 : total - healthy})',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c, String label) => Row(
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(label, style: GoogleFonts.poppins(color: _textMid, fontSize: 11)),
    ],
  );

  // ── Fields Tab ────────────────────────────────────────────────
  Widget _fieldsTab() {
    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: _headerGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // add field button
            GestureDetector(
              onTap: _showAddFieldDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_headerGreen, _accentGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _headerGreen.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: _white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: _white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Register New Field',
                            style: GoogleFonts.poppins(
                              color: _white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Add your crop field details',
                            style: GoogleFonts.poppins(
                              color: _white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: _white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_myFields.isEmpty)
              _emptyBox(
                icon: Icons.landscape_rounded,
                title: 'No fields yet',
                sub: 'Register your crop fields above',
              )
            else ...[
              _rowHeader(
                '${_myFields.length} Field${_myFields.length > 1 ? 's' : ''} Registered',
                '',
                null,
              ),
              const SizedBox(height: 12),
              ..._myFields.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _fieldRow(f),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _fieldRow(Map<String, dynamic> field) {
    final crop = field['cropType'] ?? 'Unknown';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _cropEmoji(crop),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field['name'] ?? 'Unnamed Field',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.eco_rounded, color: _lightGreen, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      crop,
                      style: GoogleFonts.poppins(color: _textMid, fontSize: 12),
                    ),
                    if ((field['location'] ?? '').isNotEmpty) ...[
                      Text(
                        '  •  ',
                        style: GoogleFonts.poppins(color: _textLight),
                      ),
                      Expanded(
                        child: Text(
                          field['location'],
                          style: GoogleFonts.poppins(
                            color: _textLight,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: _textLight,
              size: 20,
            ),
            onPressed:
                () => _deleteField(field['id'] ?? '', field['name'] ?? ''),
          ),
        ],
      ),
    );
  }

  // ── History Tab ───────────────────────────────────────────────
  Widget _historyTab() {
    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: _headerGreen,
      child:
          _scanHistory.isEmpty
              ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 400,
                  child: _emptyBox(
                    icon: Icons.history_rounded,
                    title: 'No scans yet',
                    sub: 'Your scan history will appear here',
                  ),
                ),
              )
              : ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _scanHistory.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _scanRow(_scanHistory[i]),
              ),
    );
  }

  // ── Scan Row ──────────────────────────────────────────────────
  Widget _scanRow(Map<String, dynamic> scan) {
    final isHealthy = scan['isHealthy'] == true;
    final disease = scan['disease'] ?? 'Unknown';
    final crop = scan['crop'] ?? 'Unknown';
    final date = _formatDate(scan['date']);

    final color = isHealthy ? _lightGreen : _amber;
    final bg = isHealthy ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              isHealthy ? Icons.eco_rounded : Icons.manage_search_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$crop — $disease',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: _textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: GoogleFonts.poppins(
                        color: _textLight,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isHealthy ? '✓ Healthy' : '⚑ Found',
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared widgets ────────────────────────────────────────────
  Widget _statCard({
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _textMid,
          ),
        ),
        Text(sub, style: GoogleFonts.poppins(fontSize: 10, color: _textLight)),
      ],
    ),
  );

  Widget _rowHeader(String title, String action, VoidCallback? onTap) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _textDark,
        ),
      ),
      if (action.isNotEmpty && onTap != null)
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: GoogleFonts.poppins(
              color: _headerGreen,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
    ],
  );

  Widget _emptyBox({
    required IconData icon,
    required String title,
    required String sub,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _headerGreen, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: _textDark,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: _textLight, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
