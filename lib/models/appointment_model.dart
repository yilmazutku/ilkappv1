import 'package:cloud_firestore/cloud_firestore.dart';


class AppointmentModel {
  final String appointmentId;
  final String userId;
  final String subscriptionId; // Added subscriptionId
  final MeetingType meetingType;
  final DateTime appointmentDateTime;
  final MeetingStatus status; // 'scheduled', 'completed', 'postponed', 'burned'
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AppointmentModel({
    required this.appointmentId,
    required this.userId,
    required this.subscriptionId,
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
      subscriptionId: data['subscriptionId'],
      // Fetch subscriptionId
      meetingType: MeetingType.fromLabel(data['meetingType']),
      appointmentDateTime: (data['appointmentDateTime'] as Timestamp).toDate(),
      status: MeetingStatus.fromLabel(data['status']),
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
      'subscriptionId': subscriptionId, // Include subscriptionId
      'meetingType': meetingType.label,
      'appointmentDateTime': Timestamp.fromDate(appointmentDateTime),
      'status': status.label,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}


enum MeetingStatus {
  completed('Yapıldı'),
  scheduled('Planlandı'),
  burned('Yakıldı'),
  canceled('Iptal edildi'),
  postponed('Ertelendi');

  const MeetingStatus(this.label);

  final String label;

  static MeetingStatus fromLabel(String label) {
    return MeetingStatus.values.firstWhere((e) => e.label == label);
  }
}

enum MeetingType {
  online('Online'),
  f2f('Yüz yüze');

  const MeetingType(this.label);

  final String label;

  static MeetingType fromLabel(String label) {
    return MeetingType.values.firstWhere((e) => e.label == label);
  }
}