import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/models/user_model.dart';

class AppointmentModel {
  final String appointmentId;
  final String userId;
  final String subscriptionId;
  final MeetingType meetingType;
  final DateTime appointmentDateTime;
  AppointmentStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy; // 'user' or 'admin'
  String? canceledBy; // 'user' or 'admin'
  DateTime? canceledAt;
  UserModel? user;//sonradan eklendi, userid var ama user yok gosterirken hangi username e ait old icin
  bool? isDeleted = false;
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
    this.createdBy,
    this.canceledBy,
    this.canceledAt,
    this.user,
    this.isDeleted,
  });

  factory AppointmentModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      appointmentId: doc.id,
      userId: data['userId'],
      subscriptionId: data['subscriptionId'],
      meetingType: MeetingType.fromLabel(data['meetingType']),
      appointmentDateTime: (data['appointmentDateTime'] as Timestamp).toDate(),
      status: AppointmentStatus.fromLabel(data['status']),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      createdBy: data['createdBy'],
      canceledBy: data['canceledBy'],
      canceledAt: data['canceledAt'] != null
          ? (data['canceledAt'] as Timestamp).toDate()
          : null,
      isDeleted: data['isDeleted'] == null
          ? false
          : data['isDeleted'] == 'true'
              ? true
              : false,
    );
  }

  @override
  String toString() {
    return 'AppointmentModel{appointmentId: $appointmentId, userId: $userId, subscriptionId: $subscriptionId, meetingType: $meetingType, appointmentDateTime: $appointmentDateTime, status: $status, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, canceledBy: $canceledBy, canceledAt: $canceledAt}';
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'subscriptionId': subscriptionId,
      'meetingType': meetingType.label,
      'appointmentDateTime': Timestamp.fromDate(appointmentDateTime),
      'status': status.label,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
      'canceledBy': canceledBy,
      'canceledAt': canceledAt != null ? Timestamp.fromDate(canceledAt!) : null,
      'isDeleted': isDeleted ?? false,
    };
  }
}

enum AppointmentStatus {
  completed('Yapıldı'),
  scheduled('Planlandı'),
  burned('Yakıldı'),
  canceled('Iptal edildi'),
 // pendingCancellation('Iptal onayı bekliyor'), // New status
  postponed('Ertelendi');

  const AppointmentStatus(this.label);

  final String label;

  static AppointmentStatus fromLabel(String label) {
    return AppointmentStatus.values.firstWhere((e) => e.label == label);
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
