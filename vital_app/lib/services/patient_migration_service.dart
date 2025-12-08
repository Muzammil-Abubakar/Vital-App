import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to migrate existing patient records to the new profile schema
/// This handles patients who signed up before the new profiling system was implemented
class PatientMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Migrate a single patient's profile to the new schema
  /// This sets default values for missing fields and marks them as not profiled
  Future<void> migratePatientProfile(String patientId) async {
    try {
      final patientDoc = await _firestore
          .collection('patients')
          .doc(patientId)
          .get();

      if (!patientDoc.exists) {
        throw 'Patient document not found';
      }

      final data = patientDoc.data() as Map<String, dynamic>;
      final updates = <String, dynamic>{};

      // Check if already migrated (has profiled field)
      if (data.containsKey('profiled')) {
        // Already migrated, skip
        return;
      }

      // Set default values for new fields if they don't exist
      if (!data.containsKey('gender')) {
        updates['gender'] = 'other'; // Default gender
      }

      if (!data.containsKey('height')) {
        updates['height'] = 170.0; // Default height in cm
      }

      if (!data.containsKey('weight')) {
        updates['weight'] = 70.0; // Default weight in kg
      }

      // Calculate BMI if height and weight exist
      if (data.containsKey('height') && data.containsKey('weight')) {
        final height = (data['height'] as num).toDouble();
        final weight = (data['weight'] as num).toDouble();
        final heightInMeters = height / 100;
        final bmi = weight / (heightInMeters * heightInMeters);
        updates['bmi'] = bmi;
      } else if (updates.containsKey('height') &&
          updates.containsKey('weight')) {
        // Calculate BMI from default values
        final height = updates['height'] as double;
        final weight = updates['weight'] as double;
        final heightInMeters = height / 100;
        final bmi = weight / (heightInMeters * heightInMeters);
        updates['bmi'] = bmi;
      }

      // Mark as not profiled (they need to complete the profile)
      updates['profiled'] = false;

      // Add updatedAt timestamp
      updates['updatedAt'] = FieldValue.serverTimestamp();

      // Only update if there are changes
      if (updates.isNotEmpty) {
        await _firestore.collection('patients').doc(patientId).update(updates);
      }
    } catch (e) {
      throw 'Error migrating patient profile: $e';
    }
  }

  /// Migrate the current logged-in patient's profile
  Future<void> migrateCurrentPatient() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'No user logged in';
    }
    await migratePatientProfile(user.uid);
  }

  /// Migrate all existing patients (admin function)
  /// WARNING: This should be used carefully and preferably run as a one-time migration
  Future<void> migrateAllPatients() async {
    try {
      final patientsSnapshot = await _firestore.collection('patients').get();

      for (final doc in patientsSnapshot.docs) {
        try {
          await migratePatientProfile(doc.id);
        } catch (e) {
          // Log error but continue with other patients
          // ignore: avoid_print
          print('Error migrating patient ${doc.id}: $e');
        }
      }
    } catch (e) {
      throw 'Error migrating all patients: $e';
    }
  }

  /// Check if a patient needs migration
  Future<bool> needsMigration(String patientId) async {
    try {
      final patientDoc = await _firestore
          .collection('patients')
          .doc(patientId)
          .get();

      if (!patientDoc.exists) {
        return false;
      }

      final data = patientDoc.data() as Map<String, dynamic>;
      // If profiled field doesn't exist, needs migration
      return !data.containsKey('profiled');
    } catch (e) {
      return false;
    }
  }

  /// Check if current patient needs migration
  Future<bool> currentPatientNeedsMigration() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }
    return needsMigration(user.uid);
  }
}
