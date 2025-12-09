import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password (for clinicians or basic patient signup)
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String name,
    required int age,
    required String userType, // 'clinician' or 'patient'
  }) async {
    try {
      // Create user account
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Store user profile data in Firestore - use separate collections
      final collectionName = userType == 'clinician'
          ? 'clinicians'
          : 'patients';
      await _firestore
          .collection(collectionName)
          .doc(userCredential.user?.uid)
          .set({
            'name': name,
            'age': age,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  // Sign up patient with extended profile fields
  Future<UserCredential?> signUpPatient({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    required double height,
    required double weight,
    required double bmi,
    required bool profiled,
  }) async {
    try {
      // Create user account
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Store patient profile data in Firestore
      await _firestore
          .collection('patients')
          .doc(userCredential.user?.uid)
          .set({
            'name': name,
            'age': age,
            'email': email,
            'gender': gender,
            'height': height,
            'weight': weight,
            'bmi': bmi,
            'profiled': profiled,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  // Sign up clinician with documents
  Future<UserCredential?> signUpClinician({
    required String email,
    required String password,
    required String name,
    required int age,
    required List<String> documentNames,
  }) async {
    try {
      // Create user account
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Store clinician profile data in Firestore
      await _firestore
          .collection('clinicians')
          .doc(userCredential.user?.uid)
          .set({
            'name': name,
            'age': age,
            'email': email,
            'verified': false, // Unverified by default
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Store documents
      if (documentNames.isNotEmpty) {
        final batch = _firestore.batch();
        for (final docName in documentNames) {
          final docRef = _firestore
              .collection('clinicians')
              .doc(userCredential.user?.uid)
              .collection('documents')
              .doc();
          batch.set(docRef, {
            'name': docName,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  // Update patient profile
  Future<void> updatePatientProfile({
    required String uid,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      await _firestore.collection('patients').doc(uid).update({
        ...profileData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Error updating profile: $e';
    }
  }

  // Mark patient as fully profiled
  Future<void> markPatientAsProfiled(String uid) async {
    try {
      await _firestore.collection('patients').doc(uid).update({
        'profiled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Error updating profile status: $e';
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  // Get user profile data from Firestore
  // userType should be 'clinician' or 'patient'
  Future<Map<String, dynamic>?> getUserProfile(
    String uid,
    String userType,
  ) async {
    try {
      final collectionName = userType == 'clinician'
          ? 'clinicians'
          : 'patients';
      DocumentSnapshot doc = await _firestore
          .collection(collectionName)
          .doc(uid)
          .get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      throw 'Error fetching user profile: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}
