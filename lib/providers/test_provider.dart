import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/logger.dart';
import '../models/test_model.dart';

final Logger logger = Logger.forClass(TestProvider);

class TestProvider extends ChangeNotifier {
  String? _userId;

  void setUserId(String userId) {
    _userId = userId;
  }

  Future<List<TestModel>> fetchTests() async {
    if (_userId == null) {
      logger.err('User ID not set.');
      return [];
    }

    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('tests')
          .orderBy('testDate', descending: true);

      final snapshot = await query.get();

      List<TestModel> tests =
          snapshot.docs.map((doc) => TestModel.fromDocument(doc)).toList();

      return tests;
    } catch (e) {
      logger.err('Error fetching tests for user with userId={}. {}',
          [_userId!, e.toString()]);
      return [];
    }
  }

// Other methods like addTest, updateTest can be added here if needed
}
