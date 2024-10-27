import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/logger.dart';
import '../models/subs_model.dart';
import '../models/user_model.dart';
import '../tabs/basetab.dart';

final Logger logger = Logger.forClass(UserProvider);

class UserProvider extends ChangeNotifier with Loadable {
  UserModel? _user;
  List<SubscriptionModel> _subscriptions = [];
  SubscriptionModel? _selectedSubscription;
  bool _isLoading = false;
  bool showAllSubscriptions = false;
  String? _userId;

  UserModel? get user => _user;
  List<SubscriptionModel> get subscriptions => _subscriptions;
  SubscriptionModel? get selectedSubscription => _selectedSubscription;


  List<UserModel> _users = [];
  List<UserModel> get users => _users;


  @override
  bool get isLoading => _isLoading;

  Future<void> fetchUsers() async {
    _isLoading = true;
    // notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      _users = snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
      logger.info('fetchUsers _users={}',[_users]);
    } catch (e) {
      logger.err('Error fetching users: {}', [e]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setUserId(String userId) async {
    _userId = userId;
    _isLoading = true;
   // notifyListeners();
    // notifyListeners();
    await fetchUserDetails();
    await fetchSubscriptions();
    logger.info('fetchData after setUserId is completed.');
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchUserDetails() async {
    try {
      if (_userId == null) {
        logger.err('User ID not set.');
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();
  logger.info('Fetching user details for user id={}',[_userId!]);
      if (doc.exists) {
        _user = UserModel.fromDocument(doc);
      }
    } catch (e) {
      logger.err('Error fetching user details: {}', [e]);
    }
  }

  Future<void> fetchSubscriptions() async {
    try {
      if (_userId == null) {
        logger.err('User ID not set.');
        return;
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

      _subscriptions = snapshot.docs
          .map((doc) => SubscriptionModel.fromDocument(doc))
          .toList();

      // Set selectedSubscription if it's null or not in the list
      if (_selectedSubscription == null ||
          !_subscriptions.contains(_selectedSubscription)) {
        _selectedSubscription = _subscriptions.isNotEmpty ? _subscriptions.first : null;
      }
    } catch (e) {
      logger.err('Error fetching subscriptions: {}', [e]);
    }
  }


  void setShowAllSubscriptions(bool value) {
    if (showAllSubscriptions != value) {
      showAllSubscriptions = value;
      _isLoading = true;
      notifyListeners();
      fetchSubscriptions().then((_) {
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  void selectSubscription(SubscriptionModel? subscription) {
    _selectedSubscription = subscription;
    notifyListeners();
  }
}
