import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../models/logger.dart';
import '../models/payment_model.dart';
import '../models/subs_model.dart';

final Logger logger = Logger.forClass(PaymentProvider);

class PaymentProvider extends ChangeNotifier {
  final Logger logger = Logger.forClass(PaymentProvider);


  // Fetch Payments
  Future<List<PaymentModel>> fetchPayments(String? selectedSubscriptionId,{required String userId,required bool showAllPayments}) async {

    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('payments')
          .orderBy('paymentDate', descending: true);

      if (!showAllPayments && selectedSubscriptionId != null) {
        query = query.where('subscriptionId', isEqualTo: selectedSubscriptionId);
      }

      final snapshot = await query.get();

      List<PaymentModel> payments =
      snapshot.docs.map((doc) => PaymentModel.fromDocument(doc)).toList();

      return payments;
    } catch (e) {
      logger.err('Error fetching payments: $e');
      return [];
    }
  }

  // Method to add payment
  Future<void> addPayment({
    required String userId,
    SubscriptionModel? subscription,
    required double amount,
    DateTime? paymentDate,
    PaymentStatus status = PaymentStatus.completed,
    File? dekontImage,
    DateTime? dueDate,
    List<int>? notificationTimes,
    String? notes
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
        subscriptionId: subscription?.subscriptionId,
        amount: amount,
        paymentDate: paymentDate,
        status: status,
        dekontUrl: dekontUrl,
        dueDate: dueDate,
        notificationTimes: notificationTimes,
      );

      await paymentDocRef.set(paymentModel.toMap());
      logger.info('Payment added successfully for user $userId');

      // Update the subscription's amountPaid

      // Update the subscription in Firestore
      if (subscription != null) {
        subscription.amountPaid += paymentModel.amount;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('subscriptions')
            .doc(subscription?.subscriptionId)
            .update({
          'amountPaid': subscription?.amountPaid,
        });
      }
      // No need to call fetchPayments() here since we're not maintaining a local list
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

  // Update payment method if needed
  Future<void> updatePayment(PaymentModel updatedPayment) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(updatedPayment.userId)
          .collection('payments')
          .doc(updatedPayment.paymentId)
          .update(updatedPayment.toMap());

      logger.info('Payment updated successfully for user ${updatedPayment.userId}');
    } catch (e) {
      logger.err('Error updating payment: $e');
      throw Exception('Error updating payment: $e');
    }
  }
}
