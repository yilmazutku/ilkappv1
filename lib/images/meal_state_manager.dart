import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../commons/common.dart';

class MealStateManager extends ChangeNotifier {
  final Map<Meals, bool> _checkedStates = {
    for (var meal in Meals.values) meal: false,
  };

  Map<Meals, bool> get checkedStates => _checkedStates;

  void setMealCheckedState(Meals meal, bool isChecked) async {
    _checkedStates[meal] = isChecked;
    notifyListeners(); // Notify listeners to rebuild the widgets that depend on this state

    // Save the state to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(meal.label, isChecked);
    await prefs.setInt(Constants.saveTime, DateTime.now().millisecondsSinceEpoch);
  }

// Add other methods as needed, such as initializing states from SharedPreferences
}
