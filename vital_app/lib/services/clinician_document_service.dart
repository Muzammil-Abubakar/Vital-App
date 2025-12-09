import 'package:cloud_firestore/cloud_firestore.dart';

class ClinicianDocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Store clinician documents during signup
  Future<void> addDocuments({
    required String clinicianId,
    required List<String> documentNames,
  }) async {

    // Store in clinicians/{clinicianId}/documents/{documentId}
    final batch = _firestore.batch();
    for (final docName in documentNames) {
      final docRef = _firestore
          .collection('clinicians')
          .doc(clinicianId)
          .collection('documents')
          .doc();
      batch.set(docRef, {
        'name': docName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // Get all documents for a clinician
  Future<List<Map<String, dynamic>>> getDocuments(String clinicianId) async {
    final querySnapshot = await _firestore
        .collection('clinicians')
        .doc(clinicianId)
        .collection('documents')
        .orderBy('createdAt', descending: false)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? '',
        'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
      };
    }).toList();
  }

  // Get all unverified clinicians
  Stream<List<Map<String, dynamic>>> getUnverifiedCliniciansStream() {
    return _firestore
        .collection('clinicians')
        .where('verified', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final clinicians = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'email': data['email'] ?? '',
          'age': data['age'] ?? 0,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'verified': data['verified'] ?? false,
        };
      }).toList();
      
      // Sort by createdAt descending (newest first) on client side
      clinicians.sort((a, b) {
        final aDate = a['createdAt'] as DateTime?;
        final bDate = b['createdAt'] as DateTime?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
      
      return clinicians;
    });
  }

  // Verify a clinician
  Future<void> verifyClinician(String clinicianId) async {
    await _firestore
        .collection('clinicians')
        .doc(clinicianId)
        .update({
      'verified': true,
      'verifiedAt': FieldValue.serverTimestamp(),
    });
  }
}

