// providers/user_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subs_model.dart';
import '../models/user_model.dart';
import '../tabs/basetab.dart';

class UserProvider extends ChangeNotifier with Loadable {
  UserModel? _user;
  List<SubscriptionModel> _subscriptions = [];
  SubscriptionModel? _selectedSubscription;
  bool _isLoading = false;

  UserModel? get user => _user;
  List<SubscriptionModel> get subscriptions => _subscriptions;
  SubscriptionModel? get selectedSubscription => _selectedSubscription;

  @override
  bool get isLoading => _isLoading;

  Future<void> fetchUserDetails(String userId) async {
    _isLoading = true;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        _user = UserModel.fromDocument(doc);
        await fetchUserSubscriptions(userId);
      }
    } catch (e) {
      // Handle errors as needed
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserSubscriptions(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('subscriptions')
          .orderBy('startDate', descending: true)
          .get();

      _subscriptions = snapshot.docs.map((doc) => SubscriptionModel.fromDocument(doc)).toList();

      // Automatically select the most recent subscription if available
      if (_subscriptions.isNotEmpty) {
        _selectedSubscription = _subscriptions.first;
      } else {
        _selectedSubscription = null;
      }

      notifyListeners();
    } catch (e) {
      // Handle errors as needed
    }
  }

  void selectSubscription(SubscriptionModel? subscription) {
    _selectedSubscription = subscription;
    notifyListeners();
  }
}
