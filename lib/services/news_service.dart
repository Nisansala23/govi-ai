import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NewsService {
  static const _cacheKey = 'cached_news';
  static const _cacheTimeKey = 'cached_news_time';
  static const _cacheDuration = Duration(hours: 3);

  // ───────────────── MAIN ─────────────────

  Future<List<Map<String, dynamic>>> getNews() async {
    final isOnline = await _hasInternet();

    print("🌐 INTERNET: $isOnline");

    if (isOnline) {
      try {
        final results = await Future.wait([
          _fetchFromAPI(),
          _fetchAlertsFromFirestore(),
        ]);

        final apiNews = results[0];
        final alerts = results[1];

        print("📰 API NEWS COUNT: ${apiNews.length}");
        print("🚨 FIRESTORE ALERTS COUNT: ${alerts.length}");

        final combined = _mergeAndDeduplicate(apiNews, alerts);

        print("📦 COMBINED NEWS COUNT: ${combined.length}");

        if (combined.isNotEmpty) {
          await _saveToCache(combined);
        }

        return combined.isNotEmpty ? combined : _fallbackNews();

      } catch (e) {
        print("❌ ERROR FETCHING NEWS: $e");
        return await _loadFromCache();
      }
    }

    return await _loadFromCache();
  }

  // ───────────────── API ─────────────────

  Future<List<Map<String, dynamic>>> _fetchFromAPI() async {
    final apiKey = dotenv.env['NEWS_API_KEY'] ?? '';

    final url = Uri.parse(
      'https://gnews.io/api/v4/search'
      '?q=farming OR agriculture OR crops OR tea OR rice OR tomato'
      '&lang=en&max=10&apikey=$apiKey',
    );

    final res = await http.get(url);

    print("🌍 STATUS CODE: ${res.statusCode}");

    if (res.statusCode != 200) {
      print("📦 BODY: ${res.body}");
      return [];
    }

    final data = jsonDecode(res.body);

    final articles = (data['articles'] ?? []) as List;

    return articles.map((a) {
      final title = a['title'] ?? '';
      final isAlert = _isAlert(title);

      return {
        'id': a['url'] ?? title,
        'title': title,
        'description': a['description'] ?? '',
        'category': _detectCategory(title),
        'date': _formatDate(a['publishedAt']),
        'source': a['source']?['name'] ?? 'Unknown',
        'isAlert': isAlert,
        'color': isAlert ? 'warning' : 'primary',
        'icon': _detectIcon(title),
        'url': a['url'] ?? '',
      };
    }).toList();
  }

  // ───────────────── FIRESTORE ─────────────────

  Future<List<Map<String, dynamic>>> _fetchAlertsFromFirestore() async {
    final snap = await FirebaseFirestore.instance
        .collection('news')
        .orderBy('date', descending: true)
        .limit(10)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'title': data['title'] ?? '',
        'description': data['description'] ?? '',
        'category': data['category'] ?? 'Alerts',
        'date': _formatTimestamp(data['date']),
        'source': data['source'] ?? 'Gov',
        'isAlert': data['isAlert'] ?? true,
        'color': data['color'] ?? 'danger',
        'icon': data['icon'] ?? 'warning',
        'url': '',
      };
    }).toList();
  }

  // ───────────────── HELPERS ─────────────────

  Future<bool> _hasInternet() async {
    if (kIsWeb) return true;
    return true; // safe fallback (you can improve later)
  }

  List<Map<String, dynamic>> _mergeAndDeduplicate(
    List<Map<String, dynamic>> api,
    List<Map<String, dynamic>> alerts,
  ) {
    final map = <String, Map<String, dynamic>>{};

    for (var item in [...alerts, ...api]) {
      final key = item['url'] ?? item['title'];
      map[key] = item;
    }

    return map.values.toList();
  }

  List<Map<String, dynamic>> _fallbackNews() {
    return [
      {
        'title': 'No live news available right now',
        'description': 'Check again later or enable Firestore alerts',
        'category': 'All',
        'date': 'Now',
        'source': 'System',
        'isAlert': false,
        'color': 'primary',
        'icon': 'article',
        'url': '',
      }
    ];
  }

  String _detectCategory(String title) {
    final t = title.toLowerCase();

    if (t.contains('rice') || t.contains('paddy')) return 'Paddy';
    if (t.contains('tea')) return 'Tea';
    if (t.contains('tomato')) return 'Tomato';
    if (_isAlert(title)) return 'Alerts';

    return 'All';
  }

  String _detectIcon(String title) {
    final t = title.toLowerCase();

    if (t.contains('warning') || t.contains('alert')) return 'warning';
    if (t.contains('pest')) return 'bug';
    if (t.contains('tea')) return 'eco';
    if (t.contains('government')) return 'campaign';

    return 'article';
  }

  bool _isAlert(String title) {
    final t = title.toLowerCase();

    return t.contains('alert') ||
        t.contains('warning') ||
        t.contains('disease') ||
        t.contains('outbreak') ||
        t.contains('blight');
  }

  String _formatDate(String? iso) {
    final dt = DateTime.tryParse(iso ?? '');
    if (dt == null) return '';
    return '${_month(dt.month)} ${dt.day}, ${dt.year}';
  }

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      final dt = value.toDate();
      return '${_month(dt.month)} ${dt.day}, ${dt.year}';
    }
    return '';
  }

  String _month(int m) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return months[m - 1];
  }

  // ───────────────── CACHE ─────────────────

  Future<void> _saveToCache(List<Map<String, dynamic>> news) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(news));
    await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<Map<String, dynamic>>> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();

    final cached = prefs.getString(_cacheKey);
    final time = prefs.getInt(_cacheTimeKey);

    if (cached == null || time == null) return [];

    final isExpired = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(time)) >
        _cacheDuration;

    if (isExpired) return [];

    final List decoded = jsonDecode(cached);

    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}