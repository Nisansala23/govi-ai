import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      // Save profile to Firestore
      await _firestore.collection('farmers').doc(credential.user!.uid).set({
        'name': name,
        'district': district,
        'phone': phone,
        'email': email,
        'totalScans': 0,
        'diseasesFound': 0,
        'healthyScans': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // null means success
    } on FirebaseAuthException catch (e) {
      return e.message; // return error message
    }
  }

  // Login
  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // null means success
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Logout
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // Get farmer profile
  static Future<Map<String, dynamic>?> getFarmerProfile() async {
    try {
      final doc = await _firestore
          .collection('farmers')
          .doc(currentUser!.uid)
          .get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }
}
