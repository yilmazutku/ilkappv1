import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:untitled/commons/userclass.dart';


import '../managers/meal_state_and_upload_manager.dart';
//TODO bu class sadece meal state için var, bunu generalize edilebilşir hale getirmek gerekebilir ileride.
// class CustomCheckbox extends StatefulWidget {
//   const CustomCheckbox({super.key, required this.meal});
//
//   final Meals meal;
//
//   @override
//   createState() => _CustomCheckboxState();
// }

// class _CustomCheckboxState extends State<CustomCheckbox> {
//   @override
//   Widget build(BuildContext context) {
//     bool? check;
//     final mealStateManager = Provider.of<MealStateManager>(context);
//     bool isChecked = mealStateManager.checkedStates[widget.meal] ?? false;
//
//     return Checkbox(
//       value: check ?? isChecked,
//       onChanged: (bool? newValue) {
//         mealStateManager.setMealCheckedState(widget.meal, newValue ?? false);
//         setState(() {
//           check = newValue ?? false;
//         });
//       },
//     );
//   }
// }

// class CustomCheckbox extends StatelessWidget {
//   const CustomCheckbox({super.key, required this.meal});
//
//   final Meals meal;
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<MealStateManager>(
//       builder: (context, mealStateManager, child) {
//         bool isChecked = mealStateManager.checkedStates[meal] ?? false;
//         return Checkbox(
//           value: isChecked,
//           onChanged: (bool? newValue) {
//             mealStateManager.setMealCheckedState(meal, newValue ?? false);
//           },
//         );
//       },
//     );
//   }
// }

class CustomCheckbox extends StatefulWidget {
  const CustomCheckbox({super.key, required this.meal});

  final Meals meal;

  @override
  createState() => _CustomCheckboxState();
}

class _CustomCheckboxState extends State<CustomCheckbox> {
  @override
  Widget build(BuildContext context) {
    bool? check;
    final mealStateManager = Provider.of<MealStateManager>(context);
    bool isChecked = mealStateManager.checkedStates[widget.meal] ?? false;

    return Checkbox(
      value: check ?? isChecked,
      onChanged: (bool? newValue) {
        mealStateManager.setMealCheckedState(widget.meal, newValue ?? false);
        setState(() {
          check = newValue ?? false;
        });
      },
    );
  }
}