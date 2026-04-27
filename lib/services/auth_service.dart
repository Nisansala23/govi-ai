import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register
  static Future<String?> register({
    required String email,
    required String password,
    required String name,
    required String district,
    required String phone,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('farmers').doc(credential.user!.uid).set({
        'name': name,
        'district': district,
        'phone': phone,
        'email': email,
        'totalScans': 0,
        'diseasesFound': 0,
        'healthyScans': 0,
        'profileImageUrl': null,
        'notificationsEnabled': true,
        'language': 'English',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ User registered: $email');
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Register error: ${e.message}');
      return e.message;
    } catch (e) {
      debugPrint('❌ Register error: $e');
      return e.toString();
    }
  }

  // Login
  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      debugPrint('✅ User logged in: $email');
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Login error: ${e.message}');
      return e.message;
    } catch (e) {
      debugPrint('❌ Login error: $e');
      return e.toString();
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      await _auth.signOut();
      debugPrint('✅ User logged out');
    } catch (e) {
      debugPrint('❌ Logout error: $e');
    }
  }

  // ─────────────────────────────────────────
  // FARMER PROFILE
  // ─────────────────────────────────────────

  // Get farmer profile
  static Future<Map<String, dynamic>?> getFarmerProfile() async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) return null;

      final doc = await _firestore.collection('farmers').doc(uid).get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting profile: $e');
      return null;
    }
  }

  // Update farmer profile
  static Future<bool> updateFarmerProfile({
    required String name,
    required String phone,
    required String district,
  }) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) return false;

      await _firestore.collection('farmers').doc(uid).update({
        'name': name,
        'phone': phone,
        'district': district,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Profile updated');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      return false;
    }
  }

  // Update profile image URL
  static Future<void> updateProfileImage(String imageUrl) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) return;

      await _firestore.collection('farmers').doc(uid).update({
        'profileImageUrl': imageUrl,
      });

      debugPrint('✅ Profile image updated');
    } catch (e) {
      debugPrint('❌ Error updating profile image: $e');
    }
  }

  // Update notification setting
  static Future<void> updateNotificationSetting(bool enabled) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) return;

      await _firestore.collection('farmers').doc(uid).update({
        'notificationsEnabled': enabled,
      });

      debugPrint('✅ Notification setting updated: $enabled');
    } catch (e) {
      debugPrint('❌ Error updating notification: $e');
    }
  }

  // Update language setting
  static Future<void> updateLanguage(String language) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) return;

      await _firestore.collection('farmers').doc(uid).update({
        'language': language,
      });

      debugPrint('✅ Language updated: $language');
    } catch (e) {
      debugPrint('❌ Error updating language: $e');
    }
  }

  // ─────────────────────────────────────────
  // SCAN HISTORY
  // ─────────────────────────────────────────

  // Save scan result with real location
  static Future<void> saveScanResult({
    required String disease,
    required String crop,
    required String severity,
    required String confidence,
    required double lat,
    required double lng,
    required String district,
    bool locationAvailable = false,
  }) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) {
        debugPrint('❌ No user logged in');
        return;
      }

      final bool isHealthy = disease.toLowerCase() == 'healthy';

      // ✅ Save to farmer's personal scan history
      await _firestore.collection('farmers').doc(uid).collection('scans').add({
        'disease': disease,
        'crop': crop,
        'severity': severity,
        'confidence': confidence,
        'lat': lat,
        'lng': lng,
        'district': district,
        'locationAvailable': locationAvailable,
        'date': FieldValue.serverTimestamp(),
        'isHealthy': isHealthy,
      });

      // ✅ Save to global outbreaks (for community map)
      if (!isHealthy) {
        await _firestore.collection('outbreaks').add({
          'disease': disease,
          'crop': crop,
          'severity': severity,
          'district': district,
          'lat': lat,
          'lng': lng,
          'locationAvailable': locationAvailable,
          'date': FieldValue.serverTimestamp(),
          'farmerUid': uid,
        });

        debugPrint('✅ Outbreak saved: $disease at $district ($lat, $lng)');
      }

      // ✅ Update farmer stats
      await _firestore.collection('farmers').doc(uid).update({
        'totalScans': FieldValue.increment(1),
        'diseasesFound': isHealthy
            ? FieldValue.increment(0)
            : FieldValue.increment(1),
        'healthyScans': isHealthy
            ? FieldValue.increment(1)
            : FieldValue.increment(0),
        'lastScanAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Scan saved: $disease ($crop) - $district');
    } catch (e) {
      debugPrint('❌ Error saving scan: $e');
    }
  }

  // Get scan history for current farmer
  static Future<List<Map<String, dynamic>>> getScanHistory() async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) return [];

      final snapshot = await _firestore
          .collection('farmers')
          .doc(uid)
          .collection('scans')
          .orderBy('date', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting scan history: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────
  // OUTBREAKS (COMMUNITY MAP)
  // ─────────────────────────────────────────

  // Get all outbreaks for community map
  static Future<List<Map<String, dynamic>>> getOutbreaks() async {
    try {
      final snapshot = await _firestore
          .collection('outbreaks')
          .orderBy('date', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting outbreaks: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────
  // FARMER FIELDS
  // ─────────────────────────────────────────

  // Get farmer's crop fields
  static Future<List<Map<String, dynamic>>> getFarmerFields() async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) return [];

      final snapshot = await _firestore
          .collection('farmers')
          .doc(uid)
          .collection('fields')
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting fields: $e');
      return [];
    }
  }

  // Add a new field
  static Future<bool> addField({
    required String name,
    required String cropType,
    required String location,
  }) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) return false;

      await _firestore.collection('farmers').doc(uid).collection('fields').add({
        'name': name,
        'cropType': cropType,
        'location': location,
        'status': 'Healthy',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Field added: $name ($cropType)');
      return true;
    } catch (e) {
      debugPrint('❌ Error adding field: $e');
      return false;
    }
  }

  // Update field status
  static Future<void> updateFieldStatus({
    required String fieldId,
    required String status,
  }) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) return;

      await _firestore
          .collection('farmers')
          .doc(uid)
          .collection('fields')
          .doc(fieldId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      debugPrint('✅ Field status updated: $status');
    } catch (e) {
      debugPrint('❌ Error updating field: $e');
    }
  }

  // Delete a field
  static Future<bool> deleteField(String fieldId) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) return false;

      await _firestore
          .collection('farmers')
          .doc(uid)
          .collection('fields')
          .doc(fieldId)
          .delete();

      debugPrint('✅ Field deleted: $fieldId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting field: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────

  // Check if user is logged in
  static bool get isLoggedIn => currentUser != null;

  // Get current user ID
  static String? get currentUserId => currentUser?.uid;

  // Get current user email
  static String? get currentUserEmail => currentUser?.email;
}
