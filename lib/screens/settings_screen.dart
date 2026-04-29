import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _dataSync = true;
  String _selectedLanguage = 'English';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc =
          await FirebaseFirestore.instance.collection('farmers').doc(uid).get();

      if (doc.exists && mounted) {
        setState(() {
          _notificationsEnabled = doc.data()?['notificationsEnabled'] ?? true;
          _selectedLanguage = doc.data()?['language'] ?? 'English';
          _dataSync = doc.data()?['dataSync'] ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ Password Reset - sends real email
  Future<void> _handlePasswordReset() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.lock_reset, color: Colors.blue),
                SizedBox(width: 8),
                Text('Reset Password'),
              ],
            ),
            content: Text('A password reset link will be sent to:\n\n$email'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Send Link',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Reset link sent to $email')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error sending reset email'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ✅ Privacy Policy - shows dialog (no fake URL)
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.privacy_tip, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Privacy Policy'),
              ],
            ),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last updated: May 2026',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '1. Data Collection',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Govi-AI collects crop scan images, '
                    'GPS location data, and farmer profile '
                    'information to provide disease detection '
                    'and community outbreak mapping services.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '2. Data Usage',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your scan data is used to improve '
                    'disease detection accuracy and generate '
                    'community outbreak alerts. Location data '
                    'is anonymized before sharing.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '3. Data Storage',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'All data is securely stored in Google '
                    'Firebase servers. Personal information '
                    'is never sold to third parties.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '4. Your Rights',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'You can delete your account and all '
                    'associated data at any time by contacting '
                    'our support team.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '5. Contact',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Group 08 - NSBM Green University\n'
                    'SE303.3-MAD Module • 2026',
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  // ✅ Help Center - shows dialog with real help content
  void _showHelpCenter() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.help, color: Colors.purple),
                SizedBox(width: 8),
                Text('Help Center'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHelpItem(
                    icon: Icons.camera_alt,
                    color: AppColors.primary,
                    question: 'How do I scan a crop?',
                    answer:
                        'Go to the Scanner tab, select your '
                        'crop type (Paddy/Tea/Tomato), then '
                        'take a photo or pick from gallery. '
                        'Tap "Analyze Disease" to get results.',
                  ),
                  const Divider(),
                  _buildHelpItem(
                    icon: Icons.map,
                    color: Colors.blue,
                    question: 'What is the Disease Map?',
                    answer:
                        'The Disease Map shows real-time '
                        'outbreak reports from farmers in '
                        'your area. Each dot represents a '
                        'reported disease at that location.',
                  ),
                  const Divider(),
                  _buildHelpItem(
                    icon: Icons.location_on,
                    color: Colors.orange,
                    question: 'Why does the app need my location?',
                    answer:
                        'Location is used to pin your disease '
                        'report on the community map. This '
                        'helps warn nearby farmers about '
                        'spreading diseases.',
                  ),
                  const Divider(),
                  _buildHelpItem(
                    icon: Icons.wifi_off,
                    color: Colors.grey,
                    question: 'Does it work without internet?',
                    answer:
                        'The AI scanning requires internet '
                        'to analyze images. However, you can '
                        'view your previous scan history '
                        'without a connection.',
                  ),
                  const Divider(),
                  _buildHelpItem(
                    icon: Icons.translate,
                    color: Colors.teal,
                    question: 'How to change language?',
                    answer:
                        'Go to Settings → Preferences → '
                        'App Language. Choose between '
                        'English, සිංහල, or தமிழ்.',
                  ),
                  const Divider(),
                  _buildHelpItem(
                    icon: Icons.bug_report,
                    color: AppColors.danger,
                    question: 'AI gave wrong diagnosis?',
                    answer:
                        'For best results: use good lighting, '
                        'focus on the diseased leaf area, '
                        'hold camera steady, and fill the '
                        'frame with the leaf. Try again with '
                        'a clearer photo.',
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  // ✅ Contact Us dialog
  void _showContactUs() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.contact_mail, color: Colors.green),
                SizedBox(width: 8),
                Text('Contact Us'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildContactItem(
                  icon: Icons.school,
                  label: 'Institution',
                  value: 'NSBM Green University',
                ),
                const SizedBox(height: 12),
                _buildContactItem(
                  icon: Icons.group,
                  label: 'Team',
                  value: 'Group 08 - SE303.3-MAD',
                ),
                const SizedBox(height: 12),
                _buildContactItem(
                  icon: Icons.email,
                  label: 'Module Leader',
                  value: 'diluka.w@nsbm.ac.lk',
                  onTap: () async {
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: 'diluka.w@nsbm.ac.lk',
                      query: 'subject=Govi-AI Support',
                    );
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    }
                  },
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  // ✅ About dialog
  void _showAboutApp() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Text('🌾', style: TextStyle(fontSize: 48))),
                SizedBox(height: 12),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Govi-AI is an intelligent crop disease '
                  'detection system designed specifically '
                  'for Sri Lankan farmers.',
                ),
                SizedBox(height: 8),
                Text(
                  '• AI powered by Groq Llama-4\n'
                  '• Real-time community outbreak map\n'
                  '• Sinhala language support\n'
                  '• GPS-based disease tracking',
                ),
                SizedBox(height: 12),
                Text(
                  'Developed by Group 08\n'
                  'NSBM Green University\n'
                  'SE303.3-MAD • 2026',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── ACCOUNT ──────────────────────────────
          _buildSectionTitle('Account'),
          _buildSettingCard([
            ListTile(
              leading: _iconContainer(Icons.lock_reset, Colors.blue),
              title: const Text('Reset Password'),
              subtitle: const Text('Send reset link to your email'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: _handlePasswordReset, // ✅ WORKS
            ),
          ]),
          const SizedBox(height: 20),

          // ── PREFERENCES ──────────────────────────
          _buildSectionTitle('Preferences'),
          _buildSettingCard([
            SwitchListTile(
              secondary: _iconContainer(
                Icons.notifications_outlined,
                AppColors.primary,
              ),
              title: const Text('Push Notifications'),
              subtitle: Text(
                _notificationsEnabled ? 'Enabled' : 'Disabled',
                style: const TextStyle(fontSize: 12),
              ),
              value: _notificationsEnabled,
              activeColor: AppColors.primary,
              onChanged: (val) => _updateSetting('notificationsEnabled', val),
            ),
            const Divider(height: 1),
            ListTile(
              leading: _iconContainer(Icons.language_outlined, Colors.orange),
              title: const Text('App Language'),
              trailing: DropdownButton<String>(
                value: _selectedLanguage,
                underline: const SizedBox(),
                items:
                    ['English', 'සිංහල', 'தமிழ்']
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                onChanged:
                    (val) =>
                        val != null ? _updateSetting('language', val) : null,
              ),
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary: _iconContainer(Icons.sync, Colors.teal),
              title: const Text('Cloud Data Sync'),
              subtitle: Text(
                _dataSync ? 'Syncing to Firebase' : 'Sync disabled',
                style: const TextStyle(fontSize: 12),
              ),
              value: _dataSync,
              activeColor: AppColors.primary,
              onChanged: (val) => _updateSetting('dataSync', val),
            ),
          ]),
          const SizedBox(height: 20),

          // ── SUPPORT & LEGAL ───────────────────────
          _buildSectionTitle('Support & Legal'),
          _buildSettingCard([
            ListTile(
              leading: _iconContainer(Icons.help_outline, Colors.purple),
              title: const Text('Help Center'),
              subtitle: const Text('FAQs and how-to guides'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: _showHelpCenter, // ✅ WORKS - shows dialog
            ),
            const Divider(height: 1),
            ListTile(
              leading: _iconContainer(
                Icons.privacy_tip_outlined,
                Colors.redAccent,
              ),
              title: const Text('Privacy Policy'),
              subtitle: const Text('How we handle your data'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: _showPrivacyPolicy, // ✅ WORKS - shows dialog
            ),
            const Divider(height: 1),
            ListTile(
              leading: _iconContainer(
                Icons.contact_mail_outlined,
                Colors.green,
              ),
              title: const Text('Contact Us'),
              subtitle: const Text('Get in touch with our team'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: _showContactUs, // ✅ WORKS - shows dialog
            ),
          ]),
          const SizedBox(height: 20),

          // ── ABOUT ─────────────────────────────────
          _buildSectionTitle('About'),
          _buildSettingCard([
            ListTile(
              leading: _iconContainer(Icons.eco, AppColors.primary),
              title: const Text('About Govi-AI'),
              subtitle: const Text('Version 1.0.0'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: _showAboutApp, // ✅ WORKS - shows dialog
            ),
          ]),

          const SizedBox(height: 32),

          // Version footer
          Center(
            child: Text(
              'Govi-AI • Version 1.0.0\nNSBM Green University • Group 08',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── HELPER WIDGETS ────────────────────────────────

  Widget _buildHelpItem({
    required IconData icon,
    required Color color,
    required String question,
    required String answer,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  answer,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onTap != null ? Colors.blue : AppColors.textPrimary,
                    decoration: onTap != null ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _iconContainer(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    setState(() {
      if (key == 'notificationsEnabled') _notificationsEnabled = value;
      if (key == 'language') _selectedLanguage = value;
      if (key == 'dataSync') _dataSync = value;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('farmers').doc(uid).update({
        key: value,
      });
    } catch (e) {
      debugPrint('Update error: $e');
    }
  }
}
