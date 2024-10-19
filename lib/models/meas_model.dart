

import 'package:cloud_firestore/cloud_firestore.dart';

class MeasurementModel {
  final String measurementId;
  final String userId;
  final DateTime date;
  final double height; // in cm
  final double weight; // in kg
  final double? armCircumference; // in cm
  final double? legCircumference; // in cm
  final double? waistCircumference; // in cm
  final double? bodyFatPercentage; // Optional
  final String? notes; // Optional

  MeasurementModel({
    required this.measurementId,
    required this.userId,
    required this.date,
    required this.height,
    required this.weight,
    this.armCircumference,
    this.legCircumference,
    this.waistCircumference,
    this.bodyFatPercentage,
    this.notes,
  });

  factory MeasurementModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MeasurementModel(
      measurementId: doc.id,
      userId: data['userId'],
      date: (data['date'] as Timestamp).toDate(),
      height: data['height'],
      weight: data['weight'],
      armCircumference: data['armCircumference'],
      legCircumference: data['legCircumference'],
      waistCircumference: data['waistCircumference'],
      bodyFatPercentage: data['bodyFatPercentage'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'height': height,
      'weight': weight,
      'armCircumference': armCircumference,
      'legCircumference': legCircumference,
      'waistCircumference': waistCircumference,
      'bodyFatPercentage': bodyFatPercentage,
      'notes': notes,
    };
  }
}