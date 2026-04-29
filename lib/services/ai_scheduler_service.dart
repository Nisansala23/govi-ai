import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AiSchedulerService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String get uid => _auth.currentUser!.uid;

  // ─────────────────────────────
  // 🌱 AI RULE-BASED GENERATOR
  // ─────────────────────────────
  static List<Map<String, dynamic>> generateSchedule({
    required String crop,
    required DateTime plantingDate,
  }) {
    switch (crop) {
      case "Paddy":
        return [
          {
            "title": "Apply Basal Fertilizer",
            "type": "Fertilizing",
            "date": plantingDate.add(const Duration(days: 7)),
          },
          {
            "title": "Pest Inspection",
            "type": "Inspection",
            "date": plantingDate.add(const Duration(days: 14)),
          },
          {
            "title": "Water Level Check",
            "type": "Irrigation",
            "date": plantingDate.add(const Duration(days: 21)),
          },
        ];

      case "Tea":
        return [
          {
            "title": "Pruning Check",
            "type": "Maintenance",
            "date": plantingDate.add(const Duration(days: 10)),
          },
          {
            "title": "Fertilizer Application",
            "type": "Fertilizing",
            "date": plantingDate.add(const Duration(days: 20)),
          },
        ];

      case "Tomato":
        return [
          {
            "title": "Pest Control Spray",
            "type": "Spraying",
            "date": plantingDate.add(const Duration(days: 5)),
          },
          {
            "title": "Support Staking",
            "type": "Maintenance",
            "date": plantingDate.add(const Duration(days: 10)),
          },
        ];

      default:
        return [];
    }
  }

  // ─────────────────────────────
  // 🚫 SAFE AI GENERATION (NO DUPLICATES)
  // ─────────────────────────────
static Future<void> generateAndSaveSchedule({
  required String crop,
  required DateTime plantingDate,
}) async {
  final tasks = generateSchedule(
    crop: crop,
    plantingDate: plantingDate,
  );

  final userId = FirebaseAuth.instance.currentUser!.uid;

  final scheduleKey =
      "${crop}_${plantingDate.toIso8601String().substring(0, 10)}";

  // 🔍 CHECK EXISTING
  final existing = await FirebaseFirestore.instance
      .collection('farmers') // 🔥 FIXED
      .doc(userId)
      .collection('tasks')
      .where("scheduleKey", isEqualTo: scheduleKey)
      .get();

  if (existing.docs.isNotEmpty) return;

  // ✅ SAVE
  for (final task in tasks) {
    await FirebaseFirestore.instance
        .collection('farmers') // 🔥 FIXED
        .doc(userId)
        .collection('tasks')
        .add({
      "title": task["title"],
      "crop": crop,
      "type": task["type"],
      "date": Timestamp.fromDate(task["date"]),
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
      "source": "AI",
      "scheduleKey": scheduleKey,
    });
  }
}

  // ─────────────────────────────
  // 🔄 FORCE REGENERATE (OPTIONAL)
  // ─────────────────────────────
  static Future<void> regenerateSchedule({
    required String crop,
    required DateTime plantingDate,
  }) async {
    final batch = _db.batch();

    final old = await _db
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .where("source", isEqualTo: "AI")
        .get();

    for (var doc in old.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    await generateAndSaveSchedule(
      crop: crop,
      plantingDate: plantingDate,
    );
  }
}