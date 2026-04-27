import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Map<String, dynamic>? _selectedOutbreak;
  List<Map<String, dynamic>> _outbreaks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOutbreaks();
  }

  // ✅ Get color based on severity
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return AppColors.danger;
      case 'medium':
      case 'moderate':
        return AppColors.warning;
      default:
        return AppColors.secondary;
    }
  }

  // ✅ Load REAL outbreaks from Firebase
  Future<void> _loadOutbreaks() async {
    setState(() => _isLoading = true);
    try {
      // Use AuthService.getOutbreaks() which reads from 'outbreaks' collection
      final data = await AuthService.getOutbreaks();

      // Add color based on severity
      final outbreaksWithColor = data.map((outbreak) {
        return {
          ...outbreak,
          'color': _getSeverityColor(outbreak['severity'] ?? 'low'),
        };
      }).toList();

      setState(() {
        _outbreaks = outbreaksWithColor;
        _isLoading = false;
      });

      debugPrint('✅ Loaded ${_outbreaks.length} outbreaks from Firebase');
    } catch (e) {
      debugPrint('❌ Error loading outbreaks: $e');
      setState(() => _isLoading = false);
    }
  }

  // ✅ Format Firestore timestamp
  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown Date';
    try {
      final DateTime d = (date as Timestamp).toDate();
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
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (e) {
      return 'Unknown Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Disease Outbreak Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOutbreaks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : Stack(
              children: [
                _buildMap(),
                _buildStatsBar(),
                _buildLegend(),
                if (_outbreaks.isEmpty) _buildEmptyState(),
                if (_selectedOutbreak != null) _buildOutbreakCard(),
              ],
            ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text('Loading outbreak data...', style: AppTextStyles.bodyText),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppColors.secondary,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text('No Active Outbreaks', style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Text(
              'No disease outbreaks reported yet.\nScan crops to add to community map!',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
            final double lat = (outbreak['lat'] as num?)?.toDouble() ?? 7.8731;
            final double lng = (outbreak['lng'] as num?)?.toDouble() ?? 80.7718;

            return Marker(
              point: ll.LatLng(lat, lng),
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
                  child: const Center(
                    child: Icon(
                      Icons.bug_report,
                      color: Colors.white,
                      size: 20,
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
    final highRisk = _outbreaks
        .where((o) => (o['severity'] ?? '').toString().toLowerCase() == 'high')
        .length;
    final districts = _outbreaks.map((o) => o['district']).toSet().length;

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
            _buildStatItem('High Risk', '$highRisk', AppColors.danger),
            _buildStatItem('Districts', '$districts', AppColors.warning),
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
    final color = outbreak['color'] as Color;

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
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.bug_report, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        outbreak['disease'] ?? 'Unknown Disease',
                        style: AppTextStyles.heading3,
                      ),
                      Text(
                        '${outbreak['crop'] ?? 'Unknown'} • '
                        '${outbreak['district'] ?? 'Unknown'} District',
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
                  'Severity: ${outbreak['severity'] ?? 'Unknown'}',
                  color,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(_formatDate(outbreak['date']), Colors.grey),
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
