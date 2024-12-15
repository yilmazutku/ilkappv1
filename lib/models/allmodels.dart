// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:untitled/models/user_model.dart';
//
// class AppointmentModel {
//   final String appointmentId;
//   final String userId;
//   final String subscriptionId;
//   final MeetingType meetingType;
//   final DateTime appointmentDateTime;
//   AppointmentStatus status;
//   final String? notes;
//   final DateTime createdAt;
//   final DateTime? updatedAt;
//   final String? createdBy; // 'user' or 'admin'
//   String? canceledBy; // 'user' or 'admin'
//   DateTime? canceledAt;
//   UserModel? user;//sonradan eklendi, userid var ama user yok gosterirken hangi username e ait old icin
//   bool? isDeleted = false;
//   AppointmentModel({
//     required this.appointmentId,
//     required this.userId,
//     required this.subscriptionId,
//     required this.meetingType,
//     required this.appointmentDateTime,
//     required this.status,
//     this.notes,
//     required this.createdAt,
//     this.updatedAt,
//     this.createdBy,
//     this.canceledBy,
//     this.canceledAt,
//     this.user,
//     this.isDeleted,
//   });
//
//   factory AppointmentModel.fromDocument(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return AppointmentModel(
//       appointmentId: doc.id,
//       userId: data['userId'],
//       subscriptionId: data['subscriptionId'],
//       meetingType: MeetingType.fromLabel(data['meetingType']),
//       appointmentDateTime: (data['appointmentDateTime'] as Timestamp).toDate(),
//       status: AppointmentStatus.fromLabel(data['status']),
//       notes: data['notes'],
//       createdAt: (data['createdAt'] as Timestamp).toDate(),
//       updatedAt: data['updatedAt'] != null
//           ? (data['updatedAt'] as Timestamp).toDate()
//           : null,
//       createdBy: data['createdBy'],
//       canceledBy: data['canceledBy'],
//       canceledAt: data['canceledAt'] != null
//           ? (data['canceledAt'] as Timestamp).toDate()
//           : null,
//       isDeleted: data['isDeleted'] == null
//           ? false
//           : data['isDeleted'] == 'true'
//               ? true
//               : false,
//     );
//   }
//
//   @override
//   String toString() {
//     return 'AppointmentModel{appointmentId: $appointmentId, userId: $userId, subscriptionId: $subscriptionId, meetingType: $meetingType, appointmentDateTime: $appointmentDateTime, status: $status, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, canceledBy: $canceledBy, canceledAt: $canceledAt}';
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'userId': userId,
//       'subscriptionId': subscriptionId,
//       'meetingType': meetingType.label,
//       'appointmentDateTime': Timestamp.fromDate(appointmentDateTime),
//       'status': status.label,
//       'notes': notes,
//       'createdAt': Timestamp.fromDate(createdAt),
//       'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
//       'createdBy': createdBy,
//       'canceledBy': canceledBy,
//       'canceledAt': canceledAt != null ? Timestamp.fromDate(canceledAt!) : null,
//       'isDeleted': isDeleted ?? false,
//     };
//   }
// }
//
// enum AppointmentStatus {
//   completed('Yapıldı'),
//   scheduled('Planlandı'),
//   burned('Yakıldı'),
//   canceled('Iptal edildi'),
//  // pendingCancellation('Iptal onayı bekliyor'), // New status
//   postponed('Ertelendi');
//
//   const AppointmentStatus(this.label);
//
//   final String label;
//
//   static AppointmentStatus fromLabel(String label) {
//     return AppointmentStatus.values.firstWhere((e) => e.label == label);
//   }
// }
//
// enum MeetingType {
//   online('Online'),
//   f2f('Yüz yüze');
//
//   const MeetingType(this.label);
//
//   final String label;
//
//   static MeetingType fromLabel(String label) {
//     return MeetingType.values.firstWhere((e) => e.label == label);
//   }
// }
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class DietModel {
//   final String dietId;
//   final String userId;
//   final String dietPlanUrl; // URL to the diet plan document
//   final DateTime assignedAt;
//   final DateTime? validFrom;
//   final DateTime? validTo;
//   final String? notes; // Optional
//
//   DietModel({
//     required this.dietId,
//     required this.userId,
//     required this.dietPlanUrl,
//     required this.assignedAt,
//     this.validFrom,
//     this.validTo,
//     this.notes,
//   });
//
//   factory DietModel.fromDocument(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return DietModel(
//       dietId: doc.id,
//       userId: data['userId'],
//       dietPlanUrl: data['dietPlanUrl'],
//       assignedAt: (data['assignedAt'] as Timestamp).toDate(),
//       validFrom: data['validFrom'] != null
//           ? (data['validFrom'] as Timestamp).toDate()
//           : null,
//       validTo: data['validTo'] != null
//           ? (data['validTo'] as Timestamp).toDate()
//           : null,
//       notes: data['notes'],
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'userId': userId,
//       'dietPlanUrl': dietPlanUrl,
//       'assignedAt': Timestamp.fromDate(assignedAt),
//       'validFrom': validFrom != null ? Timestamp.fromDate(validFrom!) : null,
//       'validTo': validTo != null ? Timestamp.fromDate(validTo!) : null,
//       'notes': notes,
//     };
//   }
// }import 'dart:developer' as developer;
// import 'package:intl/intl.dart'; // For formatting the timestamp
//
// class Logger {
//   final String name;
//
//   Logger(this.name);
//
//   void _log(String level, String message, {Object? error, StackTrace? stackTrace}) {
//     // Get the current time formatted as hour:minute:second
//     String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
//
//     // Include the time in the log message
//     developer.log(
//       '[$currentTime] [$level] $message',
//       name: name,
//       error: error,
//       stackTrace: stackTrace,
//     );
//   }
//
//   factory Logger.forClass(Type type) {
//     return Logger(type.toString());
//   }
//
//   void info(String message, [List<Object>? args]) {
//     _log('INFO', _format(message, args));
//   }
//
//   void debug(String message, [List<Object>? args]) {
//     _log('DEBUG', _format(message, args));
//   }
//
//   void warn(String message, [List<Object>? args]) {
//     _log('WARN', _format(message, args));
//   }
//
//   void err(String message, [List<Object>? args]) {
//     _log('ERROR', _format(message, args));
//   }
//
//   String _format(String message, [List<Object>? args]) {
//     if (args == null || args.isEmpty) {
//       return message;
//     }
//     for (var arg in args) {
//       message = message.replaceFirst(RegExp(r'\{\}'), arg.toString() ?? 'null');
//     }
//     return message;
//   }
// }
//
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import 'logger.dart';
//
// class MealModel {
//   final String mealId;
//   final Meals mealType;
//   final String imageUrl;
//   final String subscriptionId;
//   final String? description;
//   final DateTime timestamp;
//   final int? calories;
//   final String? notes;
//   bool isChecked; // Now mutable to allow state changes
//
//   MealModel({
//     required this.mealId,
//     required this.mealType,
//     required this.imageUrl,
//     required this.subscriptionId,
//     this.description,
//     required this.timestamp,
//     this.calories,
//     this.notes,
//     required this.isChecked,
//   });
//
//   factory MealModel.fromDocument(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return MealModel(
//       mealId: doc.id,
//       mealType: Meals.values.firstWhere((e) => e.name == data['mealType']),
//       imageUrl: data['imageUrl'],
//       subscriptionId: data['subscriptionId'],
//       description: data['description'],
//       timestamp: (data['timestamp'] as Timestamp).toDate(),
//       calories: data['calories'],
//       notes: data['notes'],
//       isChecked: data['isChecked'] ?? false,
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'mealType': mealType.name,
//       'imageUrl': imageUrl,
//       'subscriptionId': subscriptionId,
//       'description': description,
//       'timestamp': Timestamp.fromDate(timestamp),
//       'calories': calories,
//       'notes': notes,
//       'isChecked': isChecked,
//     };
//   }
// }
//
// final Logger logger = Logger.forClass(Meals);
// enum Meals {
//
//
//   br('Kahvaltı','09:00'),
//   firstmid('İlk Ara Öğün', '10:30'),
//   lunch('Öğle', '12:30'),
//   secondmid('İkinci Ara Öğün',  '16:00'),
//   dinner('Akşam', '19:00'),
//   thirdmid('Üçüncü Ara Öğün', '21:00');
//
//   const Meals(this.label,this.defaultTime);
//
//   final String label;
//   final String defaultTime;
//
//   // Method to get enum from label
//   static Meals fromLabel(String label) {
//     return Meals.values.firstWhere((e) => e.label == label);
//   }
//
//   static Meals? fromName(String name) {
//     try {
//       return Meals.values.firstWhere((meal) => meal.label == name);
//     } catch (e) {
//       logger.warn('No matching meal found for name: {}', [name]);
//       return null; // Return null if no match is found
//     }
//   }
// }
//
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class MeasurementModel {
//   final String measurementId;
//   final String userId;
//   final DateTime date;
//   final double height; // in cm
//   final double weight; // in kg
//   final double? armCircumference; // in cm
//   final double? legCircumference; // in cm
//   final double? waistCircumference; // in cm
//   final double? bodyFatPercentage; // Optional
//   final String? notes; // Optional
//
//   MeasurementModel({
//     required this.measurementId,
//     required this.userId,
//     required this.date,
//     required this.height,
//     required this.weight,
//     this.armCircumference,
//     this.legCircumference,
//     this.waistCircumference,
//     this.bodyFatPercentage,
//     this.notes,
//   });
//
//   factory MeasurementModel.fromDocument(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return MeasurementModel(
//       measurementId: doc.id,
//       userId: data['userId'],
//       date: (data['date'] as Timestamp).toDate(),
//       height: data['height'],
//       weight: data['weight'],
//       armCircumference: data['armCircumference'],
//       legCircumference: data['legCircumference'],
//       waistCircumference: data['waistCircumference'],
//       bodyFatPercentage: data['bodyFatPercentage'],
//       notes: data['notes'],
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'userId': userId,
//       'date': Timestamp.fromDate(date),
//       'height': height,
//       'weight': weight,
//       'armCircumference': armCircumference,
//       'legCircumference': legCircumference,
//       'waistCircumference': waistCircumference,
//       'bodyFatPercentage': bodyFatPercentage,
//       'notes': notes,
//     };
//   }
// }import 'package:cloud_firestore/cloud_firestore.dart';
//
// import 'logger.dart';
//
// class PaymentModel {
//   final String paymentId;
//   final String userId;
//   final String subscriptionId;
//   final double amount;
//   final DateTime? paymentDate; // Made nullable
//   final PaymentStatus status;
//   final String? dekontUrl;
//   final DateTime? dueDate;
//   final List<int>? notificationTimes;
//
//   PaymentModel({
//     required this.paymentId,
//     required this.userId,
//     required this.subscriptionId,
//     required this.amount,
//     this.paymentDate, // Nullable
//     required this.status,
//     this.dekontUrl,
//     this.dueDate,
//     this.notificationTimes,
//   });
//
//   factory PaymentModel.fromDocument(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return PaymentModel(
//       paymentId: doc.id,
//       userId: data['userId'],
//       subscriptionId: data['subscriptionId'],
//       amount: data['amount'].toDouble(),
//       paymentDate: data['paymentDate'] != null
//           ? (data['paymentDate'] as Timestamp).toDate()
//           : null,
//       status: PaymentStatus.fromLabel(data['status']),
//       dekontUrl: data['dekontUrl'],
//       dueDate: data['dueDate'] != null
//           ? (data['dueDate'] as Timestamp).toDate()
//           : null,
//       notificationTimes: data['notificationTimes'] != null
//           ? List<int>.from(data['notificationTimes'])
//           : null,
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'userId': userId,
//       'subscriptionId': subscriptionId,
//       'amount': amount,
//       'paymentDate': paymentDate != null ? Timestamp.fromDate(paymentDate!) : null,
//       'status': status.label,
//       'dekontUrl': dekontUrl,
//       'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
//       'notificationTimes': notificationTimes,
//     };
//   }
// }
//
//
// final Logger logger = Logger.forClass(PaymentStatus);
// enum PaymentStatus {
//
//   completed('Tamamlandı'),
//   planned('Planlandı'),
//   ;
//
//   const PaymentStatus(this.label);
//
//   final String label;
//
//   // Method to get enum from label
//   static PaymentStatus fromLabel(String label) {
//     return PaymentStatus.values.firstWhere((e) => e.label == label);
//   }
//
//   // static PaymentStatus? fromName(String name) {
//   //   try {
//   //     return PaymentStatus.values.firstWhere((e) => e.label == name);
//   //   } catch (e) {
//   //     logger.warn('No matching PaymentStatus found for name: {}', [name]);
//   //     return null; // Return null if no match is found
//   //   }
//   // }
// }import 'package:cloud_firestore/cloud_firestore.dart';
//
// class SubscriptionModel {
//   final String subscriptionId;
//   final String userId;
//   final String packageName;
//   final DateTime startDate;
//   DateTime endDate;
//   final int totalMeetings;
//   int meetingsCompleted;
//   int meetingsRemaining;
//   int meetingsBurned;
//   int postponementsUsed;
//   final int allowedPostponementsPerMonth;
//   final double totalAmount;
//   double amountPaid;
//   SubActiveStatus status;
//
//   SubscriptionModel({
//     required this.subscriptionId,
//     required this.userId,
//     required this.packageName,
//     required this.startDate,
//     required this.endDate,
//     required this.totalMeetings,
//     this.meetingsCompleted = 0,
//     required this.meetingsRemaining,
//     this.meetingsBurned = 0,
//     this.postponementsUsed = 0,
//     this.allowedPostponementsPerMonth = 1,
//     required this.totalAmount,
//     this.amountPaid = 0.0,
//     this.status = SubActiveStatus.active,
//   });
//
//   factory SubscriptionModel.fromDocument(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return SubscriptionModel(
//       subscriptionId: doc.id,
//       userId: data['userId'],
//       packageName: data['packageName'],
//       startDate: (data['startDate'] as Timestamp).toDate(),
//       endDate: (data['endDate'] as Timestamp).toDate(),
//       totalMeetings: data['totalMeetings'],
//       meetingsCompleted: data['meetingsCompleted'] ?? 0,
//       meetingsRemaining: data['meetingsRemaining'],
//       meetingsBurned: data['meetingsBurned'] ?? 0,
//       postponementsUsed: data['postponementsUsed'] ?? 0,
//       allowedPostponementsPerMonth: data['allowedPostponementsPerMonth'],
//       totalAmount: data['totalAmount'].toDouble(),
//       amountPaid: data['amountPaid'].toDouble(),
//       status: SubActiveStatus.fromLabel(data['status']),
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'subscriptionId': subscriptionId,
//       'userId': userId,
//       'packageName': packageName,
//       'startDate': Timestamp.fromDate(startDate),
//       'endDate': Timestamp.fromDate(endDate),
//       'totalMeetings': totalMeetings,
//       'meetingsCompleted': meetingsCompleted,
//       'meetingsRemaining': meetingsRemaining,
//       'meetingsBurned': meetingsBurned,
//       'postponementsUsed': postponementsUsed,
//       'allowedPostponementsPerMonth': allowedPostponementsPerMonth,
//       'totalAmount': totalAmount,
//       'amountPaid': amountPaid,
//       'status': status.label,
//     };
//   }
//
//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//           other is SubscriptionModel &&
//               runtimeType == other.runtimeType &&
//               subscriptionId == other.subscriptionId;
//
//   @override
//   int get hashCode => subscriptionId.hashCode;
// }
//
// enum SubActiveStatus {
//   active('active'),
//   completed('completed');
//
//   const SubActiveStatus(this.label);
//
//   final String label;
//
//   static SubActiveStatus fromLabel(String label) {
//     return SubActiveStatus.values.firstWhere((e) => e.label == label);
//   }
// }
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class TestModel {
//   final String testId;
//   final String userId;
//   final String testName;
//   final String? testDescription;
//   final DateTime testDate;
//   final String? testFileUrl; // URL to the uploaded test file (image, PDF)
//
//   TestModel({
//     required this.testId,
//     required this.userId,
//     required this.testName,
//     this.testDescription,
//     required this.testDate,
//     this.testFileUrl,
//   });
//
//   factory TestModel.fromDocument(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return TestModel(
//       testId: doc.id,
//       userId: data['userId'],
//       testName: data['testName'],
//       testDescription: data['testDescription'],
//       testDate: (data['testDate'] as Timestamp).toDate(),
//       testFileUrl: data['testFileUrl'],
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'userId': userId,
//       'testName': testName,
//       'testDescription': testDescription,
//       'testDate': Timestamp.fromDate(testDate),
//       'testFileUrl': testFileUrl,
//     };
//   }
// }import 'package:cloud_firestore/cloud_firestore.dart';
//
// class UserModel {
//   final String userId;
//   final String name;
//   final String email;
//   final String password; // For Firebase user creation
//   final String role; // 'admin' or 'customer'
//   final DateTime createdAt;
//   final String? surname;
//   final int? age;
//   final String? reference;
//   final String? notes;
//
//   UserModel({
//     required this.userId,
//     required this.name,
//     required this.email,
//     required this.password,
//     required this.role,
//     required this.createdAt,
//     this.surname,
//     this.age,
//     this.reference,
//     this.notes,
//   });
//
//   factory UserModel.fromDocument(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return UserModel(
//       userId: doc.id,
//       name: data['name'] ?? '',
//       email: data['email'] ?? '',
//       password: '', // Password should not be stored in Firestore
//       role: data['role'] ?? 'customer',
//       createdAt: (data['createdAt'] as Timestamp).toDate(),
//       surname: data['surname'],
//       age: data['age'],
//       reference: data['reference'],
//       notes: data['notes'],
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'userId': userId,
//       'name': name,
//       'email': email,
//       'role': role,
//       'createdAt': Timestamp.fromDate(createdAt),
//       if (surname != null) 'surname': surname,
//       if (age != null) 'age': age,
//       if (reference != null) 'reference': reference,
//       if (notes != null) 'notes': notes,
//     };
//   }
//
//   @override
//   String toString() {
//     return 'UserModel{userId: $userId, name: $name, email: $email, role: $role, createdAt: $createdAt, surname: $surname, age: $age, reference: $reference, notes: $notes}';
//   }
// }
