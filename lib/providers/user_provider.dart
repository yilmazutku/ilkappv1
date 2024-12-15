// user_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/logger.dart';
import '../models/subs_model.dart';
import '../models/user_model.dart';
import '../pages/admin_create_user_page.dart';

final Logger logger = Logger.forClass(UserProvider);

class UserProvider extends ChangeNotifier {
  static final List<String> collections = [
    'subscriptions', 'appointments', 'dietlists', 'dailyData', 'meals', 'payments'
  ];

  String? _userId;
  String? get userId => _userId;

  void setUserId(String userId) {
    _userId = userId;
    notifyListeners();
  }

  Future<UserModel?> fetchUserDetails() async {
    try {
      if (_userId == null) {
        logger.err('fetchUserDetails: User ID not set.');
        return null;
      }
      final doc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
      logger.info('Fetching user details for userId={}', [_userId!]);

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

  Future<bool> updateUserDetails(UserModel updatedUser) async {
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(updatedUser.userId);
      await userDoc.update(updatedUser.toMap());
      logger.info('User details updated successfully for userId={}', [updatedUser.userId]);
      notifyListeners();
      return true;
    } catch (e) {
      logger.err('Error updating user details for userId={}: {}', [updatedUser.userId, e]);
      return false;
    }
  }

  Future<String?> updateEmailAndMigrate({
    required String oldUid,
    required String oldEmail,
    required String password,
    required String newEmail,
    required UserModel updatedUser,
  }) async {
    try {
      final adminUser = FirebaseAuth.instance.currentUser;
      if (adminUser == null) {
        logger.err('updateEmailAndMigrate: Admin is not signed in.');
        return null;
      }

      final newUid = await _migrateUserDataAndRecreateAuth(
        oldUid: oldUid,
        newEmail: newEmail,
        password: password,
        updatedUser: updatedUser,
      );

      if (newUid == null) {
        logger.err('updateEmailAndMigrate: Data migration or user creation failed.');
        return null;
      }

      try {
        final oldUser = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: oldEmail,
          password: CreateUserPage.tempPw,
        );
        await oldUser.user?.delete();
        logger.info('Deleted the old user and Successfully updated email and migrated data for oldUid={}', [oldUid]);
      } on Exception catch (e) {
        logger.err('Exception when deleting old user: {}', [e]);
      }

      await signInAutomatically();

      await FirebaseFirestore.instance.collection('users').doc(oldUid).delete();
      logger.info('Deleted old Firestore user document for UID={}', [oldUid]);

      setUserId(newUid);
      return newUid;
    } catch (e) {
      logger.err('updateEmailAndMigrate: Error during email update and migration: {}', [e]);
      return null;
    }
  }

  Future<String?> _migrateUserDataAndRecreateAuth({
    required String oldUid,
    required String newEmail,
    required String password,
    required UserModel updatedUser,
  }) async {
    try {
      final newUid = FirebaseFirestore.instance.collection('users').doc().id;

      await _migrateUserData(oldUid, newUid);

      UserCredential newUserCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: newEmail,
        password: password,
      );

      if (newUserCred.user == null) {
        logger.err('Failed to create new Firebase user with email={}', [newEmail]);
        return null;
      }

      final updatedUserMap = updatedUser.toMap();
      updatedUserMap['userId'] = newUid;
      await FirebaseFirestore.instance.collection('users').doc(newUid).set(updatedUserMap);

      return newUid;
    } catch (e) {
      logger.err('Error during data migration and user recreation: {}', [e]);
      return null;
    }
  }

  Future<void> _migrateUserData(String oldUid, String newUid) async {
    final oldDocRef = FirebaseFirestore.instance.collection('users').doc(oldUid);
    final newDocRef = FirebaseFirestore.instance.collection('users').doc(newUid);

    final oldDataSnapshot = await oldDocRef.get();
    if (oldDataSnapshot.exists) {
      final userData = oldDataSnapshot.data();
      if (userData != null) {
        userData['userId'] = newUid;
        await newDocRef.set(userData, SetOptions(merge: true));
        logger.info('Top-level data migrated from oldUid={} to newUid={}', [oldUid, newUid]);
      }
    }

    await _migrateSubcollections(oldDocRef, newDocRef);
  }

  Future<void> _migrateSubcollections(DocumentReference oldDocRef, DocumentReference newDocRef) async {
    for (String subcollectionName in collections) {
      final oldSubcollectionRef = oldDocRef.collection(subcollectionName);
      final querySnapshot = await oldSubcollectionRef.get();

      for (final doc in querySnapshot.docs) {
        final newDocRefSub = newDocRef.collection(subcollectionName).doc(doc.id);
        await newDocRefSub.set(doc.data());
        logger.info('Migrated doc id={} in subcollection={} for newUid={}', [doc.id, subcollectionName, newDocRef.id]);
      }
    }
  }

  Future<void> signInAutomatically() async {
    // Re-sign in the admin user if needed
    // Implementation depends on how you handle admin authentication.
  }

  Future<List<SubscriptionModel>> fetchSubscriptions({required bool showAllSubscriptions}) async {
    try {
      if (_userId == null) {
        logger.err('fetchSubscriptions: User ID not set.');
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
      return snapshot.docs.map((doc) => SubscriptionModel.fromDocument(doc)).toList();
    } catch (e) {
      logger.err('Error fetching subscriptions: {}', [e]);
      return [];
    }
  }

  Future<List<UserModel>> fetchUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      List<UserModel> users = snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
      logger.info('Fetched users: {}', [users]);
      return users;
    } catch (e) {
      logger.err('Error fetching users: {}', [e]);
      return [];
    }
  }
}
