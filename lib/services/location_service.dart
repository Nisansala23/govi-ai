import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static const List<Map<String, dynamic>> _districts = [
    {'name': 'Colombo', 'lat': 6.9271, 'lng': 79.8612},
    {'name': 'Gampaha', 'lat': 7.0917, 'lng': 80.0000},
    {'name': 'Kalutara', 'lat': 6.5854, 'lng': 80.0000},
    {'name': 'Kandy', 'lat': 7.2906, 'lng': 80.6337},
    {'name': 'Matale', 'lat': 7.4675, 'lng': 80.6234},
    {'name': 'Nuwara Eliya', 'lat': 6.9497, 'lng': 80.7891},
    {'name': 'Galle', 'lat': 6.0535, 'lng': 80.2210},
    {'name': 'Matara', 'lat': 5.9549, 'lng': 80.5550},
    {'name': 'Hambantota', 'lat': 6.1429, 'lng': 81.1212},
    {'name': 'Jaffna', 'lat': 9.6615, 'lng': 80.0255},
    {'name': 'Kilinochchi', 'lat': 9.3803, 'lng': 80.3770},
    {'name': 'Mannar', 'lat': 8.9810, 'lng': 79.9044},
    {'name': 'Vavuniya', 'lat': 8.7514, 'lng': 80.4971},
    {'name': 'Mullaitivu', 'lat': 9.2671, 'lng': 80.8128},
    {'name': 'Batticaloa', 'lat': 7.7310, 'lng': 81.6747},
    {'name': 'Ampara', 'lat': 7.2980, 'lng': 81.6724},
    {'name': 'Trincomalee', 'lat': 8.5874, 'lng': 81.2152},
    {'name': 'Kurunegala', 'lat': 7.4675, 'lng': 80.3647},
    {'name': 'Puttalam', 'lat': 8.0362, 'lng': 79.8283},
    {'name': 'Anuradhapura', 'lat': 8.3114, 'lng': 80.4037},
    {'name': 'Polonnaruwa', 'lat': 7.9403, 'lng': 81.0188},
    {'name': 'Badulla', 'lat': 6.9934, 'lng': 81.0550},
    {'name': 'Moneragala', 'lat': 6.8728, 'lng': 81.3507},
    {'name': 'Ratnapura', 'lat': 6.6828, 'lng': 80.3992},
    {'name': 'Kegalle', 'lat': 7.2513, 'lng': 80.3464},
  ];

  static Future<Map<String, dynamic>> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _defaultLocation();
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return _defaultLocation();
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _defaultLocation();

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final String district = _findNearestDistrict(
        position.latitude,
        position.longitude,
      );

      debugPrint('📍 GPS: ${position.latitude}, ${position.longitude}');
      debugPrint('🏘️ District: $district');

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'district': district,
        'locationAvailable': true,
      };
    } catch (e) {
      debugPrint('❌ Location error: $e');
      return _defaultLocation();
    }
  }

  static String _findNearestDistrict(double lat, double lng) {
    String nearest = 'Unknown District';
    double minDist = double.infinity;

    for (final d in _districts) {
      final double dlat = lat - (d['lat'] as double);
      final double dlng = lng - (d['lng'] as double);
      final double dist = (dlat * dlat) + (dlng * dlng);
      if (dist < minDist) {
        minDist = dist;
        nearest = d['name'] as String;
      }
    }
    return nearest;
  }

  static Map<String, dynamic> _defaultLocation() {
    return {
      'latitude': 7.8731,
      'longitude': 80.7718,
      'district': 'Unknown District',
      'locationAvailable': false,
    };
  }
}
