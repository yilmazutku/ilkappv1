import 'package:cloud_firestore/cloud_firestore.dart';

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
      'validFrom': validFrom != null ? Timestamp.fromDate(validFrom!) : null,
      'validTo': validTo != null ? Timestamp.fromDate(validTo!) : null,
      'notes': notes,
    };
  }
}