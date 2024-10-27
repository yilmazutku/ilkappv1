// providers/payment_provider.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';

import '../models/logger.dart';
import '../models/payment_model.dart';
import '../models/subs_model.dart';
import '../tabs/basetab.dart';
final Logger logger = Logger.forClass(PaymentProvider);

class PaymentProvider extends ChangeNotifier with Loadable {
  List<PaymentModel> _payments = [];
  bool _isLoading = false;
  bool _showAllPayments = false;

  String? _userId;
  String? _selectedSubscriptionId;

  List<PaymentModel> get payments => _payments;

  @override
  bool get isLoading => _isLoading;

  bool get showAllPayments => _showAllPayments;

  PaymentProvider();

  void setUserId(String userId) {
    _userId = userId;
    fetchPayments();
  }

  void setSelectedSubscriptionId(String? subscriptionId) {
    _selectedSubscriptionId = subscriptionId;
    fetchPayments();
  }

  void setShowAllPayments(bool value) {
    if (_showAllPayments != value) {
      logger.info('setShowAllPayments is called with isShowAllPayments={}',[value]);
      _showAllPayments = value;
      fetchPayments();
    }
  }
  // New method to add payment
  Future<void> addPayment({
    required String userId,
    required SubscriptionModel subscription,
    required double amount,
    DateTime? paymentDate,
    String status = 'Pending',
    File? dekontImage,
    DateTime? dueDate,
    List<int>? notificationTimes,
  }) async {
    try {
      String? dekontUrl;

      // Upload the dekont image if it exists
      if (dekontImage != null) {
        dekontUrl = await _uploadDekontImage(userId, dekontImage);
      }

      // Create a new payment document
      final paymentDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('payments')
          .doc();

      PaymentModel paymentModel = PaymentModel(
        paymentId: paymentDocRef.id,
        userId: userId,
        subscriptionId: subscription.subscriptionId,
        amount: amount,
        paymentDate: paymentDate ?? DateTime.now(),
        status: status,
        dekontUrl: dekontUrl,
        dueDate: dueDate,
        notificationTimes: notificationTimes,
      );

      await paymentDocRef.set(paymentModel.toMap());
      logger.info('Payment added successfully for user $userId');

      // Update the subscription's amountPaid
      subscription.amountPaid += paymentModel.amount;

      // Update the subscription in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('subscriptions')
          .doc(subscription.subscriptionId)
          .update({
        'amountPaid': subscription.amountPaid,
      });

      // Refresh payments
      fetchPayments();
    } catch (e) {
      logger.err('Error adding payment: $e');
      rethrow; // Rethrow the exception to handle it in the UI
    }
  }
  Future<String> _uploadDekontImage(String userId, File dekontImage) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/$userId/dekont/$fileName');
      final uploadTask = ref.putFile(dekontImage);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      logger.info('Dekont image uploaded to $downloadUrl');

      return downloadUrl;
    } catch (e) {
      logger.err('Error uploading dekont image: $e');
      throw Exception('Error uploading dekont image: $e');
    }
  }
  Future<void> fetchPayments() async {
    _isLoading = true;
    // Do not call notifyListeners here

    try {
      final userId = _userId;

      if (userId == null) {
        // Handle error
        return;
      }

      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('payments')
          .orderBy('paymentDate', descending: true);

      if (!_showAllPayments && _selectedSubscriptionId != null) {
        query =
            query.where('subscriptionId', isEqualTo: _selectedSubscriptionId);
      }

      final snapshot = await query.get();

      _payments =
          snapshot.docs.map((doc) => PaymentModel.fromDocument(doc)).toList();

    } catch (e) {
      // Handle error TODO
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
