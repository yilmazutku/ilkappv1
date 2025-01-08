import 'package:cloud_firestore/cloud_firestore.dart';

class MeasurementModel {
  DateTime date;
  double? chest;
  double? back;
  double? waist;
  double? hips;
  double? leg;
  double? arm;
  double? weight;
  double? fatKg;
  String? hungerStatus;
  String? constipation;
  String? other;
  int? calorie;

  MeasurementModel({
    required this.date,
    this.chest,
    this.back,
    this.waist,
    this.hips,
    this.leg,
    this.arm,
    this.weight,
    this.fatKg,
    this.hungerStatus,
    this.constipation,
    this.other,
    this.calorie,
  });

  // Convert MeasurementModel to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      if (chest != null) 'chest': chest,
      if (back != null) 'back': back,
      if (waist != null) 'waist': waist,
      if (hips != null) 'hips': hips,
      if (leg != null) 'leg': leg,
      if (arm != null) 'arm': arm,
      if (weight != null) 'weight': weight,
      if (fatKg != null) 'fatKg': fatKg,
      if (hungerStatus != null) 'hungerStatus': hungerStatus,
      if (constipation != null) 'constipation': constipation,
      if (other != null) 'other': other,
      if (calorie != null) 'calorie': calorie,
    };
  }

  // Create a MeasurementModel from a Firestore document
  factory MeasurementModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MeasurementModel(
      date: (data['date'] as Timestamp).toDate(),
      chest: data['chest']?.toDouble(),
      back: data['back']?.toDouble(),
      waist: data['waist']?.toDouble(),
      hips: data['hips']?.toDouble(),
      leg: data['leg']?.toDouble(),
      arm: data['arm']?.toDouble(),
      weight: data['weight']?.toDouble(),
      fatKg: data['fatKg']?.toDouble(),
      hungerStatus: data['hungerStatus'],
      constipation: data['constipation'],
      other: data['other'],
      calorie: data['calorie']?.toInt(),
    );
  }

  @override
  String toString() {
    return 'MeasurementModel(date: $date, chest: $chest, back: $back, waist: $waist, hips: $hips, leg: $leg, arm: $arm, weight: $weight, fatKg: $fatKg, hungerStatus: $hungerStatus, constipation: $constipation, other: $other, calorie: $calorie)';
  }
}