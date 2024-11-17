// providers/meal_state_and_upload_manager.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/meal_model.dart';
import '../models/logger.dart';

final Logger logger = Logger.forClass(MealStateManager);

class MealStateManager extends ChangeNotifier {

  String? _userId;
  String? _selectedSubscriptionId;

  // Map<Meals, bool> checkedStates = {
  //   for (var meal in Meals.values) meal: false,
  // };

  void setUserId(String userId) {
    _userId = userId;
  }

  void setSelectedSubscriptionId(String? subscriptionId) {
    _selectedSubscriptionId = subscriptionId;
  }

  // void setMealCheckedState(Meals meal, bool isChecked) {
  //   checkedStates[meal] = isChecked;
  //   notifyListeners();
  // }

  Future<List<MealModel>> fetchMeals({required bool showAllImages}) async {
    try {
      final userId = _userId;

      if (userId == null) {
        logger.err('User ID not set.');
        return [];
      }

      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('meals')
          .orderBy('timestamp', descending: true);

      if (!showAllImages && _selectedSubscriptionId != null) {
        query = query.where('subscriptionId', isEqualTo: _selectedSubscriptionId);
      }

      final snapshot = await query.get();

      List<MealModel> meals = snapshot.docs.map((doc) {
        final meal = MealModel.fromDocument(doc);
        // Update checkedStates based on meals fetched
        //checkedStates[meal.mealType] = true;
        return meal;
      }).toList();

      return meals;
    } catch (e) {
      logger.err('Error fetching meals: {}', [e]);
      return [];
    }
  }
}
