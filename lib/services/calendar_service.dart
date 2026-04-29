import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get uid => _auth.currentUser!.uid;

  // ➕ ADD TASK
  static Future<void> addTask({
    required String title,
    required String crop,
    required String type,
    required DateTime date,
  }) async {
    await _db
        .collection('farmers') // 🔥 FIXED
        .doc(uid)
        .collection('tasks')
        .add({
      "title": title,
      "crop": crop,
      "type": type,
      "date": Timestamp.fromDate(date),
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  // 📡 GET TASKS
  static Stream<QuerySnapshot> getTasks() {
    return _db
        .collection('farmers') // 🔥 FIXED
        .doc(uid)
        .collection('tasks')
        .orderBy('date')
        .snapshots();
  }

  // ❌ DELETE TASK
  static Future<void> deleteTask(String id) async {
    await _db
        .collection('farmers') // 🔥 FIXED
        .doc(uid)
        .collection('tasks')
        .doc(id)
        .delete();
  }
}