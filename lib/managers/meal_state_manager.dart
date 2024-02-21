import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../commons/common.dart';

class MealStateManager extends ChangeNotifier {
  final Map<Meals, bool> _checkedStates = {
    for (var meal in Meals.values) meal: false,
  };
  late SharedPreferences prefs;
  Map<Meals, bool> get checkedStates => _checkedStates;

  void setMealCheckedState(Meals meal, bool isChecked) async {
    _checkedStates[meal] = isChecked;
    notifyListeners(); // Notify listeners to rebuild the widgets that depend on this state

    // Save the state to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(meal.label, isChecked);
    await prefs.setInt(Constants.saveTime, DateTime.now().millisecondsSinceEpoch);
  }
  Future<Map<Meals, bool>> initMealStates() async {
    await resetMealStatesIfDifferentDay();
    final Map<Meals, bool> loadedStates = {};
    for (var meal in Meals.values) {
      bool isChecked = prefs.getBool(meal.label) ?? false;
      loadedStates[meal] = isChecked;
    }
    return loadedStates;
  }


  Future<void> resetMealStatesIfDifferentDay() async {
    prefs = await SharedPreferences.getInstance();
    int? lastSaveTime = prefs.getInt(Constants.saveTime);
    DateTime lastSaveDateTime =
    DateTime.fromMillisecondsSinceEpoch(lastSaveTime!);
    var now = DateTime.now();
    bool isDifferentDay = lastSaveDateTime.day != now.day ||
        lastSaveDateTime.month != now.month ||
        lastSaveDateTime.year != now.year;
    if (isDifferentDay) {
      for (var meal in Meals.values) {
        prefs.setBool(meal.label, false);
        // loadedStates[meal] = isChecked;
      }
    }
  }

// Add other methods as needed, such as initializing states from SharedPreferences
}
