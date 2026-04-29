import 'package:cloud_firestore/cloud_firestore.dart';

class NewsService {
  Future<List<Map<String, dynamic>>> getNews() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('news')
          .orderBy('date', descending: true)
          .get();

      print("DOC COUNT: ${snap.docs.length}");

      return snap.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'category': data['category'] ?? 'All',
          'date': _formatDate(data['date']),
          'source': data['source'] ?? 'News',
          'isAlert': data['isAlert'] ?? false,
          'color': (data['isAlert'] ?? false) ? 'danger' : 'primary',
          'icon': (data['isAlert'] ?? false) ? 'warning' : 'article',
          'url': data['url'] ?? '',
          'image': data['image'] ?? '',
        };
      }).toList();
    } catch (e) {
      print("FIRESTORE ERROR: $e");
      return [];
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';

    if (date is Timestamp) {
      final d = date.toDate();
      return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    }

    if (date is String) return date;

    return '';
  }
}