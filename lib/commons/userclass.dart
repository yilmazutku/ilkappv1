import 'package:cloud_firestore/cloud_firestore.dart';

import 'common.dart';

class TestModel {
  final String testId;
  final String userId;
  final String testName;
  final String? testDescription;
  final DateTime testDate;
  final String? testFileUrl; // URL to the uploaded test file (image, PDF)

  TestModel({
    required this.testId,
    required this.userId,
    required this.testName,
    this.testDescription,
    required this.testDate,
    this.testFileUrl,
  });

  factory TestModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TestModel(
      testId: doc.id,
      userId: data['userId'],
      testName: data['testName'],
      testDescription: data['testDescription'],
      testDate: (data['testDate'] as Timestamp).toDate(),
      testFileUrl: data['testFileUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'testName': testName,
      'testDescription': testDescription,
      'testDate': Timestamp.fromDate(testDate),
      'testFileUrl': testFileUrl,
    };
  }
}
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
  final DateTime paymentDate; // Date when the payment was made
  final String status;
  final String? dekontUrl;
  final DateTime? dueDate; // For future payments
  final List<int>? notificationTimes; // New field for notification times in hours

  PaymentModel({
    required this.paymentId,
    required this.userId,
    required this.amount,
    required this.paymentDate,
    required this.status,
    this.dekontUrl,
    this.dueDate,
    this.notificationTimes,
  });

  factory PaymentModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      paymentId: doc.id,
      userId: data['userId'],
      amount: data['amount'].toDouble(),
      paymentDate: (data['paymentDate'] as Timestamp).toDate(),
      status: data['status'],
      dekontUrl: data['dekontUrl'],
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      notificationTimes: data['notificationTimes'] != null
          ? List<int>.from(data['notificationTimes'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'status': status,
      'dekontUrl': dekontUrl,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'notificationTimes': notificationTimes,
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
