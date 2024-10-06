import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../commons/common.dart';
import '../commons/customcheckbox.dart';
import '../commons/logger.dart';
import '../managers/image_manager.dart';
import '../managers/meal_state_and_upload_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  Map<Meals, List<String>> mealContents = {};
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initMealStates();
    _fetchUserMealList(); // Fetch user meal list from Firestore
  }

  Future<void> _initMealStates() async {
    final mealStateManager =
    Provider.of<MealStateManager>(context, listen: false);
    final states = await mealStateManager.initMealStates();
    setState(() {
      checkedStates.addAll(states);
    });
  }

  Future<void> _fetchUserMealList() async {
    try {
      // Replace 'userId' with the actual user ID or fetch it dynamically if needed
      const userId = 'your_user_id'; // Example: get the current user's ID
      final DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('userinfo')
          .doc(userId)
          .collection('dietlists')
          .doc('currentDiet') // Replace with actual diet document ID if needed
          .get();

      if (documentSnapshot.exists) {
        final data = documentSnapshot.data() as Map<String, dynamic>;

        setState(() {
          mealContents = data.map((key, value) {
            return MapEntry(Meals.values.firstWhere((meal) => meal.label == key),
                List<String>.from(value));
          });
        });

        logger.info('Fetched meal list: {}', [mealContents]);
      } else {
        logger.warn('No diet list found for the user.');
      }
    } catch (e) {
      logger.err('Error fetching meal list: {}', [e.toString()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.info('building MealUploadPage');
    final imageManager = Provider.of<ImageManager>(context);
    XFile? image;
    ImagePicker picker = ImagePicker();

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        mealCategory.label,
                        textAlign: TextAlign.left,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          MaterialLocalizations.of(context).formatTimeOfDay(
                              mealTimes[mealCategory] ?? defaultMealTime),
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
