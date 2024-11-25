import 'package:cloud_firestore/cloud_firestore.dart';

import 'logger.dart';

class PaymentModel {
  final String paymentId;
  final String userId;
  final String subscriptionId; // Added subscriptionId
  final double amount;
  final DateTime? paymentDate;
  final PaymentStatus status;
  final String? dekontUrl;
  final DateTime? dueDate;
  final List<int>? notificationTimes;

  PaymentModel({
    required this.paymentId,
    required this.userId,
    required this.subscriptionId, // Added subscriptionId
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
      subscriptionId: data['subscriptionId'],
      // Fetch subscriptionId
      amount: data['amount'].toDouble(),
      paymentDate: (data['paymentDate'] as Timestamp).toDate(),
      status: PaymentStatus.fromLabel(data['status']),
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
      'subscriptionId': subscriptionId, // Include subscriptionId
      'amount': amount,
      'paymentDate': Timestamp.fromDate(paymentDate!),
      'status': status.label,
      'dekontUrl': dekontUrl,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'notificationTimes': notificationTimes,
    };
  }
}

final Logger logger = Logger.forClass(PaymentStatus);
enum PaymentStatus {


  completed('Tamamlandı'),
  planned('Planlandı'),
  ;

  const PaymentStatus(this.label);

  final String label;

  // Method to get enum from label
  static PaymentStatus fromLabel(String label) {
    return PaymentStatus.values.firstWhere((e) => e.label == label);
  }

  // static PaymentStatus? fromName(String name) {
  //   try {
  //     return PaymentStatus.values.firstWhere((e) => e.label == name);
  //   } catch (e) {
  //     logger.warn('No matching PaymentStatus found for name: {}', [name]);
  //     return null; // Return null if no match is found
  //   }
  // }
}