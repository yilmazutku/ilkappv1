// providers/meal_state_and_upload_manager.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/meal_model.dart';
import '../models/logger.dart';

final Logger logger = Logger.forClass(MealStateManager);

class MealStateManager extends ChangeNotifier {

  Future<List<MealModel>> fetchMeals(String? selectedSubscriptionId,{required String userId,required bool showAllImages}) async {
    try {

      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('meals')
          .orderBy('timestamp', descending: true);

      if (!showAllImages && selectedSubscriptionId != null) {
        query = query.where('subscriptionId', isEqualTo: selectedSubscriptionId);
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
