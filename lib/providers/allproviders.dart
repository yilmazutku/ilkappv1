// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../models/appointment_model.dart';
// import '../models/logger.dart';
//
// class AppointmentManager extends ChangeNotifier {
//   final Logger logger = Logger.forClass(AppointmentManager);
//
//   String? _selectedSubscriptionId;
//
//   void setSelectedSubscriptionId(String? subscriptionId) {
//     _selectedSubscriptionId = subscriptionId;
//   }
//
//   // Fetch Appointments
//   Future<List<AppointmentModel>> fetchAppointments(
//       {required bool showAllAppointments, required String userId}) async {
//     try {
//       Query query = FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .collection('appointments')
//           .orderBy('appointmentDateTime', descending: false);
//
//       if (!showAllAppointments && _selectedSubscriptionId != null) {
//         query =
//             query.where('subscriptionId', isEqualTo: _selectedSubscriptionId);
//       }
//
//       QuerySnapshot snapshot = await query.get();
//
//       List<AppointmentModel> appointments = snapshot.docs
//           .map((doc) => AppointmentModel.fromDocument(doc))
//           .toList();
//
//       logger.info('Appointments fetched successfully.');
//
//       return appointments;
//     } catch (e, s) {
//       logger.err('Error fetching app2ointments: {}', [s]);
//       return [];
//     }
//   }
//
//   // Fetch appointments for a specific date to determine available time slots
//   Future<List<TimeOfDay>> getAvailableTimesForDate(DateTime date) async {
//     try {
//       // Fetch available times from Firebase
//       String dateString = DateFormat('yyyy-MM-dd').format(date);
//       DocumentSnapshot timeslotDoc = await FirebaseFirestore.instance
//           .collection('admininput')
//           .doc('timeslots')
//           .collection('dates')
//           .doc(dateString)
//           .get();
//
//       if (!timeslotDoc.exists) {
//         // No available times for the date
//         logger.info('No available times for date {}', [dateString]);
//         return [];
//       }
//
//       Map<String, dynamic> data = timeslotDoc.data() as Map<String, dynamic>;
//       List<dynamic> timesList = data['times'] ?? [];
//
//       // Convert timesList to List<TimeOfDay>
//       List<TimeOfDay> availableTimes = timesList.map<TimeOfDay>((timeString) {
//         // Assume timeString is in format 'HH:mm'
//         List<String> parts = timeString.split(':');
//         int hour = int.parse(parts[0]);
//         int minute = int.parse(parts[1]);
//         return TimeOfDay(hour: hour, minute: minute);
//       }).toList();
//
//       // Fetch appointments already booked for that date
//       DateTime startOfDay = DateTime(date.year, date.month, date.day);
//       DateTime endOfDay = startOfDay.add(const Duration(days: 1));
//
//       QuerySnapshot appointmentSnapshot = await FirebaseFirestore.instance
//           .collectionGroup('appointments')
//           .where('appointmentDateTime', isGreaterThanOrEqualTo: startOfDay)
//           .where('appointmentDateTime', isLessThan: endOfDay)
//           .get();
//
//       List<AppointmentModel> dayAppointments = appointmentSnapshot.docs
//           .map((doc) => AppointmentModel.fromDocument(doc))
//           .toList();
//
//       // Filter out times that are already booked
//       availableTimes = availableTimes.where((time) {
//         return isTimeSlotAvailable(date, time, dayAppointments);
//       }).toList();
//
//       logger.info(
//           'Available times for date {}: {}', [dateString, availableTimes]);
//
//       return availableTimes;
//     } catch (e) {
//       logger.err('Error fetching available times for date {}: {}', [date, e]);
//       return [];
//     }
//   }
//
//
//   // Fetch appointments for a specific date to determine available time slots
//   // Future<List<TimeOfDay>> getAvailableTimesForDate(DateTime date) async {
//   //   DateTime startOfDay = DateTime(date.year, date.month, date.day);
//   //   DateTime endOfDay = startOfDay.add(const Duration(days: 1));
//   //
//   //   try {
//   //     QuerySnapshot snapshot = await FirebaseFirestore.instance
//   //         .collectionGroup('appointments')
//   //         .where('appointmentDateTime', isGreaterThanOrEqualTo: startOfDay)
//   //         .where('appointmentDateTime', isLessThan: endOfDay)
//   //         .get();
//   //
//   //     List<AppointmentModel> dayAppointments = snapshot.docs
//   //         .map((doc) => AppointmentModel.fromDocument(doc))
//   //         .toList();
//   //
//   //     logger.info('Appointments for date {}/{}/{} fetched successfully.', [date.day, date.month, date.year]);
//   //
//   //     List<TimeOfDay> availableSlots = [];
//   //     for (int hour = 9; hour < 19; hour++) {
//   //       for (int minute = 0; minute < 60; minute += 30) {
//   //         TimeOfDay time = TimeOfDay(hour: hour, minute: minute);
//   //         if (isTimeSlotAvailable(date, time, dayAppointments)) {
//   //           availableSlots.add(time);
//   //         }
//   //       }
//   //     }
//   //     return availableSlots;
//   //   } catch (e) {
//   //     logger.err('Error fetching appointments for date {}: {}', [date, e]);
//   //     return [];
//   //   }
//   // }
//
//   // Check if a time slot is available
//   bool isTimeSlotAvailable(DateTime date, TimeOfDay time, List<AppointmentModel>? dayAppointments) {
//     DateTime dateTimeWithHour =
//     DateTime(date.year, date.month, date.day, time.hour, time.minute);
//     // Check if the time slot is in the past
//     if (dayAppointments != null) {
//     if (dateTimeWithHour.isBefore(DateTime.now())) return false;
//       for (var appointment in dayAppointments!) {
//         // appt book etmeden once cagirilirsa diye
//         if (appointment.appointmentDateTime == dateTimeWithHour &&
//             appointment.status != AppointmentStatus.canceled) {
//           return false;
//         }
//       }
//     }
//     return true;
//   }
// //TODO add appt oncesiş de i ss lot availabel check yapak
//   // Add a new appointment
//   Future<void> addAppointment(AppointmentModel appointment) async {
//     try {
//       // Save to user's appointments subcollection
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(appointment.userId)
//           .collection('appointments')
//           .doc(appointment.appointmentId)
//           .set(appointment.toMap());
//
//       logger.info('Appointment added successfully: {}', [appointment]);
//     } catch (e) {
//       logger.err('Error adding appointment: {}', [e]);
//       throw Exception('Error adding appointment.');
//     }
//   }
//
//   // Cancel an appointment
//   Future<bool> cancelAppointment(String appointmentId, String userId,
//       {required String canceledBy}) async {
//     try {
//       // Update in user's appointments subcollection
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .collection('appointments')
//           .doc(appointmentId)
//           .update({
//         'status': AppointmentStatus.canceled.label,
//         'canceledBy': canceledBy,
//         'canceledAt': Timestamp.now(),
//       });
//
//       logger.info('Appointment canceled successfully by {}.', [canceledBy]);
//       return true;
//     } catch (e) {
//       logger.err('Error canceling appointment: {}', [e]);
//       return false;
//     }
//   }
//
//   // Update an existing appointment
//   Future<void> updateAppointment(AppointmentModel updatedAppointment) async {
//     try {
//       // Update in user's appointments subcollection
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(updatedAppointment.userId)
//           .collection('appointments')
//           .doc(updatedAppointment.appointmentId)
//           .update(updatedAppointment.toMap());
//
//       logger.info('Appointment updated successfully: {}', [updatedAppointment]);
//     } catch (e) {
//       logger.err('Error updating appointment: {}', [e]);
//       throw Exception('Error updating appointment.');
//     }
//   }
// }
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter/material.dart';
// // import 'package:image_picker/image_picker.dart';
// // import '../commons/common.dart';
// // import 'image_manager.dart';
// //
// // class ChatManager extends ChangeNotifier {
// //   final TextEditingController _messageController = TextEditingController();
// //
// //   TextEditingController get messageController => _messageController;
// //
// //   final String adminId = 'admin'; // Example admin ID
// //   //final String chatId = 'chat_id2'; // Static chat ID for simplicity
// //   final String chatId = FirebaseAuth.instance.currentUser!.uid;
// //   final ImageManager imageManager;
// //
// //   ChatManager({required this.imageManager});
// //
// //   Future<void> sendMessage({XFile? image}) async {
// //     String? imageUrl;
// //     if (image != null) {
// //       UploadResult result =
// //           await imageManager.uploadFile(image); // Upload image and get URL
// //       imageUrl = result.downloadUrl;
// //     }
// //     imageUrl = imageUrl ?? 'hatalı';
// //     // Create MessageData object including the imageUrl if available
// //     MessageData message = MessageData(
// //       msg: _messageController.text,
// //       timestamp: Timestamp.now(),
// //       imageUrl: imageUrl, //null olabilir
// //     );
// //
// //     await FirebaseFirestore.instance
// //         .collection(Constants.urlChats)
// //         .doc(chatId)
// //         .collection('messages')
// //         .add(message.toJson());
// //     _messageController.clear();
// //     notifyListeners();
// //   }
// //
// //   //Asset yükleyerek denemek için
// //   // Future<String?> uploadAssetImage(String assetPath) async {
// //   //   try {
// //   //     // Load the image from assets
// //   //     ByteData byteData = await rootBundle.load(assetPath);
// //   //     Uint8List imageData = byteData.buffer.asUint8List();
// //   //
// //   //     final userId = FirebaseAuth.instance.currentUser!.uid;
// //   //     String fileName = assetPath.split('/').last;
// //   //     String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
// //   //     String path = '${Constants.urlUsers}$userId';
// //   //
// //   //     // Determine the path based on whether it's a meal photo or a chat photo
// //   //       path = '$path/${Constants.urlChatPhotos}/$date/$fileName';
// //   //
// //   //     // Upload the byte data as a file
// //   //     Reference ref = FirebaseStorage.instance.ref(path);
// //   //     await ref.putData(imageData);
// //   //
// //   //     // After uploading, get the download URL
// //   //     String downloadUrl = await ref.getDownloadURL();
// //   //     return downloadUrl;
// //   //   } catch (e) {
// //   //     print('Error uploading asset image: $e');
// //   //   }
// //   // }
// //   Stream<QuerySnapshot> getMessagesStream() {
// //     return FirebaseFirestore.instance
// //         .collection(Constants.urlChats)
// //         .doc(chatId)
// //         .collection('messages')
// //         .orderBy('timestamp', descending: true)
// //         .snapshots();
// //   }
// //
// //   @override
// //   void dispose() {
// //     // Clean up the controller when the widget is disposed.
// //     _messageController.dispose();
// //     super.dispose();
// //   }
// // }
// // image_manager.dart
//
//
// import 'dart:typed_data'; // Import for Uint8List
//
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
//
// import '../models/logger.dart';
// import '../models/meal_model.dart';
//
// class UploadResult {
//   final String? downloadUrl;
//   final String? errorMessage;
//
//   bool get isUploadOk => downloadUrl != null && errorMessage == null;
//
//   UploadResult({this.downloadUrl, this.errorMessage});
// }
//
// class ImageManager extends ChangeNotifier {
//   static final Logger logger = Logger.forClass(ImageManager);
//
//   Future<UploadResult> uploadFile(XFile? imageFile,
//       {Meals? meal, required String userId}) async {
//     if (imageFile == null) {
//       return UploadResult(errorMessage: 'No image selected for upload.');
//     }
//
//     try {
//       String fileName = imageFile.name;
//       String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
//       String path;
//
//       if (meal != null) {
//         path = 'users/$userId/mealPhotos/$date/${meal.name}/$fileName';
//       } else {
//         path = 'users/$userId/chatPhotos/$date/$fileName';
//       }
//
//       Reference ref = FirebaseStorage.instance.ref(path);
//       logger.debug('Uploading file to path: $path');
//
//       // Read the file as bytes
//       Uint8List imageData = await imageFile.readAsBytes();
//
//       // Determine the content type
//       String? mimeType = imageFile.mimeType;
//       if (mimeType == null) {
//         // Infer from file extension if mimeType is null
//         if (fileName.toLowerCase().endsWith('.png')) {
//           mimeType = 'image/png';
//         } else if (fileName.toLowerCase().endsWith('.jpg') ||
//             fileName.toLowerCase().endsWith('.jpeg')) {
//           mimeType = 'image/jpeg';
//         } else {
//           mimeType = 'application/octet-stream';
//         }
//       }
//
//       SettableMetadata metadata = SettableMetadata(contentType: mimeType);
//
//       // UploadTask uploadTask = ref.putData(imageData, metadata);
//       await ref.putData(imageData, metadata);
//
//      // await uploadTask;
//
//       // After uploading, get the download URL
//       String downloadUrl = await ref.getDownloadURL();
//       logger.info('Uploaded file to path: $path, downloadUrl: $downloadUrl');
//       return UploadResult(downloadUrl: downloadUrl);
//     } on FirebaseException catch (e) {
//       logger.err('FirebaseException Error during file upload: {}', [e.message??'exception does not have message.']);
//       return UploadResult(errorMessage: e.message);
//     } catch (e2) {
//       logger.err('Unexpected error during file upload: {}', [e2.toString()]);
//       return UploadResult(
//           errorMessage: 'An unexpected error occurred during photo upload.');
//     }
//   }
//
//   Future<void> deleteFile(String imageUrl) async {
//     try {
//       final Reference ref = FirebaseStorage.instance.refFromURL(imageUrl);
//       await ref.delete();
//       logger.info('Deleted file at URL: $imageUrl');
//     } catch (e) {
//       logger.err('Error deleting file at URL {}: {}', [imageUrl, e.toString()]);
//     }
//   }
//
// }
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// import '../models/logger.dart';
// final Logger logger = Logger.forClass(LoginProvider);
//
// class LoginProvider extends ChangeNotifier {
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//
//   bool _isLoading = false;
//   String _errorMessage = '';
//   bool _isLoggedIn = false;
//
//   bool get isLoggedIn => _isLoggedIn;
//   bool get isLoading => _isLoading;
//   String get errorMessage => _errorMessage;
//
//   // Login function
//   Future<bool> login(BuildContext context) async {
//     //TODO gerçek logine çevirmek icin comemnten çıkar
//     // if (!_validateInputs()) {
//     //   notifyListeners();
//     //   return false;
//     // }
//
//     _setLoadingState(true);
//     _errorMessage = '';
//
//     bool isLoginSuccessful = await _signIn(
//         emailController.text.trim(), passwordController.text.trim());
//
//     if (isLoginSuccessful) {
//       _isLoggedIn = true;
//     }
//
//     _setLoadingState(false);
//     notifyListeners();
//     return isLoginSuccessful;
//   }
//
//   // Sign-in function
//   Future<bool> _signIn(String email, String password) async {
//     try {
//       //TODO gerçek logine çevirmek icin comemnte al 2.yi birinciyi de çıkar
//       // await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
//       await FirebaseAuth.instance.signInWithEmailAndPassword(email: 'utkuyy97@gmail.com', password: '612009');
//       return true;
//     } on FirebaseAuthException catch (e) {
//       _handleFirebaseAuthError(e);
//       return false;
//     } catch (_) {
//       _errorMessage = 'Beklenmeyen bir hata oluştu.';
//       return false;
//     }
// return true;  }
//
//   // Handle Firebase errors
//   void _handleFirebaseAuthError(FirebaseAuthException e) {
//     switch (e.code) {
//       case 'invalid-email':
//         _errorMessage = 'Geçersiz e-posta adresi.';
//         break;
//       case 'user-disabled':
//         _errorMessage = 'Bu kullanıcı hesabı devre dışı bırakılmış.';
//         break;
//       case 'user-not-found':
//         _errorMessage = 'Kullanıcı adı bulunamadı.';
//         break;
//       case 'wrong-password':
//         _errorMessage = 'Girdiğiniz şifre yanlış. Lütfen tekrar deneyiniz.';
//         break;
//       default:
//         _errorMessage = 'Giriş yaparken beklenmeyen bir hata oluştu.';
//         break;
//     }
//     logger.err('firebase auth err:{}',[e.code]);
//     notifyListeners();
//   }
//
//   // Clear the error message
//   void clearError() {
//     _errorMessage = '';
//     notifyListeners();
//   }
//
//   // Input validation
//   bool _validateInputs() {
//     if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
//       _errorMessage = 'Lütfen alanları doldurunuz.';
//       return false;
//     }
//     return true;
//   }
//
//   // Set loading state
//   void _setLoadingState(bool isLoading) {
//     _isLoading = isLoading;
//     notifyListeners();
//   }
//
//   @override
//   void dispose() {
//     emailController.dispose();
//     passwordController.dispose();
//     super.dispose();
//   }
// }
// // providers/meal_state_and_upload_manager.dart
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import '../models/meal_model.dart';
// import '../models/logger.dart';
//
// final Logger logger = Logger.forClass(MealStateManager);
//
// class MealStateManager extends ChangeNotifier {
//
//   String? _userId;
//   String? _selectedSubscriptionId;
//
//   // Map<Meals, bool> checkedStates = {
//   //   for (var meal in Meals.values) meal: false,
//   // };
//
//   void setUserId(String userId) {
//     _userId = userId;
//   }
//
//   void setSelectedSubscriptionId(String? subscriptionId) {
//     _selectedSubscriptionId = subscriptionId;
//   }
//
//   // void setMealCheckedState(Meals meal, bool isChecked) {
//   //   checkedStates[meal] = isChecked;
//   //   notifyListeners();
//   // }
//
//   Future<List<MealModel>> fetchMeals({required bool showAllImages}) async {
//     try {
//       final userId = _userId;
//
//       if (userId == null) {
//         logger.err('User ID not set.');
//         return [];
//       }
//
//       Query query = FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .collection('meals')
//           .orderBy('timestamp', descending: true);
//
//       if (!showAllImages && _selectedSubscriptionId != null) {
//         query = query.where('subscriptionId', isEqualTo: _selectedSubscriptionId);
//       }
//
//       final snapshot = await query.get();
//
//       List<MealModel> meals = snapshot.docs.map((doc) {
//         final meal = MealModel.fromDocument(doc);
//         // Update checkedStates based on meals fetched
//         //checkedStates[meal.mealType] = true;
//         return meal;
//       }).toList();
//
//       return meals;
//     } catch (e) {
//       logger.err('Error fetching meals: {}', [e]);
//       return [];
//     }
//   }
// }
// import 'dart:io';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
//
// import '../models/logger.dart';
// import '../models/payment_model.dart';
// import '../models/subs_model.dart';
//
// final Logger logger = Logger.forClass(PaymentProvider);
//
// class PaymentProvider extends ChangeNotifier {
//   final Logger logger = Logger.forClass(PaymentProvider);
//
//   String? _userId;
//   String? _selectedSubscriptionId;
//
//   // Setters
//   void setUserId(String userId) {
//     _userId = userId;
//   }
//
//   void setSelectedSubscriptionId(String? subscriptionId) {
//     _selectedSubscriptionId = subscriptionId;
//   }
//
//   // Fetch Payments
//   Future<List<PaymentModel>> fetchPayments({required bool showAllPayments}) async {
//     if (_userId == null) return [];
//
//     try {
//       Query query = FirebaseFirestore.instance
//           .collection('users')
//           .doc(_userId)
//           .collection('payments')
//           .orderBy('paymentDate', descending: true);
//
//       if (!showAllPayments && _selectedSubscriptionId != null) {
//         query = query.where('subscriptionId', isEqualTo: _selectedSubscriptionId);
//       }
//
//       final snapshot = await query.get();
//
//       List<PaymentModel> payments =
//       snapshot.docs.map((doc) => PaymentModel.fromDocument(doc)).toList();
//
//       return payments;
//     } catch (e) {
//       logger.err('Error fetching payments: $e');
//       return [];
//     }
//   }
//
//   // Method to add payment
//   Future<void> addPayment({
//     required String userId,
//     required SubscriptionModel subscription,
//     required double amount,
//     DateTime? paymentDate,
//     PaymentStatus status = PaymentStatus.completed,
//     File? dekontImage,
//     DateTime? dueDate,
//     List<int>? notificationTimes,
//   }) async {
//     try {
//       String? dekontUrl;
//
//       // Upload the dekont image if it exists
//       if (dekontImage != null) {
//         dekontUrl = await _uploadDekontImage(userId, dekontImage);
//       }
//
//       // Create a new payment document
//       final paymentDocRef = FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .collection('payments')
//           .doc();
//
//       PaymentModel paymentModel = PaymentModel(
//         paymentId: paymentDocRef.id,
//         userId: userId,
//         subscriptionId: subscription.subscriptionId,
//         amount: amount,
//         paymentDate: paymentDate,
//         status: status,
//         dekontUrl: dekontUrl,
//         dueDate: dueDate,
//         notificationTimes: notificationTimes,
//       );
//
//       await paymentDocRef.set(paymentModel.toMap());
//       logger.info('Payment added successfully for user $userId');
//
//       // Update the subscription's amountPaid
//       subscription.amountPaid += paymentModel.amount;
//
//       // Update the subscription in Firestore
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .collection('subscriptions')
//           .doc(subscription.subscriptionId)
//           .update({
//         'amountPaid': subscription.amountPaid,
//       });
//
//       // No need to call fetchPayments() here since we're not maintaining a local list
//     } catch (e) {
//       logger.err('Error adding payment: $e');
//       rethrow; // Rethrow the exception to handle it in the UI
//     }
//   }
//
//   Future<String> _uploadDekontImage(String userId, File dekontImage) async {
//     try {
//       final fileName = DateTime.now().millisecondsSinceEpoch.toString();
//       final ref = FirebaseStorage.instance
//           .ref()
//           .child('users/$userId/dekont/$fileName');
//       final uploadTask = ref.putFile(dekontImage);
//
//       final snapshot = await uploadTask;
//       final downloadUrl = await snapshot.ref.getDownloadURL();
//
//       logger.info('Dekont image uploaded to $downloadUrl');
//
//       return downloadUrl;
//     } catch (e) {
//       logger.err('Error uploading dekont image: $e');
//       throw Exception('Error uploading dekont image: $e');
//     }
//   }
//
//   // Update payment method if needed
//   Future<void> updatePayment(PaymentModel updatedPayment) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(updatedPayment.userId)
//           .collection('payments')
//           .doc(updatedPayment.paymentId)
//           .update(updatedPayment.toMap());
//
//       logger.info('Payment updated successfully for user ${updatedPayment.userId}');
//     } catch (e) {
//       logger.err('Error updating payment: $e');
//       throw Exception('Error updating payment: $e');
//     }
//   }
// }
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import '../models/logger.dart';
// import '../models/test_model.dart';
//
// final Logger logger = Logger.forClass(TestProvider);
//
// class TestProvider extends ChangeNotifier {
//   String? _userId;
//
//   void setUserId(String userId) {
//     _userId = userId;
//   }
//
//   Future<List<TestModel>> fetchTests() async {
//     if (_userId == null) {
//       logger.err('User ID not set.');
//       return [];
//     }
//
//     try {
//       Query query = FirebaseFirestore.instance
//           .collection('users')
//           .doc(_userId)
//           .collection('tests')
//           .orderBy('testDate', descending: true);
//
//       final snapshot = await query.get();
//
//       List<TestModel> tests =
//           snapshot.docs.map((doc) => TestModel.fromDocument(doc)).toList();
//
//       return tests;
//     } catch (e) {
//       logger.err('Error fetching tests for user with userId={}. {}',
//           [_userId!, e.toString()]);
//       return [];
//     }
//   }
//
// // Other methods like addTest, updateTest can be added here if needed
// }
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:untitled/main.dart';
//
// import '../models/logger.dart';
// import '../models/subs_model.dart';
// import '../models/user_model.dart';
// import '../pages/admin_create_user_page.dart';
//
// final Logger logger = Logger.forClass(UserProvider);
//
// class UserProvider extends ChangeNotifier {
//   static final UserProvider _userProvider = UserProvider._internal();
//   static final List<String> collections = ['subscriptions', 'appointments', 'dietlists', 'dailyData', 'meals', 'payments'];
//
//   factory UserProvider() => _userProvider;
//   UserProvider._internal();
//
//   String? _userId;
//   String? get userId => _userId;
//
//   void setUserId(String userId) {
//     _userId = userId;
//   }
//
//   /// Fetch User Details
//   Future<UserModel?> fetchUserDetails() async {
//     try {
//       if (_userId == null) {
//         logger.err('fetchUserDetails: User ID not set.');
//         return null;
//       }
//       final doc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
//       logger.info('Fetching user details for userId={}', [_userId!]);
//
//       if (doc.exists) {
//         return UserModel.fromDocument(doc);
//       } else {
//         return null;
//       }
//     } catch (e) {
//       logger.err('Error fetching user details: {}', [e]);
//       return null;
//     }
//   }
//
//   /// Update User Details if Email Not Changed
//   Future<bool> updateUserDetails(UserModel updatedUser) async {
//     try {
//       final userDoc = FirebaseFirestore.instance.collection('users').doc(updatedUser.userId);
//       await userDoc.update(updatedUser.toMap());
//       logger.info('User details updated successfully for userId={}', [updatedUser.userId]);
//       notifyListeners();
//       return true;
//     } catch (e) {
//       logger.err('Error updating user details for userId={}: {}', [updatedUser.userId, e]);
//       return false;
//     }
//   }
//
//   /// Update Email and Migrate Data
//   Future<bool> updateEmailAndMigrate({
//     required String oldUid,
//     required String oldEmail,
//     required String password,
//     required String newEmail,
//     required UserModel updatedUser,
//   }) async {
//     try {
//       final adminUser = FirebaseAuth.instance.currentUser;
//       if (adminUser == null) {
//         logger.err('updateEmailAndMigrate: Admin is not signed in.');
//         return false;
//       }
//
//       // Step 1: Migrate Firestore data
//       final newUid = await _migrateUserDataAndRecreateAuth(
//         oldUid: oldUid,
//         newEmail: newEmail,
//         password: password,
//         updatedUser: updatedUser,
//       );
//
//       if (newUid == null) {
//         logger.err('updateEmailAndMigrate: Data migration or user creation failed.');
//         return false;
//       }
//       /// Silinen kullanıcı, geçici şifreye sahip olmalı. yoksa çalışmaz!!!
//       try {
//         final oldUser = await FirebaseAuth.instance.signInWithEmailAndPassword(
//           email: oldEmail,
//           password: CreateUserPage.tempPw,
//         );
//         await oldUser.user?.delete();
//         logger.info('Deleted the old user and Successfully updated email and migrated data for oldUid={}', [oldUid]);
//       } on Exception catch (e) {
//        logger.err('Exception occurred when trying to delete the old user from authentication. {}',[e]);
//       }
//       await signInAutomatically(); ///TEKRAR ADMIN OLARAK GIRIS YAP
//
//       // Step 2: Delete old Firestore document
//       await FirebaseFirestore.instance.collection('users').doc(oldUid).delete();
//       logger.info('Deleted old Firestore user document for UID={}', [oldUid]);
//
//       // Update the provider state
//       setUserId(newUid);
//       notifyListeners();
//       return true;
//     } catch (e) {
//       logger.err('updateEmailAndMigrate: Error during email update and migration: {}', [e]);
//       return false;
//     }
//   }
//
//   /// Migrate Firestore Data and Recreate Auth User
//   Future<String?> _migrateUserDataAndRecreateAuth({
//     required String oldUid,
//     required String newEmail,
//     required String password,
//     required UserModel updatedUser,
//   }) async {
//     try {
//       // Generate new UID for the user
//       final newUid = FirebaseFirestore.instance.collection('users').doc().id;
//
//       // Step 1: Migrate Firestore Data
//       await _migrateUserData(oldUid, newUid);
//
//       // Step 2: Create new Firebase Authentication user
//       UserCredential newUserCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: newEmail,
//         password: password,
//       );
//
//       if (newUserCred.user == null) {
//         logger.err('Failed to create new Firebase user with email={}', [newEmail]);
//         return null;
//       }
//
//       // Step 3: Update Firestore Document with new UID
//       final updatedUserMap = updatedUser.toMap();
//       updatedUserMap['userId'] = newUid;
//       await FirebaseFirestore.instance.collection('users').doc(newUid).set(updatedUserMap);
//
//       return newUid;
//     } catch (e) {
//       logger.err('Error during Firestore data migration and user recreation: {}', [e]);
//       return null;
//     }
//   }
//
//   /// Migrate Top-Level and Subcollections
//   Future<void> _migrateUserData(String oldUid, String newUid) async {
//     final oldDocRef = FirebaseFirestore.instance.collection('users').doc(oldUid);
//     final newDocRef = FirebaseFirestore.instance.collection('users').doc(newUid);
//
//     // Step 1: Migrate Top-Level Data
//     final oldDataSnapshot = await oldDocRef.get();
//     if (oldDataSnapshot.exists) {
//       final userData = oldDataSnapshot.data();
//       if (userData != null) {
//         userData['userId'] = newUid; // Update UID
//         await newDocRef.set(userData, SetOptions(merge: true));
//         logger.info('Top-level data migrated from oldUid={} to newUid={}', [oldUid, newUid]);
//       }
//     }
//
//     // Step 2: Migrate Subcollections
//     await _migrateSubcollections(oldDocRef, newDocRef);
//   }
//
//   /// Migrate Subcollections
//   Future<void> _migrateSubcollections(DocumentReference oldDocRef, DocumentReference newDocRef) async {
//     for (String subcollectionName in collections) {
//       final oldSubcollectionRef = oldDocRef.collection(subcollectionName);
//       final querySnapshot = await oldSubcollectionRef.get();
//
//       for (final doc in querySnapshot.docs) {
//         final newDocRefSub = newDocRef.collection(subcollectionName).doc(doc.id);
//         await newDocRefSub.set(doc.data());
//         logger.info('Migrated document id={} in subcollection={} for newUid={}', [doc.id, subcollectionName, newDocRef.id]);
//       }
//     }
//   }
//
//   /// Fetch Subscriptions
//   Future<List<SubscriptionModel>> fetchSubscriptions({required bool showAllSubscriptions}) async {
//     try {
//       if (_userId == null) {
//         logger.err('fetchSubscriptions: User ID not set.');
//         return [];
//       }
//       Query query = FirebaseFirestore.instance
//           .collection('users')
//           .doc(_userId)
//           .collection('subscriptions')
//           .orderBy('startDate', descending: true);
//
//       if (!showAllSubscriptions) {
//         query = query.where('status', isEqualTo: SubActiveStatus.active.label);
//       }
//
//       final snapshot = await query.get();
//       return snapshot.docs.map((doc) => SubscriptionModel.fromDocument(doc)).toList();
//     } catch (e) {
//       logger.err('Error fetching subscriptions: {}', [e]);
//       return [];
//     }
//   }
//
//   /// Fetch All Users
//   Future<List<UserModel>> fetchUsers() async {
//     try {
//       final snapshot = await FirebaseFirestore.instance.collection('users').get();
//       List<UserModel> users = snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
//       logger.info('Fetched users: {}', [users]);
//       return users;
//     } catch (e) {
//       logger.err('Error fetching users: {}', [e]);
//       return [];
//     }
//   }
// }
