import 'package:cloud_firestore/cloud_firestore.dart';

import 'common.dart';


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

class DietModel {
  final String dietId;
  final String userId;
  final String dietPlanUrl; // URL to the diet plan document
  final DateTime assignedAt;
  final DateTime? validFrom;
  final DateTime? validTo;
  final String? notes; // Optional

  DietModel({
    required this.dietId,
    required this.userId,
    required this.dietPlanUrl,
    required this.assignedAt,
    this.validFrom,
    this.validTo,
    this.notes,
  });

  factory DietModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DietModel(
      dietId: doc.id,
      userId: data['userId'],
      dietPlanUrl: data['dietPlanUrl'],
      assignedAt: (data['assignedAt'] as Timestamp).toDate(),
      validFrom: data['validFrom'] != null
          ? (data['validFrom'] as Timestamp).toDate()
          : null,
      validTo: data['validTo'] != null
          ? (data['validTo'] as Timestamp).toDate()
          : null,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'dietPlanUrl': dietPlanUrl,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'validFrom':
      validFrom != null ? Timestamp.fromDate(validFrom!) : null,
      'validTo': validTo != null ? Timestamp.fromDate(validTo!) : null,
      'notes': notes,
    };
  }
}
class PaymentModel {
  final String paymentId;
  final String userId;
  final double amount;
  final String currency;
  final DateTime paymentDate;
  final String paymentMethod;
  final String status; // 'completed', 'pending', 'failed'
  final String? notes; // Optional
  final DateTime createdAt;

  PaymentModel({
    required this.paymentId,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.paymentDate,
    required this.paymentMethod,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory PaymentModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      paymentId: doc.id,
      userId: data['userId'],
      amount: data['amount'],
      currency: data['currency'],
      paymentDate: (data['paymentDate'] as Timestamp).toDate(),
      paymentMethod: data['paymentMethod'],
      status: data['status'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'paymentMethod': paymentMethod,
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class AppointmentModel {
  final String appointmentId;
  final String userId;
  final MeetingType meetingType;
  final DateTime appointmentDateTime;
  final String status; // 'scheduled', 'completed', 'canceled'
  final String? notes; // Optional
  final DateTime createdAt;
  final DateTime? updatedAt;

  AppointmentModel({
    required this.appointmentId,
    required this.userId,
    required this.meetingType,
    required this.appointmentDateTime,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory AppointmentModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      appointmentId: doc.id,
      userId: data['userId'],
      meetingType: MeetingType.fromLabel(data['meetingType']),
      appointmentDateTime: (data['appointmentDateTime'] as Timestamp).toDate(),
      status: data['status'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'meetingType': meetingType.label,
      'appointmentDateTime': Timestamp.fromDate(appointmentDateTime),
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt':
      updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
class MealModel {
  final String mealId;
  final Meals mealType;
  final String imageUrl;
  final String? description;
  final DateTime timestamp;
  final int? calories; // Optional
  final String? notes; // Optional

  MealModel({
    required this.mealId,
    required this.mealType,
    required this.imageUrl,
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
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'calories': calories,
      'notes': notes,
    };
  }
}
class UserModel {
  final String userId;
  final String name;
  final String email;
  final String role; // 'admin' or 'customer'
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      name: data['name'],
      email: data['email'],
      role: data['role'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
