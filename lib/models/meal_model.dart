
import 'package:cloud_firestore/cloud_firestore.dart';

class MealModel {
  final String mealId;
  final Meals mealType;
  final String imageUrl;
  final String subscriptionId;
  final String? description;
  final DateTime timestamp;
  final int? calories; // Optional
  final String? notes; // Optional

  MealModel({
    required this.mealId,
    required this.mealType,
    required this.imageUrl,
    required this.subscriptionId,
    this.description,
    required this.timestamp,
    this.calories,
    this.notes,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mealType': mealType.name, // Store the enum's name or label
      'imageUrl': imageUrl,
      'subscriptionId': subscriptionId, // Include subscriptionId
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'calories': calories,
      'notes': notes,
    };
  }
}

enum Meals {
  br('Kahvaltı', 'sabah/', '09:00'),
  firstmid('İlk ara öğün', 'ilkara/', '10:30'),
  lunch('Öğle', 'oglen/', '12:30'),
  secondmid('İkinci Ara Öğün', 'ikinciara/', '16:00'),
  dinner('Akşam', 'aksam/', '19:00'),
  thirdmid('Üçüncü Ara Öğün', 'ucuncuara/', '21:00');

  const Meals(this.label, this.url, this.defaultTime);

  final String label;
  final String url;
  final String defaultTime;

  // Method to get enum from label
  static Meals fromLabel(String label) {
    return Meals.values.firstWhere((e) => e.label == label);
  }

  static Meals fromName(String name) {
    return Meals.values.firstWhere((e) => e.name == name);
  }
}