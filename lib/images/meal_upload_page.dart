import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../commons/common.dart';

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
@override
  initState () {
  super.initState();
  // mealContents [Meals.br] = ['egg'];
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
    // Define meal contents for each category
    // final Map<Meals, List<String>> mealContents = {
    //   Meals.br: ['Egg', 'Tomatoes', 'Bread'],
    //   Meals.lunch: ['Soup', 'Chicken', 'Rice'],
    //   Meals.dinner: ['Salad', 'Steak', 'Potatoes'],
    //   Meals.firstmid: ['Egg1', 'Tomatoes1', 'Bread1'],
    //   Meals.secondmid: ['Soup2', 'Chicken2', 'Rice2'],
    //   Meals.thirdmid: ['Salad3', 'Steak3', 'Potatoes3'],
    // };
    return Scaffold(
      appBar: AppBar(
        title: Text('Meal Image Upload'),
      ),
      body: ListView(
        children: _mealImages.keys.map((mealCategory) {
          List<Text> list =[];
          if(mealContents[mealCategory]!=null && mealContents[mealCategory]!.isNotEmpty) {
            list = mealContents[mealCategory]!
                      .map((content) => Text('• $content'))
                      .toList();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ListTile(
                title: Center(
                  // Center the title text. center ıle bole yapınca textı ortalıyor
                  child: Text(
                    mealCategory.label,
                    textAlign: TextAlign.center, // Add this line to center align text
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () => pickAndUploadImage(mealCategory),
                ),
              ),
              // This Padding widget is new, it wraps the meal contents
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // This maps the meal contents to a list of Text widgets
                  children:
                  list ,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
