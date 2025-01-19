import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/diet_model.dart';
import '../models/logger.dart';

class DietProvider extends ChangeNotifier {
  final Logger logger = Logger.forClass(DietProvider);


  Future<List<DietDocument>> fetchDiets({required String userId,required bool showAllData}) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('dietlists')
          .orderBy('uploadTime', descending: true);

      // If you have a subscription filter, apply it here if (!showAllData) { ... }

      final snapshot = await query.get();
      final diets = snapshot.docs
          .map((doc) => DietDocument.fromSnapshot(doc))
          .toList();
      logger.info('Fetched ${diets.length} diets for user $userId');
      return diets;
    } catch (e, s) {
      logger.err('Error fetching diets: $e', [s]);
      return [];
    }
  }

  Future<void> deleteDiet({required String userId,required String docId}) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('dietlists')
        .doc(docId)
        .delete();
    logger.info('Deleted diet document: $docId');
  }

}