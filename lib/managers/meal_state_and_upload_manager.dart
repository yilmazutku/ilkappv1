import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../commons/common.dart';
import '../commons/logger.dart';
final Logger logger = Logger.forClass(MealStateManager);
class MealStateManager extends ChangeNotifier {
  final Map<Meals, bool> _checkedStates = {
    for (var meal in Meals.values) meal: false,
  };
  SharedPreferences? prefs; // Make prefs nullable to check if initialized
  Map<Meals, bool> get checkedStates => _checkedStates;

  MealStateManager() {
    initPrefs();
  }

  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    await resetMealStatesIfDifferentDay();
    _loadMealStates();
  //  notifyListeners();
  }

  void setMealCheckedState(Meals meal, bool isChecked) async {
    _checkedStates[meal] = isChecked;
    //notifyListeners(); // Notify listeners to rebuild the widgets that depend on this state
    // Save the state to SharedPreferences
    await prefs?.setBool(meal.label, isChecked);
   bool? isSuccessfullySet= await prefs?.setInt(
        Constants.saveTime, DateTime.now().millisecondsSinceEpoch);
    logger.info('isSuccessfullySet={} for meal={}, isChecked={}', [ isSuccessfullySet! ,meal, isChecked]);
  }

  void _loadMealStates() {
    for (var meal in Meals.values) {
      bool? boolMeal = prefs?.getBool(meal.label);
      bool isChecked = boolMeal ?? false;
      _checkedStates[meal] = isChecked;
    }
  }

  Future<Map<Meals, bool>> initMealStates() async {
    await resetMealStatesIfDifferentDay();
    final Map<Meals, bool> loadedStates = {};
    for (var meal in Meals.values) {
      bool? boolMeal = prefs?.getBool(meal.label);
      bool isChecked = boolMeal ?? false;
      loadedStates[meal] = isChecked;
    }
    return loadedStates;
  }

  Future<void> resetMealStatesIfDifferentDay() async {
    int? lastSaveTime = prefs?.getInt(Constants.saveTime);
    if (lastSaveTime == null) {
      setMealsFalse();
      return;
    }
    DateTime lastSaveDateTime =
        DateTime.fromMillisecondsSinceEpoch(lastSaveTime);
    var now = DateTime.now();
    bool isDifferentDay = lastSaveDateTime.day != now.day ||
        lastSaveDateTime.month != now.month ||
        lastSaveDateTime.year != now.year;
    if (isDifferentDay) {
      setMealsFalse();
    }
  }

  void setMealsFalse() {
    for (var meal in Meals.values) {
      prefs?.setBool(meal.label, false);
      _checkedStates[meal] = false;
    }
    //notifyListeners();
  }
}
