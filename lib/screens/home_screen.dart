import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/ai_fab.dart'; // ✅ reusable AI button
import 'scanner_screen.dart';
import 'map_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      // ✅ AI FLOATING BUTTON
      floatingActionButton: const AiFab(),

      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: const [
                _Header(),
                SizedBox(height: 20),
                _WeatherCard(),
                SizedBox(height: 20),
                _ScanCard(),
                SizedBox(height: 20),
                _QuickActions(),
                SizedBox(height: 20),

                // ✅ NEW SECTION (added properly)
                _LastScanCard(),
                SizedBox(height: 20),
                _MarketCard(),
                SizedBox(height: 20),

                _DashboardRow(),
                SizedBox(height: 20),
                _TipCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// HEADER
////////////////////////////////////////////////////////////

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white.withOpacity(0.6),
          child: const Icon(Icons.person),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Good Morning 👋",
                  style: TextStyle(fontSize: 14, color: Colors.black54)),
              Text("Farmer Dashboard",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        // Notification
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {},
              ),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            )
          ],
        )
      ],
    );
  }
}

////////////////////////////////////////////////////////////
/// WEATHER
////////////////////////////////////////////////////////////

class _WeatherCard extends StatelessWidget {
  const _WeatherCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Colors.green],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("28°C",
                  style: TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              Text("Partly Cloudy",
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
          Icon(Icons.cloud, size: 40, color: Colors.white70)
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// SCAN CARD
////////////////////////////////////////////////////////////

class _ScanCard extends StatelessWidget {
  const _ScanCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScannerScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Icon(Icons.camera_alt, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Scan Crop Disease",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.white70)
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// QUICK ACTIONS
////////////////////////////////////////////////////////////

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _Action(
            icon: Icons.map,
            label: "Map",
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const MapScreen()))),
        _Action(
            icon: Icons.chat,
            label: "AI",
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
        _Action(icon: Icons.bar_chart, label: "Crops", onTap: () {}),
        _Action(icon: Icons.warning, label: "Alerts", onTap: () {}),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 24, color: Colors.black.withOpacity(0.7)),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12))
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// LAST SCAN
////////////////////////////////////////////////////////////

class _LastScanCard extends StatelessWidget {
  const _LastScanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.eco, size: 40, color: Colors.green),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Last Scan", style: TextStyle(color: Colors.black54)),
              Text("Tea - Blister Blight",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// MARKET CARD
////////////////////////////////////////////////////////////

class _MarketCard extends StatelessWidget {
  const _MarketCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Market Prices",
              style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("Paddy: Rs.120 ↑"),
          Text("Tomato: Rs.180 ↓"),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// DASHBOARD
////////////////////////////////////////////////////////////

class _DashboardRow extends StatelessWidget {
  const _DashboardRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _InfoCard(title: "Alerts", value: "2 Issues")),
        SizedBox(width: 12),
        Expanded(child: _InfoCard(title: "Health", value: "Good")),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const _InfoCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// TIP
////////////////////////////////////////////////////////////

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb, color: Colors.green),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Tip: Water crops early morning for best absorption.",
            ),
          )
        ],
      ),
    );
  }
}