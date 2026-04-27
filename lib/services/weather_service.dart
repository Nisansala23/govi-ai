import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // Sri Lankan district coordinates
  static const Map<String, Map<String, double>> _districtCoords = {
    'Colombo': {'lat': 6.9271, 'lng': 79.8612},
    'Kandy': {'lat': 7.2906, 'lng': 80.6337},
    'Galle': {'lat': 6.0535, 'lng': 80.2210},
    'Kurunegala': {'lat': 7.4675, 'lng': 80.3647},
    'Anuradhapura': {'lat': 8.3114, 'lng': 80.4037},
    'Jaffna': {'lat': 9.6615, 'lng': 80.0255},
    'Trincomalee': {'lat': 8.5874, 'lng': 81.2152},
    'Batticaloa': {'lat': 7.7170, 'lng': 81.7000},
    'Matara': {'lat': 5.9549, 'lng': 80.5550},
    'Ratnapura': {'lat': 6.6828, 'lng': 80.3992},
    'Badulla': {'lat': 6.9934, 'lng': 81.0550},
    'Nuwara Eliya': {'lat': 6.9497, 'lng': 80.7891},
    'Polonnaruwa': {'lat': 7.9403, 'lng': 81.0188},
    'Ampara': {'lat': 7.2980, 'lng': 81.6724},
    'Hambantota': {'lat': 6.1241, 'lng': 81.1185},
    'Kalutara': {'lat': 6.5854, 'lng': 79.9607},
    'Gampaha': {'lat': 7.0873, 'lng': 79.9990},
    'Matale': {'lat': 7.4675, 'lng': 80.6234},
    'Kegalle': {'lat': 7.2513, 'lng': 80.3464},
    'Puttalam': {'lat': 8.0362, 'lng': 79.8283},
    'Monaragala': {'lat': 6.8727, 'lng': 81.3507},
  };

  static Future<Map<String, dynamic>?> getWeather(String district) async {
    try {
      // Get coordinates for district
      final coords =
          _districtCoords[district] ??
          {'lat': 7.8731, 'lng': 80.7718}; // default Sri Lanka center

      final lat = coords['lat'];
      final lng = coords['lng'];

      final url =
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current=temperature_2m,relative_humidity_2m,weathercode,windspeed_10m&timezone=Asia%2FColombo';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'];
        final temp = current['temperature_2m'];
        final humidity = current['relative_humidity_2m'];
        final windspeed = current['windspeed_10m'];
        final weatherCode = current['weathercode'];

        return {
          'temp': temp.round().toString(),
          'humidity': humidity.toString(),
          'windspeed': windspeed.toString(),
          'description': _getWeatherDescription(weatherCode),
          'icon': _getWeatherIcon(weatherCode),
          'city': district,
        };
      }
      return null;
    } catch (e) {
      print('Weather error: $e');
      return null;
    }
  }

  static String _getWeatherDescription(int code) {
    if (code == 0) return 'Clear Sky';
    if (code <= 3) return 'Partly Cloudy';
    if (code <= 49) return 'Foggy';
    if (code <= 59) return 'Drizzle';
    if (code <= 69) return 'Rainy';
    if (code <= 79) return 'Snowy';
    if (code <= 82) return 'Rain Showers';
    if (code <= 99) return 'Thunderstorm';
    return 'Cloudy';
  }

  static String _getWeatherIcon(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 49) return '🌫️';
    if (code <= 69) return '🌧️';
    if (code <= 82) return '🌦️';
    if (code <= 99) return '⛈️';
    return '☁️';
  }
}
