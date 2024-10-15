// managers/meal_state_and_upload_manager.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../commons/logger.dart';
import '../commons/userclass.dart';
import '../tabs/basetab.dart';

final Logger logger = Logger.forClass(MealStateManager);

class MealStateManager extends ChangeNotifier with Loadable {
  List<MealModel> _meals = [];
  bool _isLoading = false;
  bool _showAllImages = false;

  String? _selectedSubscriptionId;

  List<MealModel> get meals => _meals;
  @override
  bool get isLoading => _isLoading;
  bool get showAllImages => _showAllImages;

  MealStateManager() {
    fetchMeals();
  }

  void setSelectedSubscriptionId(String? subscriptionId) {
    _selectedSubscriptionId = subscriptionId;
    fetchMeals();
  }

  void setShowAllImages(bool value) {
    if (_showAllImages != value) {
      _showAllImages = value;
      fetchMeals();
    }
  }

  Future<void> fetchMeals() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        logger.err('User not authenticated.');
        return;
      }
      final userId = user.uid;

      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('meals')
          .orderBy('timestamp', descending: true);

      if (!_showAllImages && _selectedSubscriptionId != null) {
        query = query.where('subscriptionId', isEqualTo: _selectedSubscriptionId);
      }

      final snapshot = await query.get();

      _meals = snapshot.docs
          .map((doc) => MealModel.fromDocument(doc))
          .toList();

    } catch (e) {
      logger.err('Error fetching meals: {}', [e]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
