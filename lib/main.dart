import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/map_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/news_screen.dart';
import 'screens/farming_calendar_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Govi-AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF2E7D32),
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 0,
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
        drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
        dividerColor: const Color(0xFFEEEEEE),
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
      ),
      home: const SplashScreen(),
    );
  }
}

// ══════════════════════════════════════════════════════════════
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  static const _green1 = Color(0xFF1B5E20);
  static const _headerGreen = Color(0xFF2E7D32);
  static const _lightGreen = Color(0xFF4CAF50);
  static const _pageBg = Color(0xFFF4F6F8);
  static const _textDark = Color(0xFF1A1A2E);
  static const _textMid = Color(0xFF5A6070);
  static const _textLight = Color(0xFF9E9E9E);
  static const _cardBorder = Color(0xFFEEEEEE);
  static const _white = Colors.white;

  final List<String> _titles = [
    'Govi-AI',
    'AI Scanner',
    'Disease Map',
    'My Profile',
  ];

  final List<Widget> _screens = [
    const HomeScreen(),
    const ScannerScreen(),
    const MapScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: _pageBg,
      drawer: _buildDrawer(context),

      appBar:
          _currentIndex == 0
              ? null
              : AppBar(
                backgroundColor: _headerGreen,
                elevation: 0,
                leading: Builder(
                  builder:
                      (ctx) => GestureDetector(
                        onTap: () => Scaffold.of(ctx).openDrawer(),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.menu_rounded,
                            color: _white,
                            size: 22,
                          ),
                        ),
                      ),
                ),
                title: Text(
                  _titles[_currentIndex],
                  style: GoogleFonts.poppins(
                    color: _white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                systemOverlayStyle: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                ),
              ),

      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _navItem(
                1,
                Icons.camera_alt_outlined,
                Icons.camera_alt_rounded,
                'Scanner',
              ),
              _navItem(2, Icons.map_outlined, Icons.map_rounded, 'Map'),
              _navItem(
                3,
                Icons.person_outline,
                Icons.person_rounded,
                'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? _headerGreen.withValues(alpha: 0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? _headerGreen : _textLight,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? _headerGreen : _textLight,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Drawer ────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: _white,
      width: MediaQuery.of(context).size.width * 0.78,
      child: Column(
        children: [
          _buildDrawerHeader(),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  _sectionLabel('MAIN'),
                  _drawerNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    index: 0,
                  ),
                  _drawerNavItem(
                    icon: Icons.camera_alt_outlined,
                    activeIcon: Icons.camera_alt_rounded,
                    label: 'AI Scanner',
                    index: 1,
                  ),
                  _drawerNavItem(
                    icon: Icons.map_outlined,
                    activeIcon: Icons.map_rounded,
                    label: 'Disease Map',
                    index: 2,
                  ),
                  _drawerNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person_rounded,
                    label: 'My Profile',
                    index: 3,
                  ),

                  _divider(),
                  _sectionLabel('MORE FEATURES'),

                  _drawerActionItem(
                    icon: Icons.newspaper_outlined,
                    label: 'Agri News & Alerts',
                    iconBg: const Color(0xFFE3F2FD),
                    iconColor: const Color(0xFF1565C0),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NewsScreen()),
                      );
                    },
                  ),
                  _drawerActionItem(
                    icon: Icons.calendar_month_outlined,
                    label: 'Farming Calendar',
                    iconBg: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFE65100),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FarmingCalendarScreen(),
                        ),
                      );
                    },
                  ),

                  _divider(),
                  _sectionLabel('SYSTEM'),

                  _drawerActionItem(
                    icon: Icons.settings_outlined,
                    label: 'App Settings',
                    iconBg: const Color(0xFFECEFF1),
                    iconColor: const Color(0xFF455A64),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _drawerActionItem(
                    icon: Icons.info_outline_rounded,
                    label: 'About Govi-AI',
                    iconBg: const Color(0xFFE8F5E9),
                    iconColor: _headerGreen,
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog(context);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Logout button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  // Close drawer first
                  Navigator.of(context).pop();

                  // Small delay for drawer close animation
                  await Future.delayed(const Duration(milliseconds: 200));

                  if (!mounted) return;

                  // Show confirmation dialog
                  await _confirmLogout();
                },
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFFF8F00),
                  size: 18,
                ),
                label: Text(
                  'LOGOUT',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFF8F00),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF8F00), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              'Version 1.0.0  •  Govi-AI  •  Sri Lanka 🇱🇰',
              style: GoogleFonts.poppins(color: _textLight, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ── Drawer Header ─────────────────────────────────────────
  Widget _buildDrawerHeader() {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/farm_bg.jpg',
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_green1, _headerGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
          Positioned(right: -20, top: -20, child: _circle(110, 0.07)),
          Positioned(left: -10, bottom: 30, child: _circle(70, 0.06)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _lightGreen.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      color: _white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Govi-AI',
                    style: GoogleFonts.poppins(
                      color: _white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ආයුබෝවන් / Welcome',
                    style: GoogleFonts.poppins(
                      color: _white.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
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

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
    child: Text(
      label,
      style: GoogleFonts.poppins(
        color: _textLight,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
      ),
    ),
  );

  Widget _divider() =>
      const Divider(indent: 18, endIndent: 18, color: _cardBorder, height: 20);

  Widget _drawerNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color:
            isSelected
                ? _headerGreen.withValues(alpha: 0.08)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color:
                isSelected
                    ? _headerGreen.withValues(alpha: 0.12)
                    : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? _headerGreen : _textMid,
            size: 20,
          ),
        ),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? _headerGreen : _textDark,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        trailing:
            isSelected
                ? Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _headerGreen,
                    shape: BoxShape.circle,
                  ),
                )
                : null,
        onTap: () {
          setState(() => _currentIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _drawerActionItem({
    required IconData icon,
    required String label,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          label,
          style: GoogleFonts.poppins(color: _textDark, fontSize: 14),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 12,
          color: _textLight,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: _headerGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'About Govi-AI',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: _textDark,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Govi-AI is an intelligent crop disease '
                  'detection system built for Sri Lankan farmers.',
                  style: GoogleFonts.poppins(
                    color: _textMid,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                _aboutRow(Icons.group_outlined, 'Developed by Group 08'),
                const SizedBox(height: 6),
                _aboutRow(Icons.school_outlined, 'NSBM Green University'),
                const SizedBox(height: 6),
                _aboutRow(Icons.flag_outlined, 'Sri Lanka 🇱🇰'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _headerGreen,
                  foregroundColor: _white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }

  Widget _aboutRow(IconData icon, String text) => Row(
    children: [
      Icon(icon, color: _headerGreen, size: 16),
      const SizedBox(width: 8),
      Text(
        text,
        style: GoogleFonts.poppins(
          color: _textDark,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Logout',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: _textDark,
                fontSize: 17,
              ),
            ),
            content: Text(
              'Are you sure you want to logout?',
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
                  backgroundColor: const Color(0xFFFF8F00),
                  foregroundColor: _white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Logout',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await AuthService.logout();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
