// providers/meal_state_and_upload_manager.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/meal_model.dart';
import '../commons/logger.dart';
import '../tabs/basetab.dart';

final Logger logger = Logger.forClass(MealStateManager);

class MealStateManager extends ChangeNotifier with Loadable {
  List<MealModel> _meals = [];
  bool _isLoading = false;
  bool _showAllImages = false;

  String? _userId;
  String? _selectedSubscriptionId;

  Map<Meals, bool> checkedStates = {
    for (var meal in Meals.values) meal: false,
  };

  List<MealModel> get meals => _meals;
  @override
  bool get isLoading => _isLoading;
  bool get showAllImages => _showAllImages;

  MealStateManager();

  void setUserId(String userId) {
    _userId = userId;
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

  void setMealCheckedState(Meals meal, bool isChecked) {
    checkedStates[meal] = isChecked;
    notifyListeners();
  }

  Future<void> fetchMeals() async {
    _isLoading = true;
    // notifyListeners();

    try {
      final userId = _userId;

      if (userId == null) {
        logger.err('User ID not set.');
        return;
      }

      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('meals')
          .orderBy('timestamp', descending: true);

      if (!_showAllImages && _selectedSubscriptionId != null) {
        query = query.where('subscriptionId', isEqualTo: _selectedSubscriptionId);
      }

      final snapshot = await query.get();

      _meals = snapshot.docs.map((doc) {
        final meal = MealModel.fromDocument(doc);
        // Update checkedStates based on meals fetched
        checkedStates[meal.mealType] = true;
        return meal;
      }).toList();
    } catch (e) {
      logger.err('Error fetching meals: {}', [e]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
