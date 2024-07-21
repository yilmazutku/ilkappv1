import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../commons/common.dart';
import '../commons/customcheckbox.dart';
import '../managers/image_manager.dart';
import '../managers/meal_state_manager.dart';

class MealUploadPage extends StatelessWidget {
  const MealUploadPage({super.key});

  void setMealList() {
    //TODO: Yazılan diyet ile widget list guncellenecek. Input nereden girilecek? constta keyler girilebilir ama girilemdigi durumda fluter napıo?
  }

  @override
  Widget build(BuildContext context) {
    print('building mealuploadpage');
    final imageManager = Provider.of<ImageManager>(context);
    final mealStateManager = Provider.of<MealStateManager>(context);
    XFile? image;
    ImagePicker picker = ImagePicker();
    Map<Meals, List<String>> mealContents = {
      //TODO kısıden kısıye ogunler deısıo hepsını koymamalıyız default olarak
    };
    Map<Meals, bool> checkedStates = {
      for (var meal in Meals.values) meal: false,
    };
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
          checkedStates.addAll(snapshot.data!);
          return ListView(
            children: checkedStates.keys.map((mealCategory) {
              List<Text> list = [];
              if (mealContents[mealCategory] != null &&
                  mealContents[mealCategory]!.isNotEmpty) {
                list = mealContents[mealCategory]!
                    .map((content) => Text('• $content'))
                    .toList();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children:
                [
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
                                  image = await picker.pickImage(
                                      source: ImageSource.gallery),
                                  imageManager.uploadFile(image,
                                      meal: mealCategory),
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


