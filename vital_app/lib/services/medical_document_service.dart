import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MedicalDocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Store a medical document
  Future<void> addDocument({
    required String name,
    required DateTime date,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'No user logged in';
    }

    final documentData = <String, dynamic>{
      'name': name,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Store in patients/{userId}/medical_documents/{documentId}
    await _firestore
        .collection('patients')
        .doc(user.uid)
        .collection('medical_documents')
        .add(documentData);
  }

  // Get all medical documents for the current patient
  Stream<List<Map<String, dynamic>>> getDocumentsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'No user logged in';
    }

    return _firestore
        .collection('patients')
        .doc(user.uid)
        .collection('medical_documents')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'date': (data['date'] as Timestamp?)?.toDate(),
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
        };
      }).toList();
    });
  }

  // Get all medical documents (one-time fetch)
  Future<List<Map<String, dynamic>>> getDocuments() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'No user logged in';
    }

    final querySnapshot = await _firestore
        .collection('patients')
        .doc(user.uid)
        .collection('medical_documents')
        .orderBy('date', descending: true)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? '',
        'date': (data['date'] as Timestamp?)?.toDate(),
        'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
      };
    }).toList();
  }

  // Delete a medical document
  Future<void> deleteDocument(String documentId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'No user logged in';
    }

    await _firestore
        .collection('patients')
        .doc(user.uid)
        .collection('medical_documents')
        .doc(documentId)
        .delete();
  }
}

