// providers/user_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../commons/userclass.dart';
import '../tabs/basetab.dart';

class UserProvider extends ChangeNotifier with Loadable {
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  @override
  bool get isLoading => _isLoading;

  Future<void> fetchUserDetails(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        _user = UserModel.fromDocument(doc);
      }
    } catch (e) {
      // Handle errors as needed
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
