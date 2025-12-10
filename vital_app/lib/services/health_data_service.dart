import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HealthDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get today's date as a string key (YYYY-MM-DD)
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Store daily health data
  Future<void> storeDailyHealthData({
    int? steps,
    double? caloriesBurned,
    double? hoursSlept,
    double? heartRate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'No user logged in';
    }

    final dateKey = _getTodayKey();
    final healthData = <String, dynamic>{
      'date': dateKey,
      'timestamp': FieldValue.serverTimestamp(),
      'steps': steps,
      'caloriesBurned': caloriesBurned,
      'hoursSlept': hoursSlept,
      'heartRate': heartRate,
    };

    // Store in patients/{userId}/health_data/{dateKey}
    await _firestore
        .collection('patients')
        .doc(user.uid)
        .collection('health_data')
        .doc(dateKey)
        .set(healthData, SetOptions(merge: true));
  }

  // Get today's health data
  Future<Map<String, dynamic>?> getTodayHealthData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'No user logged in';
    }

    final dateKey = _getTodayKey();
    final doc = await _firestore
        .collection('patients')
        .doc(user.uid)
        .collection('health_data')
        .doc(dateKey)
        .get();

    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  // Get health data for a specific date
  Future<Map<String, dynamic>?> getHealthDataForDate(String dateKey) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'No user logged in';
    }

    final doc = await _firestore
        .collection('patients')
        .doc(user.uid)
        .collection('health_data')
        .doc(dateKey)
        .get();

    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  // Get health data for a date range
  Future<List<Map<String, dynamic>>> getHealthDataRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'No user logged in';
    }

    final querySnapshot = await _firestore
        .collection('patients')
        .doc(user.uid)
        .collection('health_data')
        .where('date', isGreaterThanOrEqualTo: _formatDate(startDate))
        .where('date', isLessThanOrEqualTo: _formatDate(endDate))
        .orderBy('date', descending: false)
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
