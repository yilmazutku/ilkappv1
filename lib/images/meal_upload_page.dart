import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../commons/common.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MealUploadPage extends StatefulWidget {
  const MealUploadPage({Key? key}) : super(key: key);

  @override
  _MealUploadPageState createState() => _MealUploadPageState();
}

class _MealUploadPageState extends State<MealUploadPage> {
  _MealUploadPageState(); //initstate hep cagiriliyor ama constructor olai nasil olur? listten baslayarak bunu denemeye basladim TODO
  final ImagePicker _picker = ImagePicker();
  final Map<Meals, List<String>> mealContents = {
    // Meals.br: ['Egg', 'Tomatoes', 'Bread'],
    // Meals.lunch: ['Soup', 'Chicken', 'Rice'],
    // Meals.dinner: ['Salad', 'Steak', 'Potatoes'],
    // Meals.firstmid: ['Egg1', 'Tomatoes1', 'Bread1'],
    // Meals.secondmid: ['Soup2', 'Chicken2', 'Rice2'],
    // Meals.thirdmid: ['Salad3', 'Steak3', 'Potatoes3'],
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
  static const String saveTime = 'saveTime';

  @override
  initState() {
    super.initState();
  }

  Future<Map<Meals, bool>> initMealStates() async {
    await resetMealStatesIfDifferentDay();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<Meals, bool> loadedStates = {};
    for (var meal in Meals.values) {
      bool isChecked = prefs.getBool(meal.label) ?? false;
      loadedStates[meal] = isChecked;
    }

    return loadedStates;
  }

  Future<void> saveMealCheckedState(Meals meal, bool isChecked) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(meal.label, isChecked);
    await prefs.setInt(saveTime, DateTime.now().millisecondsSinceEpoch);
    await resetMealStatesIfDifferentDay();
  }

  Future<void> resetMealStatesIfDifferentDay() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lastSaveTime = prefs.getInt(saveTime);
    DateTime lastSaveDateTime =
        DateTime.fromMillisecondsSinceEpoch(lastSaveTime!);
    var now = DateTime.now();
    bool isDifferentDay = lastSaveDateTime.day != now.day || lastSaveDateTime.month!=now.month || lastSaveDateTime.year!=now.year;
    if (isDifferentDay) {
      for (var meal in Meals.values) {
        prefs.setBool(meal.label, false);
        // loadedStates[meal] = isChecked;
      }
    }
  }

  Future<bool> loadMealCheckedState(Meals meal) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(meal.label) ?? false; // Returns false if not set
  }

  Future<void> pickAndUploadImage(Meals meal) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _mealImages[meal] = image;
      });
      await uploadFile(meal, File(image.path));
    }
  }

  Future<void> uploadFile(Meals meal, File file) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      String fileName = file.path.split('/').last;

      String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      var path = '${Constants.urlUsers}$userId/$date/${meal.url}$fileName';
      Reference ref = FirebaseStorage.instance.ref(path);
      print('uploadFile path=$path');
      await ref.putFile(file);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image uploaded for $meal')),
      );
      setMealList();
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error during file upload')),
      );
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

          // Data is loaded, proceed to build the UI with the loaded checkbox states
          // First, update the local checkbox states map with the data from the snapshot
          _checkedStates.addAll(snapshot.data!);

          // Now build the UI as usual, but using the updated _checkedStates
          return ListView(
            children: _mealImages.keys.map((mealCategory) {
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
                          onPressed: () => pickAndUploadImage(mealCategory),
                        ),
                        // Checkbox widget integrated with loaded state
                        CustomCheckbox(
                          meal: mealCategory,
                          initialValue: _checkedStates[mealCategory] ?? false,
                          onStateChanged: (bool newValue) {
                            // Update the parent widget's state or perform other actions here
                            saveMealCheckedState(mealCategory, newValue);
                            // If you need to update something in the current state as well,
                            // remember to call setState here if necessary
                          },
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

class CustomCheckbox extends StatefulWidget {
  final Meals meal;
  final bool initialValue;
  final Function(bool) onStateChanged; // Add this line

  const CustomCheckbox({
    super.key,
    required this.meal,
    required this.initialValue,
    required this.onStateChanged, // Add this line
  });

  @override
  _CustomCheckboxState createState() => _CustomCheckboxState();
}

class _CustomCheckboxState extends State<CustomCheckbox> {
  late bool isChecked;

  @override
  void initState() {
    super.initState();
    isChecked = widget.initialValue;
  }

  void _toggleCheckbox(bool newValue) {
    setState(() {
      isChecked = !isChecked;
    });
    widget.onStateChanged(newValue); // Invoke the callback with the new state
    // Here, save the new state to SharedPreferences or any other persistent storage
  }

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: isChecked,
      onChanged: (bool? newValue) {
        _toggleCheckbox(newValue ?? false);
        // Optionally, perform additional actions such as saving the state
      },
    );
  }
}
