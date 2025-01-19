
import 'package:cloud_firestore/cloud_firestore.dart';

import 'logger.dart';

class MealModel {
  final String mealId;
  final Meals mealType;
  final String imageUrl;
  final String? subscriptionId;
  final String? description;
  final DateTime timestamp;
  final int? calories;
  final String? notes;
  bool isChecked; // Now mutable to allow state changes

  MealModel({
    required this.mealId,
    required this.mealType,
    required this.imageUrl,
    this.subscriptionId,
    this.description,
    required this.timestamp,
    this.calories,
    this.notes,
    required this.isChecked,
  });

  factory MealModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MealModel(
      mealId: doc.id,
      mealType: Meals.values.firstWhere((e) => e.name == data['mealType']),
      imageUrl: data['imageUrl'],
      subscriptionId: data['subscriptionId'],
      description: data['description'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      calories: data['calories'],
      notes: data['notes'],
      isChecked: data['isChecked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mealType': mealType.name,
      'imageUrl': imageUrl,
      'subscriptionId': subscriptionId,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'calories': calories,
      'notes': notes,
      'isChecked': isChecked,
    };
  }
}

final Logger logger = Logger.forClass(Meals);
enum Meals {


  br('Kahvaltı','09:00'),
  firstmid('İlk Ara Öğün', '10:30'),
  lunch('Öğle', '12:30'),
  secondmid('İkinci Ara Öğün',  '16:00'),
  dinner('Akşam', '19:00'),
  thirdmid('Üçüncü Ara Öğün', '21:00');

  const Meals(this.label,this.defaultTime);

  final String label;
  final String defaultTime;

  // Method to get enum from label
  static Meals fromLabel(String label) {
    return Meals.values.firstWhere((e) => e.label == label);
  }

  static Meals? fromName(String name) {
    try {
      return Meals.values.firstWhere((meal) => meal.label == name);
    } catch (e) {
      logger.warn('No matching meal found for name: {}', [name]);
      return null; // Return null if no match is found
    }
  }
}