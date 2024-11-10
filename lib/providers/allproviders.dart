// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import '../models/appointment_model.dart';
// import '../models/logger.dart';
// import '../tabs/basetab.dart';
//
// class AppointmentManager extends ChangeNotifier with Loadable {
//   final Logger logger = Logger.forClass(AppointmentManager);
//
//   List<AppointmentModel> _userAppointments = [];
//   List<AppointmentModel> _dayAppointments = [];
//   bool _isLoading = false;
//   bool _showAllAppointments = false;
//
//   String? _userId;
//   String? _selectedSubscriptionId;
//
//   // Getters
//   List<AppointmentModel> get userAppointments => _userAppointments;
//   String? get userId => _userId;
//   bool get showAllAppointments => _showAllAppointments;
//   String? get selectedSubscriptionId => _selectedSubscriptionId;
//
//   @override
//   bool get isLoading => _isLoading;
//
//   AppointmentManager();
//
//   // Setters
//   void setUserId(String userId) {
//     _userId = userId;
//     fetchAppointments();
//   }
//
//   void setSelectedSubscriptionId(String? subscriptionId) {
//     _selectedSubscriptionId = subscriptionId;
//     fetchAppointments();
//   }
//
//   void setShowAllAppointments(bool value) {
//     if (_showAllAppointments != value) {
//       logger.info('setShowAllAppointments is called with _showAllAppointments={}', [value]);
//       _showAllAppointments = value;
//       fetchAppointments();
//     }
//   }
//
//   // Fetch Appointments based on the selected subscription and showAllAppointments flag
//   Future<void> fetchAppointments() async {
//     if (_userId == null) return;
//
//     _isLoading = true;
//     // notifyListeners();
//
//     try {
//       Query query = FirebaseFirestore.instance
//           .collection('users')
//           .doc(_userId)
//           .collection('appointments')
//           .orderBy('appointmentDateTime', descending: false);
//
//       if (!_showAllAppointments && _selectedSubscriptionId != null) {
//         query = query.where('subscriptionId', isEqualTo: _selectedSubscriptionId);
//       }
//
//       QuerySnapshot snapshot = await query.get();
//
//       _userAppointments = snapshot.docs
//           .map((doc) => AppointmentModel.fromDocument(doc))
//           .toList();
//
//       logger.info('Appointments fetched successfully.');
//     } catch (e) {
//       logger.err('Error fetching appointments: {}', [e]);
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   // Fetch appointments for the current user
//   Future<void> fetchUserAppointments() async {
//     if (_userId == null) return;
//
//     _isLoading = true;
//     //notifyListeners();
//
//     try {
//       QuerySnapshot snapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(_userId)
//           .collection('appointments')
//           .orderBy('appointmentDateTime', descending: false)
//           .get();
//
//       _userAppointments = snapshot.docs
//           .map((doc) => AppointmentModel.fromDocument(doc))
//           .toList();
//
//       logger.info('User appointments fetched successfully.');
//     } catch (e) {
//       logger.err('Error fetching user appointments: {}', [e]);
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   // Fetch appointments for a specific date to determine available time slots
//   Future<List<TimeOfDay>> getAvailableTimesForDate(DateTime date) async {
//     DateTime startOfDay = DateTime(date.year, date.month, date.day);
//     DateTime endOfDay = startOfDay.add(const Duration(days: 1));
//     _isLoading=true;
//     List<TimeOfDay> availableSlots = [];
//     try {
//       // Query query = FirebaseFirestore.instance
//       //     .collection('appointments')
//       //     .where('appointmentDateTime', isGreaterThanOrEqualTo: startOfDay)
//       //     .where('appointmentDateTime', isLessThan: endOfDay);
//
//       QuerySnapshot snapshot = await FirebaseFirestore.instance
//           .collectionGroup('appointments')
//           .where('appointmentDateTime', isGreaterThanOrEqualTo: startOfDay)
//           .where('appointmentDateTime', isLessThan: endOfDay)
//           .get();
//
//       //final snapshot = await query.get();
//
//       _dayAppointments = snapshot.docs
//           .map((doc) => AppointmentModel.fromDocument(doc))
//           .toList();
//
//       logger.info(
//           'Appointments for date {}/{}/{} fetched successfully.', [date.day, date.month, date.year]);
//
//       for (int hour = 9; hour < 19; hour++) {
//         for (int minute = 0; minute < 60; minute += 30) {
//           TimeOfDay time = TimeOfDay(hour: hour, minute: minute);
//           if (isTimeSlotAvailable(date, time)) {
//             availableSlots.add(time);
//           }
//         }
//       }
//     } catch (e) {
//       logger.err('Error fetching appointments for date {}: {}', [date, e]);
//     } finally {
//       _isLoading=false;
//       notifyListeners();
//     }
//     return availableSlots;
//   }
//
//   // Check if a time slot is available
//   bool isTimeSlotAvailable(DateTime date, TimeOfDay time) {
//     DateTime dateTimeWithHour =
//     DateTime(date.year, date.month, date.day, time.hour, time.minute);
//     for (var appointment in _dayAppointments) {
//       if (appointment.appointmentDateTime == dateTimeWithHour &&
//           appointment.status != MeetingStatus.canceled) {
//         return false;
//       }
//     }
//     return true;
//   }
//
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
//       _userAppointments.add(appointment);
//
//       logger.info('Appointment added successfully: {}', [appointment]);
//
//     } catch (e) {
//       logger.err('Error adding appointment: {}', [e]);
//       throw Exception('Error adding appointment.');
//     }finally {
//       notifyListeners();
//     }
//   }
//
//   // Cancel an appointment
//   Future<bool> cancelAppointment(String appointmentId, {required String canceledBy}) async {
//     if (_userId == null) {
//       return false;
//     }
//
//     try {
//       // Update in user's appointments subcollection
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(_userId)
//           .collection('appointments')
//           .doc(appointmentId)
//           .update({
//         'status': MeetingStatus.canceled.label,
//         'canceledBy': canceledBy,
//         'canceledAt': Timestamp.now(),
//       });
//
//
//       // Update local list
//       int index = _userAppointments.indexWhere((a) => a.appointmentId == appointmentId);
//       if (index != -1) {
//         _userAppointments[index].status = MeetingStatus.canceled;
//         _userAppointments[index].canceledBy = canceledBy;
//         _userAppointments[index].canceledAt = DateTime.now();
//       }
//
//       logger.info('Appointment canceled successfully by {}.', [canceledBy]);
//       return false;
//     } catch (e) {
//       logger.err('Error canceling appointment: {}', [e]);
//       return false;
//     }
//     finally{
//       notifyListeners();
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
//
//       // Update local list
//       int index = _userAppointments.indexWhere(
//               (a) => a.appointmentId == updatedAppointment.appointmentId);
//       if (index != -1) {
//         _userAppointments[index] = updatedAppointment;
//       }
//
//       logger.info('Appointment updated successfully: {}', [updatedAppointment]);
//     } catch (e) {
//       logger.err('Error updating appointment: {}', [e]);
//       throw Exception('Error updating appointment.');
//     }finally{
//       notifyListeners();
//     }
//   }
// }
// // image_manager.dart
//
// import 'dart:io';
//
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
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
//   final Logger logger = Logger.forClass(ImageManager);
//
//   Future<UploadResult> uploadFile(File? imageFile,
//       {Meals? meal, required String userId}) async {
//     if (imageFile == null) {
//       return UploadResult(errorMessage: 'No image selected for upload.');
//     }
//
//     try {
//       String fileName = imageFile.path.split('/').last;
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
//       UploadTask uploadTask = ref.putFile(imageFile);
//
//       await uploadTask;
//
//       // After uploading, get the download URL
//       String downloadUrl = await ref.getDownloadURL();
//       logger.info('Uploaded file to path: $path, downloadUrl: $downloadUrl');
//       return UploadResult(downloadUrl: downloadUrl);
//     } on FirebaseException catch (e) {
//       logger.err('FirebaseException Error during file upload: {}', [e]);
//       return UploadResult(errorMessage: e.message);
//     } catch (e2) {
//       logger.err('Unexpected error during file upload: {}', [e2]);
//       return UploadResult(
//           errorMessage: 'An unexpected error occurred during photo upload.');
//     }
//   }
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
//       await FirebaseAuth.instance.signInWithEmailAndPassword(email: 'utkuyy97@gmail.com', password: '612009aa');
//       return true;
//     } on FirebaseAuthException catch (e) {
//       _handleFirebaseAuthError(e);
//       return false;
//     } catch (_) {
//       _errorMessage = 'Beklenmeyen bir hata oluştu.';
//       return false;
//     }
//     return true;  }
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
// import '../tabs/basetab.dart';
//
// final Logger logger = Logger.forClass(MealStateManager);
//
// class MealStateManager extends ChangeNotifier with Loadable {
//   List<MealModel> _meals = [];
//   bool _isLoading = false;
//   bool _showAllImages = false;
//
//   String? _userId;
//   String? _selectedSubscriptionId;
//
//   Map<Meals, bool> checkedStates = {
//     for (var meal in Meals.values) meal: false,
//   };
//
//   List<MealModel> get meals => _meals;
//   @override
//   bool get isLoading => _isLoading;
//   bool get showAllImages => _showAllImages;
//
//   MealStateManager();
//
//   void setUserId(String userId) {
//     _userId = userId;
//     fetchMeals();
//   }
//
//   void setSelectedSubscriptionId(String? subscriptionId) {
//     _selectedSubscriptionId = subscriptionId;
//     fetchMeals();
//   }
//
//   void setShowAllImages(bool value) {
//     if (_showAllImages != value) {
//       _showAllImages = value;
//       fetchMeals();
//     }
//   }
//
//   void setMealCheckedState(Meals meal, bool isChecked) {
//     checkedStates[meal] = isChecked;
//     notifyListeners();
//   }
//
//   Future<void> fetchMeals() async {
//     _isLoading = true;
//     // notifyListeners();
//
//     try {
//       final userId = _userId;
//
//       if (userId == null) {
//         logger.err('User ID not set.');
//         return;
//       }
//
//       Query query = FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .collection('meals')
//           .orderBy('timestamp', descending: true);
//
//       if (!_showAllImages && _selectedSubscriptionId != null) {
//         query = query.where('subscriptionId', isEqualTo: _selectedSubscriptionId);
//       }
//
//       final snapshot = await query.get();
//
//       _meals = snapshot.docs.map((doc) {
//         final meal = MealModel.fromDocument(doc);
//         // Update checkedStates based on meals fetched
//         checkedStates[meal.mealType] = true;
//         return meal;
//       }).toList();
//     } catch (e) {
//       logger.err('Error fetching meals: {}', [e]);
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
// }
// // providers/payment_provider.dart
//
// import 'dart:io';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/cupertino.dart';
//
// import '../models/logger.dart';
// import '../models/payment_model.dart';
// import '../models/subs_model.dart';
// import '../tabs/basetab.dart';
// final Logger logger = Logger.forClass(PaymentProvider);
//
// class PaymentProvider extends ChangeNotifier with Loadable {
//   List<PaymentModel> _payments = [];
//   bool _isLoading = false;
//   bool _showAllPayments = false;
//
//   String? _userId;
//   String? _selectedSubscriptionId;
//
//   List<PaymentModel> get payments => _payments;
//
//   @override
//   bool get isLoading => _isLoading;
//
//   bool get showAllPayments => _showAllPayments;
//
//   PaymentProvider();
//
//   void setUserId(String userId) {
//     _userId = userId;
//     fetchPayments();
//   }
//
//   void setSelectedSubscriptionId(String? subscriptionId) {
//     _selectedSubscriptionId = subscriptionId;
//     fetchPayments();
//   }
//
//   void setShowAllPayments(bool value) {
//     if (_showAllPayments != value) {
//       logger.info('setShowAllPayments is called with isShowAllPayments={}',[value]);
//       _showAllPayments = value;
//       fetchPayments();
//     }
//   }
//   // New method to add payment
//   Future<void> addPayment({
//     required String userId,
//     required SubscriptionModel subscription,
//     required double amount,
//     DateTime? paymentDate,
//     String status = 'Pending',
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
//         paymentDate: paymentDate ?? DateTime.now(),
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
//       // Refresh payments
//       fetchPayments();
//     } catch (e) {
//       logger.err('Error adding payment: $e');
//       rethrow; // Rethrow the exception to handle it in the UI
//     }
//   }
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
//   Future<void> fetchPayments() async {
//     _isLoading = true;
//     // Do not call notifyListeners here
//     try {
//       if (_userId == null) {
//         // Handle error
//         return;
//       }
//
//       Query query = FirebaseFirestore.instance
//           .collection('users')
//           .doc(_userId)
//           .collection('payments')
//           .orderBy('paymentDate', descending: true);
//
//       if (!_showAllPayments && _selectedSubscriptionId != null) {
//         query =
//             query.where('subscriptionId', isEqualTo: _selectedSubscriptionId);
//       }
//
//       final snapshot = await query.get();
//
//       _payments =
//           snapshot.docs.map((doc) => PaymentModel.fromDocument(doc)).toList();
//
//     } catch (e) {
//       // Handle error TODO
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
// }
// // providers/test_provider.dart
//
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/test_model.dart';
// import '../tabs/basetab.dart';
//
// class TestProvider extends ChangeNotifier with Loadable{
//   List<TestModel> _tests = [];
//   bool _isLoading = false;
//   bool _showAllTests = false;
//
//   String? _selectedSubscriptionId;
//
//   List<TestModel> get tests => _tests;
//   @override
//   bool get isLoading => _isLoading;
//   bool get showAllTests => _showAllTests;
//
//   TestProvider() {
//     fetchTests();
//   }
//
//   void setSelectedSubscriptionId(String? subscriptionId) {
//     _selectedSubscriptionId = subscriptionId;
//     fetchTests();
//   }
//
//   void setShowAllTests(bool value) {
//     if (_showAllTests != value) {
//       _showAllTests = value;
//       fetchTests();
//     }
//   }
//
//   Future<void> fetchTests() async {
//     _isLoading = true;
//     notifyListeners();
//
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         // Handle error
//         return;
//       }
//       final userId = user.uid;
//
//       Query query = FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .collection('tests')
//           .orderBy('testDate', descending: true);
//
//       if (!_showAllTests && _selectedSubscriptionId != null) {
//         query = query.where('subscriptionId', isEqualTo: _selectedSubscriptionId);
//       }
//
//       final snapshot = await query.get();
//
//       _tests = snapshot.docs
//           .map((doc) => TestModel.fromDocument(doc))
//           .toList();
//
//     } catch (e) {
//       // Handle error
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   void clearTests() {
//     _tests = [];
//     notifyListeners();
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/logger.dart';
// import '../models/subs_model.dart';
// import '../models/user_model.dart';
// import '../tabs/basetab.dart';
//
// final Logger logger = Logger.forClass(UserProvider);
//
// class UserProvider extends ChangeNotifier with Loadable {
//   UserModel? _user;
//   List<SubscriptionModel> _subscriptions = [];
//   SubscriptionModel? _selectedSubscription;
//   bool _isLoading = false;
//   bool showAllSubscriptions = false;
//   String? _userId;
//
//   UserModel? get user => _user;
//   List<SubscriptionModel> get subscriptions => _subscriptions;
//   SubscriptionModel? get selectedSubscription => _selectedSubscription;
//
//
//   List<UserModel> _users = [];
//   List<UserModel> get users => _users;
//
//
//   @override
//   bool get isLoading => _isLoading;
//
//   Future<void> fetchUsers() async {
//     _isLoading = true;
//     // notifyListeners();
//     try {
//       final snapshot = await FirebaseFirestore.instance.collection('users').get();
//       _users = snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
//       logger.info('fetchUsers _users={}',[_users]);
//     } catch (e) {
//       logger.err('Error fetching users: {}', [e]);
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   void setUserId(String userId) async {
//     _userId = userId;
//     _isLoading = true;
//     // notifyListeners();
//     // notifyListeners();
//     await fetchUserDetails();
//     await fetchSubscriptions();
//     logger.info('fetchData after setUserId is completed.');
//     _isLoading = false;
//     notifyListeners();
//   }
//
//   Future<void> fetchUserDetails() async {
//     try {
//       if (_userId == null) {
//         logger.err('User ID not set.');
//         return;
//       }
//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(_userId)
//           .get();
//       logger.info('Fetching user details for user id={}',[_userId!]);
//       if (doc.exists) {
//         _user = UserModel.fromDocument(doc);
//       }
//     } catch (e) {
//       logger.err('Error fetching user details: {}', [e]);
//     }
//   }
//   Future<void> addSubscription() async { //TODO: add sub dialog burayı kullanabilmeli.
//
//   }
//   Future<void> fetchSubscriptions() async {
//     try {
//       if (_userId == null) {
//         logger.err('User ID not set.');
//         return;
//       }
//       _isLoading = true;
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
//
//       _subscriptions = snapshot.docs
//           .map((doc) => SubscriptionModel.fromDocument(doc))
//           .toList();
//
//       // Set selectedSubscription if it's null or not in the list
//       if (_selectedSubscription == null ||
//           !_subscriptions.contains(_selectedSubscription)) {
//         _selectedSubscription = _subscriptions.isNotEmpty ? _subscriptions.first : null;
//       }
//     } catch (e) {
//       logger.err('Error fetching subscriptions: {}', [e]);
//     }
//     finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//
//   void setShowAllSubscriptions(bool value) {
//     if (showAllSubscriptions != value) {
//       showAllSubscriptions = value;
//       fetchSubscriptions();
//     }
//   }
//
//   void selectSubscription(SubscriptionModel? subscription) {
//     _selectedSubscription = subscription;
//     notifyListeners();
//   }
// }
