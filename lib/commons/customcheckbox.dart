// commons/customcheckbox.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal_model.dart';
import '../providers/meal_state_and_upload_manager.dart';

class CustomCheckbox extends StatefulWidget {
  const CustomCheckbox({super.key, required this.meal});

  final Meals meal;

  @override
   createState() => _CustomCheckboxState();
}

class _CustomCheckboxState extends State<CustomCheckbox> {
  @override
  Widget build(BuildContext context) {
    final mealStateManager = Provider.of<MealStateManager>(context);
    bool isChecked = mealStateManager.checkedStates[widget.meal] ?? false;

    return Checkbox(
      value: isChecked,
      onChanged: (bool? newValue) {
        mealStateManager.setMealCheckedState(widget.meal, newValue ?? false);
        setState(() {});
      },
    );
  }
}
