// meal_upload_page.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../commons/customcheckbox.dart';
import '../commons/logger.dart';
import '../models/meal_model.dart';
import '../providers/image_manager.dart';
import '../providers/meal_state_and_upload_manager.dart';

final Logger logger = Logger.forClass(MealUploadPage);

class MealUploadPage extends StatefulWidget {
  final String userId;
  final String subscriptionId;

  const MealUploadPage({
    super.key,
    required this.userId,
    required this.subscriptionId,
  });

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
    _fetchUserMealList();
  }

  Future<void> _initMealStates() async {
    final mealStateManager =
    Provider.of<MealStateManager>(context, listen: false);
    final states = mealStateManager.checkedStates;
    setState(() {
      checkedStates.addAll(states);
    });
  }

  Future<void> _fetchUserMealList() async {
    try {
      // Fetch the meal contents for the user
      final dietDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('diets')
          .doc(widget.subscriptionId)
          .get();

      if (dietDoc.exists) {
        final data = dietDoc.data();
        if (data != null && data['mealContents'] != null) {
          setState(() {
            mealContents = (data['mealContents'] as Map<String, dynamic>).map(
                  (key, value) {
                return MapEntry(
                  Meals.fromName(key),
                  List<String>.from(value as List<dynamic>),
                );
              },
            );
          });
        }
      } else {
        logger.warn('No diet found for the subscription.');
      }
    } catch (e) {
      logger.err('Error fetching meal list: {}', [e.toString()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.info('Building MealUploadPage');
    final imageManager = Provider.of<ImageManager>(context, listen: false);
    final mealStateManager =
    Provider.of<MealStateManager>(context, listen: false);
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

                              final result = await imageManager.uploadFile(
                                File(image!.path),
                                meal: mealCategory,
                                userId: widget.userId,
                              );

                              if (!mounted) return;

                              setState(() {
                                _isUploading = false;
                              });

                              if (result.isUploadOk &&
                                  result.downloadUrl != null) {
                                // Create a new MealModel and save to Firestore
                                final mealDocRef = FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(widget.userId)
                                    .collection('meals')
                                    .doc(); // Generate a new meal ID

                                MealModel mealModel = MealModel(
                                  mealId: mealDocRef.id,
                                  mealType: mealCategory,
                                  imageUrl: result.downloadUrl!,
                                  subscriptionId: widget.subscriptionId,
                                  timestamp: DateTime.now(),
                                  description: null,
                                  calories: null,
                                  notes: null,
                                );

                                await mealDocRef.set(mealModel.toMap());

                                // Update meal checked state
                                mealStateManager.setMealCheckedState(
                                    mealCategory, true);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                      Text('Photo uploaded successfully.')),
                                );
                              } else if (result.errorMessage != null) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(result.errorMessage!)),
                                );
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
