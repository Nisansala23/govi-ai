import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class RssService {

  Future<List<Map<String, dynamic>>> fetchNews() async {
    final feeds = [
      'https://www.adaderana.lk/rss.php',
      'https://www.hirunews.lk/rss.php',
      'https://www.newsfirst.lk/feed/',
    ];

    List<Map<String, dynamic>> allNews = [];

    for (final feed in feeds) {
      try {
        final response = await http.get(Uri.parse(feed));

        if (response.statusCode != 200) continue;

        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');

        print("🟡 Feed: $feed → ${items.length} items");

        final newsItems = items.map((item) {
          final title = _getText(item, 'title');
          final description = _getText(item, 'description');
          final link = _getText(item, 'link');
          final date = _getText(item, 'pubDate');

          final text = (title + ' ' + description).toLowerCase();

          // ✅ RELAXED FILTER (IMPORTANT FIX)
          if (!_isAgricultureRelated(text)) return null;

          // ✅ IMAGE (safe)
          String imageUrl = '';
          try {
            final media = item.findElements('media:content');
            if (media.isNotEmpty) {
              imageUrl = media.first.getAttribute('url') ?? '';
            }
          } catch (_) {}

          return {
            'id': link.isNotEmpty ? link : title,
            'title': title,
            'description': _cleanHtml(description),
            'url': link,
            'date': date,
            'source': 'Sri Lanka News',
            'category': _detectCategory(text),
            'isAlert': _isAlert(text),
            'color': _isAlert(text) ? 'warning' : 'primary',
            'icon': _detectIcon(text),
            'image': imageUrl,
          };
        }).whereType<Map<String, dynamic>>().toList();

        print("🟢 After filter: ${newsItems.length}");

        allNews.addAll(newsItems);

      } catch (e) {
        print("❌ Feed error: $feed -> $e");
      }
    }

    // ✅ SORT
    allNews.sort((a, b) {
      if (a['isAlert'] == b['isAlert']) {
        return (b['date'] ?? '').compareTo(a['date'] ?? '');
      }
      return (b['isAlert'] ? 1 : 0)
          .compareTo(a['isAlert'] ? 1 : 0);
    });

    return allNews;
  }

  // ───────── HELPERS ─────────

  String _getText(XmlElement item, String tag) {
    final el = item.findElements(tag);
    return el.isNotEmpty ? el.first.innerText : '';
  }

  // ✅ FIXED: BROAD + SMART FILTER
  bool _isAgricultureRelated(String text) {
    final keywords = [
      'agriculture','farmer','farming','crop','harvest','cultivation',
      'rice','paddy','tea','rubber','coconut','vegetable','fruit',
      'maize','corn','onion','potato','chilli','banana',
      'fertilizer','pesticide','seed','irrigation',
      'rain','drought','flood','climate','weather',
      'pest','disease','outbreak'
    ];

    int score = 0;

    for (final k in keywords) {
      if (text.contains(k)) score++;
    }

    return score >= 1; // 🔥 VERY IMPORTANT
  }

  bool _isAlert(String text) {
    return text.contains('flood') ||
        text.contains('drought') ||
        text.contains('pest') ||
        text.contains('outbreak') ||
        text.contains('warning') ||
        text.contains('alert');
  }

  // ✅ NEW CATEGORY SYSTEM
  String _detectCategory(String text) {
    if (_isAlert(text)) return 'Alerts';

    if (text.contains('rain') ||
        text.contains('flood') ||
        text.contains('drought') ||
        text.contains('climate')) {
      return 'Weather';
    }

    if (text.contains('fertilizer') ||
        text.contains('irrigation') ||
        text.contains('farmer') ||
        text.contains('farming')) {
      return 'Farming';
    }

    return 'Crops';
  }

  String _detectIcon(String text) {
    if (text.contains('pest')) return 'bug';
    if (_isAlert(text)) return 'warning';
    if (text.contains('tea') || text.contains('crop')) return 'eco';
    return 'article';
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }
}