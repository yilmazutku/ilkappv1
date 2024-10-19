import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String subscriptionId;
  final String userId;
  final String packageName; // Added packageName
  final DateTime startDate;
  DateTime endDate;
  final int totalMeetings;
  int meetingsCompleted;
  int meetingsRemaining;
  int meetingsBurned;
  int postponementsUsed;
  final int allowedPostponementsPerMonth;
  final double totalAmount;
  double amountPaid;
  SubActiveStatus status; // 'active', 'completed'

  SubscriptionModel({
    required this.subscriptionId,
    required this.userId,
    required this.packageName, // Added packageName
    required this.startDate,
    required this.endDate,
    required this.totalMeetings,
    this.meetingsCompleted = 0,
    required this.meetingsRemaining,
    this.meetingsBurned = 0,
    this.postponementsUsed = 0,
    this.allowedPostponementsPerMonth = 1,
    required this.totalAmount,
    this.amountPaid = 0.0,
    this.status = SubActiveStatus.active,
  });

  factory SubscriptionModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionModel(
      subscriptionId: doc.id,
      userId: data['userId'],
      packageName: data['packageName'],
      // Fetch packageName
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      totalMeetings: data['totalMeetings'],
      meetingsCompleted: data['meetingsCompleted'] ?? 0,
      meetingsRemaining: data['meetingsRemaining'],
      meetingsBurned: data['meetingsBurned'] ?? 0,
      postponementsUsed: data['postponementsUsed'] ?? 0,
      allowedPostponementsPerMonth: data['allowedPostponementsPerMonth'],
      totalAmount: data['totalAmount'].toDouble(),
      amountPaid: data['amountPaid'].toDouble(),
      status: SubActiveStatus.fromLabel(data['status']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'packageName': packageName, // Include packageName
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalMeetings': totalMeetings,
      'meetingsCompleted': meetingsCompleted,
      'meetingsRemaining': meetingsRemaining,
      'meetingsBurned': meetingsBurned,
      'postponementsUsed': postponementsUsed,
      'allowedPostponementsPerMonth': allowedPostponementsPerMonth,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'status': status.label,
    };
  }
}


enum SubActiveStatus {
  active('active'), completed('completed');
  const SubActiveStatus(this.label);

  final String label;

  static SubActiveStatus fromLabel(String label) {
    return SubActiveStatus.values.firstWhere((e) => e.label == label);
  }
}