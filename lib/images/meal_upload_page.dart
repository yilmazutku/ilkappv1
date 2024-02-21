import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../commons/common.dart';
import '../managers/image_manager.dart';
import '../managers/meal_state_manager.dart';

class MealUploadPage extends StatefulWidget {
  const MealUploadPage({super.key});

  @override
  createState() => _MealUploadPageState();
}

class _MealUploadPageState extends State<MealUploadPage> {
  _MealUploadPageState(); //initstate hep cagiriliyor ama constructor olai nasil olur? listten baslayarak bunu denemeye basladim TODO
  final ImagePicker _picker = ImagePicker();
  final Map<Meals, List<String>> mealContents = {
    //TODO kısıden kısıye ogunler deısıo hepsını koymamalıyız default olarak
  };
  final Map<Meals, XFile?> _mealImages = {
    for (var meal in Meals.values) meal: null,
    //ya da for( var meal in  Meals.values) {
    //_mealImages[meal.label]=null;
    //} loopunu alıp initState methodunu override edip onun icine koyacaksın. ikisi de aynı.
  };
  final Map<Meals, bool> _checkedStates = {
    for (var meal in Meals.values) meal: false,
  };
  late SharedPreferences prefs;
  XFile? image;

  void setMealList() {
    //TODO: Yazılan diyet ile widget list guncellenecek. Input nereden girilecek? constta keyler girilebilir ama girilemdigi durumda fluter napıo?
  }

  @override
  Widget build(BuildContext context) {
    final imageManager = Provider.of<ImageManager>(context);
    final mealStateManager = Provider.of<MealStateManager>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Image Upload'),
      ),
      body: FutureBuilder<Map<Meals, bool>>(
        future: mealStateManager.initMealStates(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading meal states"));
          }
          _checkedStates.addAll(snapshot.data!);
          return ListView(
            children: _checkedStates.keys.map((mealCategory) {
              List<Text> list = [];
              if (mealContents[mealCategory] != null &&
                  mealContents[mealCategory]!.isNotEmpty) {
                list = mealContents[mealCategory]!
                    .map((content) => Text('• $content'))
                    .toList();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ListTile(
                    title: Center(
                      child: Text(
                        mealCategory.label,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed: () async => {
                                  image = await _picker.pickImage(
                                      source: ImageSource.gallery),
                                  imageManager.uploadFile(image, mealCategory),
                                }),
                        CustomCheckbox(
                          meal: mealCategory,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: list,
                    ),
                  ),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class CustomCheckbox extends StatelessWidget {
  const CustomCheckbox({super.key, required this.meal});

  final Meals meal;

  @override
  Widget build(BuildContext context) {
    final mealStateManager = Provider.of<MealStateManager>(context);
    bool isChecked = mealStateManager.checkedStates[meal] ?? false;

    return Checkbox(
      value: isChecked,
      onChanged: (bool? newValue) {
        mealStateManager.setMealCheckedState(meal, newValue ?? false);
      },
    );
  }
}
