import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // if needed for date formatting
import '../models/logger.dart';
import '../models/meas_model.dart';
import 'dart:typed_data';

final Logger logger = Logger.forClass(MeasProvider);

class MeasProvider extends ChangeNotifier {

  // Existing method
  Future<List<MeasurementModel>> fetchMeasurements(String userId) async {
    try {
      logger.info('Ölçümler getiriliyor. userId={}', [userId]);
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('measurements')
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs.map((doc) => MeasurementModel.fromDocument(doc)).toList();
    } catch (e) {
      logger.err('fetchMeasurements hatası: {}', [e.toString()]);
      return [];
    }
  }


  Future<void> saveChanges(String userId, List<MeasurementModel> updatedList) async {
    logger.info('Starting to save measurement changes. userId={}', [userId]);

    try {
      final collectionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('measurements');

      // Step 1: Delete existing documents
      logger.info('Removing existing measurements for userId={}', [userId]);
      final snapshot = await collectionRef.get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      logger.info('Existing measurements removed for userId={}', [userId]);

      // Step 2: Add updated measurements
      logger.info('Adding updated measurements for userId={}', [userId]);
      for (var meas in updatedList) {
        await collectionRef.doc(meas.date.toIso8601String()).set(meas.toMap());
      }

      logger.info('Measurements saved successfully for userId={}', [userId]);
      notifyListeners();
    } catch (e) {
      logger.err('Failed to save measurements for userId={}: {}', [userId, e.toString()]);
    }
  }


  /// Upload a PDF to Firebase Storage and store metadata in Firestore
  Future<void> uploadTanitaPdfFile({
    required String userId,
    required String fileName,
    required List<int> fileBytes,
  }) async {
    final logger = Logger.forClass(MeasProvider);
    try {
      final now = DateTime.now();
      final storagePath = 'users/$userId/measurements/tanita_${now.millisecondsSinceEpoch}.pdf';

      // 1) Upload to Storage
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);
      final Uint8List uint8FileBytes = Uint8List.fromList(fileBytes);
      final uploadTask = await storageRef.putData(uint8FileBytes, SettableMetadata(contentType: 'application/pdf'));

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // 2) Save metadata doc in Firestore
      final docId = 'tanita_${now.millisecondsSinceEpoch}';
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('measurements')
          .doc('tanita')      // or just .doc('tanita_{someKey}') if you prefer
          .collection('pdfFiles')
          .doc(docId);

      await docRef.set({
        'pdfUrl': downloadUrl,
        'fileName': fileName,
        'uploadTime': FieldValue.serverTimestamp(),
      });

      logger.info('Tanita PDF uploaded: $docId');
    } catch (e) {
      logger.err('Error uploading Tanita PDF: {}', [e.toString()]);
      rethrow;
    }
  }

  MeasProvider();
}
