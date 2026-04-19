import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Map<String, dynamic>? _selectedOutbreak;

  final List<Map<String, dynamic>> _outbreaks = [
    {
      'id': 1,
      'disease': 'Paddy Blast',
      'crop': 'Paddy',
      'district': 'Kurunegala',
      'severity': 'High',
      'reports': 12,
      'date': 'Apr 4, 2026',
      'lat': 7.4675,
      'lng': 80.3647,
      'color': AppColors.danger,
    },
    {
      'id': 2,
      'disease': 'Brown Planthopper',
      'crop': 'Paddy',
      'district': 'Anuradhapura',
      'severity': 'Medium',
      'reports': 8,
      'date': 'Apr 3, 2026',
      'lat': 8.3114,
      'lng': 80.4037,
      'color': AppColors.warning,
    },
    {
      'id': 3,
      'disease': 'Blister Blight',
      'crop': 'Tea',
      'district': 'Kandy',
      'severity': 'Medium',
      'reports': 6,
      'date': 'Apr 2, 2026',
      'lat': 7.2906,
      'lng': 80.6337,
      'color': AppColors.warning,
    },
    {
      'id': 4,
      'disease': 'Brown Spot',
      'crop': 'Paddy',
      'district': 'Polonnaruwa',
      'severity': 'Low',
      'reports': 3,
      'date': 'Apr 1, 2026',
      'lat': 7.9403,
      'lng': 81.0188,
      'color': AppColors.secondary,
    },
    {
      'id': 5,
      'disease': 'Tomato Blight',
      'crop': 'Tomato',
      'district': 'Nuwara Eliya',
      'severity': 'High',
      'reports': 9,
      'date': 'Mar 31, 2026',
      'lat': 6.9497,
      'lng': 80.7891,
      'color': AppColors.danger,
    },
    {
      'id': 6,
      'disease': 'Paddy Blast',
      'crop': 'Paddy',
      'district': 'Ampara',
      'severity': 'Low',
      'reports': 4,
      'date': 'Mar 30, 2026',
      'lat': 7.2980,
      'lng': 81.6724,
      'color': AppColors.secondary,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Disease Outbreak Map')),
      body: Stack(
        children: [
          _buildMap(),
          _buildStatsBar(),
          _buildLegend(),
          if (_selectedOutbreak != null) _buildOutbreakCard(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: ll.LatLng(7.8731, 80.7718),
        initialZoom: 7.5,
        onTap: (_, __) => setState(() => _selectedOutbreak = null),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.govi_ai',
        ),
        MarkerLayer(
          markers: _outbreaks.map((outbreak) {
            return Marker(
              point: ll.LatLng(
                outbreak['lat'] as double,
                outbreak['lng'] as double,
              ),
              width: 44,
              height: 44,
              child: GestureDetector(
                onTap: () => setState(() => _selectedOutbreak = outbreak),
                child: Container(
                  decoration: BoxDecoration(
                    color: outbreak['color'] as Color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: (outbreak['color'] as Color).withValues(
                          alpha: 0.4,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${outbreak['reports']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatsBar() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Total Outbreaks',
              '${_outbreaks.length}',
              AppColors.primary,
            ),
            _buildStatItem(
              'High Risk',
              '${_outbreaks.where((o) => o['severity'] == 'High').length}',
              AppColors.danger,
            ),
            _buildStatItem(
              'Districts',
              '${_outbreaks.map((o) => o['district']).toSet().length}',
              AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.heading3.copyWith(color: color)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildLegend() {
    return Positioned(
      bottom: 180,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Severity',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            _buildLegendItem('High', AppColors.danger),
            _buildLegendItem('Medium', AppColors.warning),
            _buildLegendItem('Low', AppColors.secondary),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          CircleAvatar(radius: 6, backgroundColor: color),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildOutbreakCard() {
    final outbreak = _selectedOutbreak!;
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (outbreak['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.bug_report,
                    color: outbreak['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        outbreak['disease'] as String,
                        style: AppTextStyles.heading3,
                      ),
                      Text(
                        '${outbreak['crop']} • ${outbreak['district']} District',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedOutbreak = null),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  'Severity: ${outbreak['severity']}',
                  outbreak['color'] as Color,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  '${outbreak['reports']} Reports',
                  AppColors.primary,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(outbreak['date'] as String, Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
