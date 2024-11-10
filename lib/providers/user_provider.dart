import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/logger.dart';
import '../models/subs_model.dart';
import '../models/user_model.dart';

final Logger logger = Logger.forClass(UserProvider);

class UserProvider extends ChangeNotifier {
  static final UserProvider _userProvider = UserProvider._internal();
  factory UserProvider () {
    return _userProvider;
  }
  UserProvider._internal();

  String? _userId;

  String? get userId => _userId; // Set User ID
  void setUserId(String userId) { // TODO: belki detailstab ve diğerlerinde fln tek tek set etmemeyi ayarlamak? + diğer providerları da sıngleton yapmak gerek
    _userId = userId;
  }

  // Fetch User Details
  Future<UserModel?> fetchUserDetails() async {
    try {
      if (_userId == null) {
        logger.err('fetchUserDetails:User ID not set.');
        return null;
      }
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();
      logger.info('Fetching user details for user id={}', [_userId!]);
      if (doc.exists) {
        return UserModel.fromDocument(doc);
      } else {
        return null;
      }
    } catch (e) {
      logger.err('Error fetching user details: {}', [e]);
      return null;
    }
  }

  // Fetch Subscriptions
  Future<List<SubscriptionModel>> fetchSubscriptions({required bool showAllSubscriptions}) async {
    try {
      if (_userId == null) {
        logger.err('fetchSubscriptions:User ID not set.');
        return [];
      }
      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('subscriptions')
          .orderBy('startDate', descending: true);

      if (!showAllSubscriptions) {
        query = query.where('status', isEqualTo: SubActiveStatus.active.label);
      }

      final snapshot = await query.get();

      List<SubscriptionModel> subscriptions = snapshot.docs
          .map((doc) => SubscriptionModel.fromDocument(doc))
          .toList();

      return subscriptions;
    } catch (e) {
      logger.err('Error fetching subscriptions: {}', [e]);
      return [];
    }
  }

  // Fetch Users (if needed)
  Future<List<UserModel>> fetchUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      List<UserModel> users = snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
      logger.info('fetchUsers users={}', [users]);
      return users;
    } catch (e) {
      logger.err('Error fetching users: {}', [e]);
      return [];
    }
  }
}
