// providers/test_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/test_model.dart';
import '../tabs/basetab.dart';

class TestProvider extends ChangeNotifier with Loadable{
  List<TestModel> _tests = [];
  bool _isLoading = false;
  bool _showAllTests = false;

  String? _selectedSubscriptionId;

  List<TestModel> get tests => _tests;
  @override
  bool get isLoading => _isLoading;
  bool get showAllTests => _showAllTests;

  TestProvider() {
    fetchTests();
  }

  void setSelectedSubscriptionId(String? subscriptionId) {
    _selectedSubscriptionId = subscriptionId;
    fetchTests();
  }

  void setShowAllTests(bool value) {
    if (_showAllTests != value) {
      _showAllTests = value;
      fetchTests();
    }
  }

  Future<void> fetchTests() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Handle error
        return;
      }
      final userId = user.uid;

      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tests')
          .orderBy('testDate', descending: true);

      if (!_showAllTests && _selectedSubscriptionId != null) {
        query = query.where('subscriptionId', isEqualTo: _selectedSubscriptionId);
      }

      final snapshot = await query.get();

      _tests = snapshot.docs
          .map((doc) => TestModel.fromDocument(doc))
          .toList();

    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearTests() {
    _tests = [];
    notifyListeners();
  }
}
