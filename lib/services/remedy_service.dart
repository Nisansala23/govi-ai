
class RemedyService {
  static Future<Map<String, dynamic>> getRemedy(String key) async {
    // 🌿 Offline dummy database (you can expand later)
    final Map<String, Map<String, dynamic>> database = {
      "paddy_blast": {
        "sinhala": "බ්ලාස්ට් රෝගය සඳහා කොළ ඉවත් කරන්න.",
        "organic": "නීම් තෙල් ඉසීම කරන්න.",
        "chemical": "Tricyclazole 75% WP භාවිතා කරන්න.",
        "dosage": "ග්‍රෑම් 2 / ලීටර් 1",
        "shop": "Agro shops in your area",
      },
      "tea_red_spot": {
        "sinhala": "රතු ලප රෝගය පාලනය කරන්න.",
        "organic": "කොම්පෝස්ට් වැඩි කරන්න.",
        "chemical": "Copper fungicide භාවිතා කරන්න.",
        "dosage": "මිලි 3 / ලීටර් 1",
        "shop": "Tea estate stores",
      },
    };

    return database[key] ?? {};
  }
}