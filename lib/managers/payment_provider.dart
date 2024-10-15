// providers/payment_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../commons/userclass.dart';
import '../tabs/basetab.dart';

class PaymentProvider extends ChangeNotifier with Loadable {
  List<PaymentModel> _payments = [];
  bool _isLoading = false;
  bool _showAllPayments = false;

  String? _selectedSubscriptionId;

  List<PaymentModel> get payments => _payments;
  bool get isLoading => _isLoading;
  bool get showAllPayments => _showAllPayments;

  PaymentProvider() {
    fetchPayments();
  }

  void setSelectedSubscriptionId(String? subscriptionId) {
    _selectedSubscriptionId = subscriptionId;
    fetchPayments();
  }

  void setShowAllPayments(bool value) {
    if (_showAllPayments != value) {
      _showAllPayments = value;
      fetchPayments();
    }
  }

  Future<void> fetchPayments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Handle error
        return;
      }
      final userId = user.uid;

      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('payments')
          .orderBy('paymentDate', descending: true);

      if (!_showAllPayments && _selectedSubscriptionId != null) {
        query = query.where('subscriptionId', isEqualTo: _selectedSubscriptionId);
      }

      final snapshot = await query.get();

      _payments = snapshot.docs
          .map((doc) => PaymentModel.fromDocument(doc))
          .toList();

    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearPayments() {
    _payments = [];
    notifyListeners();
  }
}
