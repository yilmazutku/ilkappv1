import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../commons/common.dart';
import '../commons/logger.dart';

final Logger logger = Logger.forClass(MealStateManager);

class MealStateManager extends ChangeNotifier {
  final Map<Meals, bool> _checkedStates = {
    for (var meal in Meals.values) meal: false,
  };
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _userId;

  Map<Meals, bool> get checkedStates => _checkedStates;

  MealStateManager() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      _loadMealStates();
    } else {
      logger.err('User not authenticated.');
    }
  }

  void setMealCheckedState(Meals meal, bool isChecked) async {
    _checkedStates[meal] = isChecked;
    notifyListeners();

    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('mealStates')
        .doc(date)
        .set({
      meal.name: isChecked,
    }, SetOptions(merge: true));
  }

  void _loadMealStates() async {
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('mealStates')
        .doc(date)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      for (var meal in Meals.values) {
        _checkedStates[meal] = data[meal.name] ?? false;
      }
    } else {
      // Initialize meal states for the day
      for (var meal in Meals.values) {
        _checkedStates[meal] = false;
      }
    }
    notifyListeners();
  }
}
