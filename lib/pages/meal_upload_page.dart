import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/logger.dart';
import '../models/meal_model.dart';
import '../providers/image_manager.dart';

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
  Map<Meals, TimeOfDay> mealTimes = {
    for (var meal in Meals.values) meal: const TimeOfDay(hour: 0, minute: 0),
  };
  bool _isUploading = false;

  late Future<void> _mealContentsFuture;
  final String _currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  // New variables for water consumption and steps
  double _waterIntakeLiters = 0.0; // Water intake in liters
  final TextEditingController _stepsController = TextEditingController();
  bool _isSavingWater = false;
  bool _isSavingSteps = false;
  @override
  void initState() {
    super.initState();
    _mealContentsFuture = _fetchMealStatesAndContents();
  }

  Future<void> _fetchMealStatesAndContents() async {
    try {
      // Fetch meal contents (subtitles)
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('dietlists')
          .orderBy('uploadTime', descending: true)
          .limit(1)
          .get();
      Map<Meals, List<String>> mealContentsTemp = {};
      Map<Meals, TimeOfDay> mealTimesTemp = {};
      if (querySnapshot.docs.isNotEmpty) {
        final latestDoc = querySnapshot.docs.first;
        final data = latestDoc.data() as Map<String, dynamic>;
        if (data['subtitles'] != null) {
          (data['subtitles'] as List<dynamic>).forEach((subtitle) {
            final meal = Meals.fromName(subtitle['name']);
            if (meal != null) {
              final contentList = List<String>.from(
                subtitle['content'].map((item) => item['content'].toString()),
              );
              mealContentsTemp[meal] = contentList;

              // Extract 'time', parse it into TimeOfDay
              String? timeString = subtitle['time'];
              TimeOfDay timeOfDay = const TimeOfDay(hour: 0, minute: 0);
              if (timeString != null && timeString.isNotEmpty) {
                try {
                  final parsedTime = DateFormat('HH:mm').parse(timeString);
                  timeOfDay = TimeOfDay.fromDateTime(parsedTime);
                } catch (e) {
                  logger.err('Error when parsing the time of dietlist:{}',
                      [e.toString()]);
                }
              }
              mealTimesTemp[meal] = timeOfDay;
            } else {
              logger.warn('Skipping unmatched meal: {}', [subtitle['name']]);
            }
          });
        }
      } else {
        logger.warn('No diet lists found for the user.');
      }
      setState(() {
        mealContents = mealContentsTemp;
        mealTimes = mealTimesTemp;
      });
      final mealStateDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('meals')
          .doc(_currentDate)
          .get();
      if (mealStateDoc.exists) {
        final data = mealStateDoc.data();
        if (data != null && data['meals'] != null) {
          final fetchedStates = (data['meals'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(Meals.fromName(key)!, value as bool),
          );
          setState(() {

            for (var meal in fetchedStates.keys) {
              checkedStates[meal] = fetchedStates[meal]!;
            }
          });
        }
      }
      else {
        logger.warn(
            'No mealStateDoc found for date $_currentDate, initializing defaults.');
      }

      final dailyDataDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('dailyData')
          .doc(_currentDate)
          .get();

      if (dailyDataDoc.exists) {
        final data = dailyDataDoc.data();
        if (data != null) {
          setState(() {
            if (data['steps'] != null) {
              _stepsController.text = data['steps'].toString();
            }
            if (data['waterIntake'] != null) {
              _waterIntakeLiters = (data['waterIntake'] as num).toDouble();
            }
          });
        }
      } else {
        logger.info(
            'No daily data found for date $_currentDate, initializing defaults.');
      }
    } catch (e) {
      logger.err('Error fetching meal states or contents: {}', [e.toString()]);
    }
  }

  Future<void> _updateMealState(Meals meal, bool state) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('meals')
          .doc(_currentDate);

      await docRef.set({
        'meals': {
          meal.label: state,
        },
      }, SetOptions(merge: true));

      logger.info('Updated state for {} to {}', [meal.label, state]);
    } catch (e) {
      logger.err('Error updating meal state: {}', [e.toString()]);
    }
  }

  Future<void> _uploadMealImage(Meals mealCategory) async {
    final ImagePicker picker = ImagePicker();
    final imageManager = ImageManager();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      setState(() {
        _isUploading = true;
      });

      // Delete previous image if exists
      await _deletePreviousImage(mealCategory);

      final result = await imageManager.uploadFile(
        image,
        meal: mealCategory,
        userId: widget.userId,
      );

      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      if (result.isUploadOk && result.downloadUrl != null) {
        // Save the meal image information to Firestore
        final mealDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('meals')
            .doc(_currentDate)
            .collection('mealEntries')
            .doc(mealCategory.name); // Use mealCategory.name as document ID

        MealModel mealModel = MealModel(
          mealId: mealDocRef.id,
          mealType: mealCategory,
          imageUrl: result.downloadUrl!,
          subscriptionId: widget.subscriptionId,
          timestamp: DateTime.now(),
          description: null,
          calories: null,
          notes: null,
          isChecked: true, // Meal is considered checked upon upload
        );

        await mealDocRef.set(mealModel.toMap());

        // Update meal checked state
        setState(() {
          checkedStates[mealCategory] = true;
        });

        // Update meal state in the main document
        await _updateMealState(mealCategory, true);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully.')),
        );
      } else if (result.errorMessage != null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage!)),
        );
      }
    }
  }

  Future<void> _deletePreviousImage(Meals mealCategory) async {
    try {
      // Get the meal document
      final mealDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('meals')
          .doc(_currentDate)
          .collection('mealEntries')
          .doc(mealCategory.name); // Use mealCategory.name as document ID

      final mealDoc = await mealDocRef.get();

      if (mealDoc.exists) {
        final mealModel = MealModel.fromDocument(mealDoc);

        // Delete the image from Firebase Storage
        final imageManager = ImageManager();
        await imageManager.deleteFile(
          mealModel.imageUrl,
        );

        // Delete the meal document from Firestore
        await mealDocRef.delete();
      }
    } catch (e) {
      logger.err('Error deleting previous image: {}', [e.toString()]);
    }
  }
  Future<void> _saveWaterIntake() async {
    setState(() {
      _isSavingWater = true;
    });

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('dailyData')
          .doc(_currentDate);

      await docRef.set({
        'waterIntake': _waterIntakeLiters,
      }, SetOptions(merge: true));

      logger.info('Water intake updated to {} liters', [_waterIntakeLiters]);
    } catch (e) {
      logger.err('Error saving water intake: {}', [e.toString()]);
    } finally {
      setState(() {
        _isSavingWater = false;
      });
    }
  }

  Future<void> _saveSteps() async {
    try {
      int? steps = int.tryParse(_stepsController.text) ;
      if (steps == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Girilen sayı geçerli değildir. Lütfen sayıyı kontrol edip tekrar giriniz.')),
        );
        return;
      }

      setState(() {
        _isSavingSteps = true;
      });
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('dailyData')
          .doc(_currentDate);

      await docRef.set({
        'steps': steps,
      }, SetOptions(merge: true));

      logger.info('Steps updated to {}', [steps]);
    } catch (e) {
      logger.err('Error saving steps: {}', [e.toString()]);
    } finally {
      setState(() {
        _isSavingSteps = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    logger.info('Building MealUploadPage');

    Map<Meals, TimeOfDay> mealTimes = {
      Meals.br: const TimeOfDay(hour: 8, minute: 30),
      Meals.firstmid: const TimeOfDay(hour: 10, minute: 30),
      Meals.lunch: const TimeOfDay(hour: 12, minute: 30),
      Meals.secondmid: const TimeOfDay(hour: 15, minute: 30),
      Meals.dinner: const TimeOfDay(hour: 18, minute: 30),
      Meals.thirdmid: const TimeOfDay(hour: 21, minute: 30)
    };
    const defaultMealTime = TimeOfDay(hour: 0, minute: 0);
    // const defaultMealTime = 'TimeOfDay(hour: 0, minute: 0)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Günlüğüm'),
        backgroundColor: Colors.lightBlue,
      ),
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _mealContentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                logger.err('Error in FutureBuilder: {}', [snapshot.error ?? 'snapshot error']);
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Water Intake Section
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text(
                                  'Water Intake',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '${_waterIntakeLiters.toStringAsFixed(2)} Liters',
                                  style: const TextStyle(fontSize: 24),
                                ),
                                Slider(
                                  value: _waterIntakeLiters,
                                  min: 0,
                                  max: 5,
                                  divisions: 20,
                                  label: '${_waterIntakeLiters.toStringAsFixed(2)} L',
                                  onChanged: (value) {
                                    setState(() {
                                      _waterIntakeLiters = value;
                                    });
                                  },
                                  onChangeEnd: (value) {
                                    _saveWaterIntake();
                                  },
                                  activeColor: Colors.blue,
                                  inactiveColor: Colors.blue[100],
                                ),
                                if (_isSavingWater)
                                  const CircularProgressIndicator(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Steps Section
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text(
                                  'Steps Taken',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _stepsController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Enter steps',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _isSavingSteps ? null : _saveSteps,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.green,
                                  ),
                                  child: _isSavingSteps
                                      ? const CircularProgressIndicator(
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                  )
                                      : const Text('Save Steps'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Meals Section
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: Meals.values.length,
                          itemBuilder: (context, index) {
                            final mealCategory = Meals.values[index];
                            final contents = mealContents[mealCategory] ?? [];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  title: Text(
                                    mealCategory.label,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: contents
                                        .map((content) => Text('- $content'))
                                        .toList(),
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
                                        color: Colors.blue,
                                        onPressed: () async {
                                          await _uploadMealImage(mealCategory);
                                        },
                                      ),
                                      Checkbox(
                                        value: checkedStates[mealCategory],
                                        onChanged: (bool? newValue) async {
                                          setState(() {
                                            checkedStates[mealCategory] =
                                                newValue ?? false;
                                          });

                                          // Update the meal state in Firestore
                                          await _updateMealState(
                                              mealCategory, newValue ?? false);
                                        },
                                        activeColor: Colors.deepOrange,
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
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
