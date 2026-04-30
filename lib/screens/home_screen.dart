import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/weather_service.dart';
import 'scanner_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _farmerData;
  List<Map<String, dynamic>> _recentScans = [];
  List<Map<String, dynamic>> _outbreaks = [];
  Map<String, dynamic>? _weather;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final farmer = await AuthService.getFarmerProfile();
      final scans = await AuthService.getScanHistory();
      final outbreaks = await AuthService.getOutbreaks();
      final weather = await WeatherService.getWeather(
        farmer?['district'] ?? 'Colombo',
      );
      if (mounted) {
        setState(() {
          _farmerData = farmer;
          _recentScans = scans.take(3).toList();
          _outbreaks = outbreaks;
          _weather = weather;
          _isLoading = false;
        });
        _animationController
          ..reset()
          ..forward();
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    ).then((_) => _loadData());
  }

  void _goToMap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final name = _farmerData?['name'] ?? 'Farmer';
    final district = _farmerData?['district'] ?? 'Unknown';
    final totalScans = _farmerData?['totalScans'] ?? 0;
    final diseases = _farmerData?['diseasesFound'] ?? 0;
    final healthy = _farmerData?['healthyScans'] ?? 0;

    return Scaffold(
      backgroundColor: _pageBg,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: _headerGreen,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildAppBar(context, name, district),
            SliverToBoxAdapter(
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 450,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: _headerGreen,
                            strokeWidth: 3,
                          ),
                        ),
                      )
                      : FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── scan button first ──
                              _buildScanButton(),
                              const SizedBox(height: 20),

                              // ── alert if any ──
                              if (_outbreaks.isNotEmpty) ...[
                                _buildAlertBanner(),
                                const SizedBox(height: 20),
                              ],

                              // ── stats cards ──
                              _sectionHeader('Farm Overview', '', null),
                              const SizedBox(height: 12),
                              _buildStatsRow(totalScans, diseases, healthy),
                              const SizedBox(height: 24),

                              // ── recent activity ──
                              _sectionHeader(
                                'Recent Activity',
                                'View All',
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildRecentActivity(),
                              const SizedBox(height: 24),

                              // ── map ──
                              _sectionHeader(
                                'Nearby Outbreaks',
                                'Open Map',
                                _goToMap,
                              ),
                              const SizedBox(height: 12),
                              _buildMapCard(),
                              const SizedBox(height: 20),

                              // ── tip ──
                              _buildTipCard(),
                              const SizedBox(height: 90),
                            ],
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar with background image + temp on top ──────────────
  Widget _buildAppBar(BuildContext context, String name, String district) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'F';
    final temp = _weather?['temp'] ?? '--';
    final wIcon = _weather?['icon'] ?? '⛅';
    final desc = _weather?['description'] ?? '';
    final humidity = _weather?['humidity'] ?? '--';

    return SliverAppBar(
      expandedHeight: 340,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1B5E20),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // ── BACKGROUND IMAGE ──────────────────────────
            Image.asset(
              'assets/images/farm_bg.jpg',
              fit: BoxFit.cover,
              // If image not found, falls back gracefully
              errorBuilder:
                  (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1B5E20),
                          Color(0xFF2E7D32),
                          Color(0xFF388E3C),
                        ],
                      ),
                    ),
                  ),
            ),

            // ── dark gradient overlay ─────────────────────
            // Makes text always readable over any image
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xCC000000), // top darker
                    Color(0x881B5E20), // mid green tint
                    Color(0xEE1B5E20), // bottom solid green
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // ── content ───────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // top bar row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _appBarBtn(
                          Icons.menu_rounded,
                          () => Scaffold.of(context).openDrawer(),
                        ),
                        Row(
                          children: [
                            Stack(
                              children: [
                                _appBarBtn(
                                  Icons.notifications_outlined,
                                  _goToMap,
                                ),
                                if (_outbreaks.isNotEmpty)
                                  Positioned(
                                    right: 7,
                                    top: 7,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _amber,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _white,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProfileScreen(),
                                    ),
                                  ),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _lightGreen,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 19,
                                  backgroundColor: _white.withValues(
                                    alpha: 0.2,
                                  ),
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: _white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // ── TEMPERATURE — shown at top ─────────
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // big temp
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$temp°C',
                              style: const TextStyle(
                                color: _white,
                                fontSize: 56,
                                fontWeight: FontWeight.w200,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(wIcon, style: const TextStyle(fontSize: 28)),
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              style: TextStyle(
                                color: _white.withValues(alpha: 0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.water_drop_outlined,
                                  color: Colors.white70,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Humidity $humidity%',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        // LIVE badge top right
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _lightGreen.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _lightGreen.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.circle, color: _lightGreen, size: 7),
                              SizedBox(width: 5),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  color: _white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // ── name + location at bottom ──────────
                    Text(
                      'ආයුබෝවන් / Welcome Back 👋',
                      style: TextStyle(
                        color: _white.withValues(alpha: 0.75),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      name,
                      style: const TextStyle(
                        color: _white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _appBarChip(
                          Icons.location_on_rounded,
                          '$district District',
                        ),
                        const SizedBox(width: 8),
                        _appBarChip(
                          Icons.calendar_today_rounded,
                          _getFormattedDate(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appBarBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _white.withValues(alpha: 0.2)),
      ),
      child: Icon(icon, color: _white, size: 21),
    ),
  );

  Widget _appBarChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _white.withValues(alpha: 0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _lightGreen, size: 12),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: _white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  String _getFormattedDate() {
    final now = DateTime.now();
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
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  // ── Scan Button ───────────────────────────────────────────────
  Widget _buildScanButton() {
    return GestureDetector(
      onTap: _goToScanner,
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                color: _white,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scan Crop Disease',
                    style: TextStyle(
                      color: _white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'බෝග රෝගය පරීක්ෂා කරන්න',
                    style: TextStyle(
                      color: _white.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '✨  Instant AI diagnosis • Gemini',
                    style: TextStyle(
                      color: _white.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
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
    );
  }

  // ── Alert Banner ──────────────────────────────────────────────
  Widget _buildAlertBanner() {
    final disease = _outbreaks.first['disease'] ?? 'Disease';
    final district = _outbreaks.first['district'] ?? 'Unknown';

    return GestureDetector(
      onTap: _goToMap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _amber.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: _amber,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_outbreaks.length} Active Alert${_outbreaks.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Color(0xFF6D4C00),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '$disease detected in $district',
                    style: const TextStyle(
                      color: Color(0xFF8D6200),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _amber,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'View',
                style: TextStyle(
                  color: _white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────
  Widget _sectionHeader(String title, String action, VoidCallback? onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _textDark,
          ),
        ),
        if (action.isNotEmpty && onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              action,
              style: const TextStyle(
                color: _headerGreen,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ── Stats Row ─────────────────────────────────────────────────
  Widget _buildStatsRow(int total, int diseases, int healthy) {
    return Row(
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
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
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
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _textMid,
            ),
          ),
          Text(sub, style: const TextStyle(fontSize: 10, color: _textLight)),
        ],
      ),
    );
  }

  // ── Recent Activity ───────────────────────────────────────────
  Widget _buildRecentActivity() {
    return Container(
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
      child:
          _recentScans.isEmpty
              ? _buildEmptyActivity()
              : Column(
                children:
                    _recentScans.asMap().entries.map((e) {
                      final i = e.key;
                      final scan = e.value;
                      return Column(
                        children: [
                          _buildActivityItem(scan),
                          if (i < _recentScans.length - 1)
                            Divider(
                              height: 1,
                              color: Colors.grey.shade100,
                              indent: 16,
                              endIndent: 16,
                            ),
                        ],
                      );
                    }).toList(),
              ),
    );
  }

  Widget _buildEmptyActivity() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              color: _textLight,
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No scans yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _textDark,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Start scanning your crops for\ninstant AI disease diagnosis',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textLight, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _goToScanner,
            icon: const Icon(Icons.camera_alt_rounded, size: 16),
            label: const Text('Scan Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _headerGreen,
              foregroundColor: _white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> scan) {
    final isHealthy =
        scan['isHealthy'] == true ||
        (scan['disease'] ?? '').toLowerCase() == 'healthy';
    final disease = scan['disease'] ?? 'Unknown';
    final crop = scan['crop'] ?? 'Unknown';
    final district = scan['district'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  isHealthy ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              isHealthy ? Icons.eco_rounded : Icons.manage_search_rounded,
              color: isHealthy ? _lightGreen : _amber,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disease,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  district.isNotEmpty
                      ? '${crop.toUpperCase()} • $district'
                      : crop.toUpperCase(),
                  style: const TextStyle(
                    color: _textLight,
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color:
                  isHealthy ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isHealthy ? '✓ Healthy' : '⚑ Found',
              style: TextStyle(
                color: isHealthy ? _lightGreen : _amber,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Map Card ──────────────────────────────────────────────────
  Widget _buildMapCard() {
    return GestureDetector(
      onTap: _goToMap,
      child: Container(
        height: 155,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), _headerGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _headerGreen.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // decorative
              Positioned(right: -25, top: -25, child: _circle(130, 0.07)),
              Positioned(left: -10, bottom: -20, child: _circle(90, 0.06)),
              const Positioned.fill(
                child: Center(
                  child: Icon(
                    Icons.map_rounded,
                    color: Colors.white10,
                    size: 100,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _outbreaks.isEmpty
                                ? _white.withValues(alpha: 0.2)
                                : _amber.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _outbreaks.isEmpty
                            ? '✓  All Clear'
                            : '⚠  ${_outbreaks.length} Outbreaks',
                        style: const TextStyle(
                          color: _white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_outbreaks.isEmpty)
                      Text(
                        'No active outbreaks\nin your region.',
                        style: TextStyle(
                          color: _white.withValues(alpha: 0.75),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      )
                    else
                      ..._outbreaks
                          .take(2)
                          .map(
                            (o) => Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                '• ${o['disease']} — ${o['district']}',
                                style: TextStyle(
                                  color: _white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Regional Health Index',
                          style: TextStyle(
                            color: _white.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'View Full Map',
                                style: TextStyle(
                                  color: _headerGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: _headerGreen,
                                size: 12,
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
      ),
    );
  }

  // ── Tip Card ──────────────────────────────────────────────────
  Widget _buildTipCard() {
    final tips = [
      'Water crops early morning for best absorption.',
      'Check leaves regularly for early disease signs.',
      'Rotate crops each season to reduce soil diseases.',
      'Use organic compost to boost soil health naturally.',
      'Keep field drainage clear after heavy rainfall.',
    ];
    final tip = tips[DateTime.now().day % tips.length];

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 4,
            height: 52,
            decoration: BoxDecoration(
              color: _headerGreen,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Text('💡', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FARMER TIP OF THE DAY',
                  style: TextStyle(
                    color: _textLight,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

  Widget _circle(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: _white.withValues(alpha: opacity),
    ),
  );
}
