import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../commons/common.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'meal_state_manager.dart';

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

  Future<Map<Meals, bool>> initMealStates() async {
    await resetMealStatesIfDifferentDay();
    final Map<Meals, bool> loadedStates = {};
    for (var meal in Meals.values) {
      bool isChecked = prefs.getBool(meal.label) ?? false;
      loadedStates[meal] = isChecked;
    }
    return loadedStates;
  }

  Future<void> saveMealCheckedState(Meals meal, bool isChecked) async {
    await prefs.setBool(meal.label, isChecked);
    await prefs.setInt(
        Constants.saveTime, DateTime.now().millisecondsSinceEpoch);
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

  Future<void> uploadFile(Meals meal) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      try {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        String fileName = image.path.split('/').last;
        String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
        var path = '${Constants.urlUsers}$userId/$date/${meal.url}$fileName';
        Reference ref = FirebaseStorage.instance.ref(path);
        print('uploadFile path=$path');
        await ref.putFile(File(image.path));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image uploaded for $meal')),
        );
      } on FirebaseException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Error during file upload')),
        );
      }
    }
  }

  void setMealList() {
    //TODO: Yazılan diyet ile widget list guncellenecek. Input nereden girilecek? constta keyler girilebilir ama girilemdigi durumda fluter napıo?
    // mealContents[Meals.br] = ['egg'];
    // mealContents[Meals.lunch] = ['Soup', 'Chicken', 'Rice'];
    // setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Use FutureBuilder to handle the asynchronous loading of meal checkbox states
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Image Upload'),
      ),
      body: FutureBuilder<Map<Meals, bool>>(
        future: initMealStates(),
        // Call the method that initializes checkbox states
        builder: (context, snapshot) {
          // Check the state of the snapshot
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Data is still loading, show a progress indicator
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // If there's an error loading the data, show an error message
            return const Center(child: Text("Error loading meal states"));
          }
          // First, update the local checkbox states map with the data from the snapshot
          _checkedStates.addAll(snapshot.data!);

          // Now build the UI as usual, but using the updated _checkedStates
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
                          onPressed: () => uploadFile(mealCategory),
                        ),
                        // Checkbox widget integrated with loaded state
                        CustomCheckbox(
                          meal: mealCategory,
                          // initialValue: _checkedStates[mealCategory] ?? false,
                          // onStateChanged: (bool newValue) {
                          //   // Update the parent widget's state or perform other actions here
                          //   saveMealCheckedState(mealCategory, newValue);
                          // },
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
