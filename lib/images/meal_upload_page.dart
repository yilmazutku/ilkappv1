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
  final ImagePicker _picker = ImagePicker();
  final Map<Meals, XFile?> _mealImages = {
    for (var meal in Meals.values) meal: null,
    //ya da   for( var meal in  Meals.values) {
    //       _mealImages[meal.label]=null;
    //     } loopunu alıp initState methodunu override edip onun icine koyacaksın. ikisi de aynı.
  };

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
      print('$path');
      await ref.putFile(file);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image uploaded for $meal')),
      );
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error during file upload')),
      );
    }
  }

  void setMealList() {
    //TODO: Yazılan diyet ile widget list guncellenecek.
  }

  @override
  Widget build(BuildContext context) {
    // Define meal contents for each category
    final Map<Meals, List<String>> mealContents = {
      Meals.br: ['Egg', 'Tomatoes', 'Bread'],
      Meals.lunch: ['Soup', 'Chicken', 'Rice'],
      Meals.dinner: ['Salad', 'Steak', 'Potatoes'],
      Meals.firstmid: ['Egg1', 'Tomatoes1', 'Bread1'],
      Meals.secondmid: ['Soup2', 'Chicken2', 'Rice2'],
      Meals.thirdmid: ['Salad3', 'Steak3', 'Potatoes3'],
    };
    return Scaffold(
      appBar: AppBar(
        title: Text('Meal Image Upload'),
      ),
      body: ListView(
        children: _mealImages.keys.map((mealCategory) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ListTile(
                // title: Text(mealCategory),
                title: Center(
                  // Center the title text. center ıle bole yapınca textı ortalıyor
                  child: Text(
                    mealCategory.label,
                    textAlign:
                        TextAlign.center, // Add this line to center align text
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: () => pickAndUploadImage(mealCategory),
                ),
                // leading: _mealImages[mealCategory] != null
                //     ? Image.file(
                //   File(_mealImages[mealCategory]!.path),
                //   width: 100,
                //   height: 100,
                //   fit: BoxFit.cover,
                // )
                //     : Container(width: 100, height: 100),
              ),
              // This Padding widget is new, it wraps the meal contents
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // This maps the meal contents to a list of Text widgets
                  children: mealContents[mealCategory]!
                      .map((content) => Text('• $content'))
                      .toList(),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

// bunun meal içeriği eklenmiş hali yukarıdaki build methodu.
// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: AppBar(
//       title: Text('Meal Image Upload'),
//     ),
//     body: ListView(
//       children: _mealImages.keys.map((mealCategory) {
//         return ListTile(
//           title: Text(mealCategory),
//           trailing: IconButton(
//             icon: Icon(Icons.camera_alt),
//             onPressed: () => pickAndUploadImage(mealCategory),
//           ),
//           leading: _mealImages[mealCategory] != null
//               ? Image.file(
//             File(_mealImages[mealCategory]!.path),
//             width: 100,
//             height: 100,
//             fit: BoxFit.cover,
//           )
//               : Container(width: 100, height: 100),
//         );
//       }).toList(),
//     ),
//   );
// }
}
