// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';
//
// import '../commons/common.dart';
// import '../commons/customcheckbox.dart';
// import '../commons/logger.dart';
// import '../managers/image_manager.dart';
// import '../managers/meal_state_and_upload_manager.dart';
// final Logger logger = Logger.forClass(MealUploadPage);
// class MealUploadPage extends StatelessWidget {
//   const MealUploadPage({super.key});
//
//   void setMealList() {
//     //TODO: Yazılan diyet ile widget list guncellenecek. Input nereden girilecek? constta keyler girilebilir ama girilemdigi durumda fluter napıo?
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     logger.info('building MealUploadPage');
//     final imageManager = Provider.of<ImageManager>(context);
//     final mealStateManager = Provider.of<MealStateManager>(context);
//     XFile? image;
//     ImagePicker picker = ImagePicker();
//     Map<Meals, List<String>> mealContents = {
//       //TODO kısıden kısıye ogunler deısıo hepsını koymamalıyız default olarak
//     };
//     Map<Meals, bool> checkedStates = {
//       for (var meal in Meals.values) meal: false,
//     };
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Meal Image Upload'),
//       ),
//       body: FutureBuilder<Map<Meals, bool>>(
//         future: mealStateManager.initMealStates(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return const Center(child: Text("Error loading meal states"));
//           }
//           if (snapshot.hasData) {
//             checkedStates.addAll(snapshot.data!);
//           }
//           //checkedStates.addAll(snapshot.data!); //BURAYI NEDEN DEGISTIRI CHATGPT?=
//           return ListView(
//             children: checkedStates.keys.map((mealCategory) {
//               List<Text> list = [];
//               if (mealContents[mealCategory] != null &&
//                   mealContents[mealCategory]!.isNotEmpty) {
//                 list = mealContents[mealCategory]!
//                     .map((content) => Text('• $content'))
//                     .toList();
//               }
//
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children:   [
//                   ListTile(
//                     title: Center(
//                       child: Text(
//                         mealCategory.label,
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                     trailing: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         IconButton(
//                             icon: const Icon(Icons.camera_alt),
//                             onPressed: () async  {
//                                   image = await picker.pickImage(
//                                       source: ImageSource.gallery,);
//                                   final result = await imageManager.uploadFile(image, meal: mealCategory);
//                                   if (result.errorMessage != null) {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       SnackBar(content: Text(result.errorMessage!)),
//                                     );
//                                   } else {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       const SnackBar(content: Text('Fotoğraf başarıyla yüklendi.')),
//                                     );
//                                   }
//                             },
//                         ),
//                         CustomCheckbox(
//                           meal: mealCategory,
//                         ),
//                       ],
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(left: 16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: list,
//                     ),
//                   ),
//                 ],
//               );
//             }).toList(),
//           );
//         },
//       ),
//     );
//   }
// }
//
//
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../commons/common.dart';
import '../commons/customcheckbox.dart';
import '../commons/logger.dart';
import '../managers/image_manager.dart';
import '../managers/meal_state_and_upload_manager.dart';

final Logger logger = Logger.forClass(MealUploadPage);

class MealUploadPage extends StatefulWidget {
  const MealUploadPage({super.key});

  @override
  State<MealUploadPage> createState() => _MealUploadPageState();
}

class _MealUploadPageState extends State<MealUploadPage> {
  Map<Meals, bool> checkedStates = {
    for (var meal in Meals.values) meal: false,
  };
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initMealStates();
  }

  Future<void> _initMealStates() async {
    final mealStateManager =
        Provider.of<MealStateManager>(context, listen: false);
    final states = await mealStateManager.initMealStates();
    setState(() {
      checkedStates.addAll(states);
    });
  }

  void setMealList() {
    //TODO: Yazılan diyet ile widget list guncellenecek. Input nereden girilecek? constta keyler girilebilir ama girilemdigi durumda fluter napıo?
  }

  @override
  Widget build(BuildContext context) {
    logger.info('building MealUploadPage');
    final imageManager = Provider.of<ImageManager>(context);
    final mealStateManager = Provider.of<MealStateManager>(context);
    XFile? image;
    ImagePicker picker = ImagePicker();
    Map<Meals, List<String>> mealContents = {
      Meals.br: ['Eggs', 'Toast', 'Orange Juice'],
      Meals.firstmid: ['Yogurt', 'Fruit', 'Nuts'],
      Meals.lunch: ['Grilled Chicken', 'Salad', 'Rice'],
      Meals.secondmid: ['Yogurt oglen', 'Fruit', 'Nuts'],

      Meals.dinner: ['Steak', 'Mashed Potatoes', 'Green Beans'],
      Meals.thirdmid: ['Yogurt gece', 'Fruit', 'Nuts']
    };
    Map<Meals, TimeOfDay> mealTimes = {
      Meals.br: const TimeOfDay(hour: 8, minute: 30),
      Meals.firstmid: const TimeOfDay(hour: 10, minute: 30),
      Meals.lunch: const TimeOfDay(hour: 12, minute: 30),
      Meals.secondmid: const TimeOfDay(hour: 15, minute: 30),
      Meals.dinner: const TimeOfDay(hour: 18, minute: 30),
      Meals.thirdmid: const TimeOfDay(hour: 21, minute: 30)
    };
    const defaultMealTime = TimeOfDay(hour: 0, minute: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Image Upload'),
      ),
      body: Stack(
          children: [
      ListView(
      children: checkedStates.keys.map((mealCategory) {
          List<Text> list = [];
          if (mealContents[mealCategory] != null &&
              mealContents[mealCategory]!.isNotEmpty) {
            list = mealContents[mealCategory]!
                .map((content) => Text('• $content'))
                .toList();
          }


          return Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Change this line

            children: [
              ListTile(
                title: Align(
                  alignment: Alignment.centerLeft,  // Align the text to the left
                child: Text(
                    mealCategory.label,
                    textAlign: TextAlign.left,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                   MaterialLocalizations.of(context).formatTimeOfDay(mealTimes[mealCategory]??defaultMealTime),
                      textAlign: TextAlign.left,
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: () async {
                        image = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          setState(() {
                            _isUploading = true;
                          });
                          final result = await imageManager.uploadFile(image,
                              meal: mealCategory);

                          if (context.mounted) {
                            setState(() {
                              _isUploading = false;
                            });

                            if (result.isUploadOk) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Fotoğraf başarıyla yüklendi.')),
                              );
                            } else if (result.errorMessage != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result.errorMessage!)),
                              );
                            }
                          }
                        }
                      },
                    ),
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
      ),
            if (_isUploading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
      ),
    );
  }
}
