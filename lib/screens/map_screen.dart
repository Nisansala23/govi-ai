import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../widgets/ai_fab.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Map<String, dynamic>? selectedOutbreak;

  final ll.LatLng _center = ll.LatLng(7.8731, 80.7718);

  Color _getColor(String severity) {
    switch (severity) {
      case 'High':
        return AppColors.danger;
      case 'Medium':
        return AppColors.warning;
      default:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("AI Agriculture Map"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          )
        ],
      ),

      floatingActionButton: const AiFab(), // ✅ ADDED HERE

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('outbreaks')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final markers = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final color = _getColor(data['severity'] ?? 'Low');

            return Marker(
              point: ll.LatLng(
                (data['lat'] ?? 0).toDouble(),
                (data['lng'] ?? 0).toDouble(),
              ),
              width: 45,
              height: 45,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedOutbreak = data;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            );
          }).toList();

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 7.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: "com.example.app",
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),

              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: _buildStats(docs.length),
              ),

              if (selectedOutbreak != null)
                _buildDetailCard(selectedOutbreak!),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStats(int total) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat("Total", "$total", AppColors.primary),
          _stat("High", "🔥", AppColors.danger),
          _stat("Live", "AI", AppColors.warning),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              color: color, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildDetailCard(Map<String, dynamic> data) {
    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data['disease'] ?? 'Unknown Disease',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      selectedOutbreak = null;
                    });
                  },
                )
              ],
            ),
            const SizedBox(height: 6),
            Text("Crop: ${data['crop'] ?? ''}"),
            Text("District: ${data['district'] ?? ''}"),
            Text("Severity: ${data['severity'] ?? ''}"),
            Text("Reports: ${data['reports'] ?? ''}"),
          ],
        ),
      ),
    );
  }
}