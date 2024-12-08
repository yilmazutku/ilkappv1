import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:untitled/main.dart';

import '../models/logger.dart';
import '../models/subs_model.dart';
import '../models/user_model.dart';
import '../pages/admin_create_user_page.dart';

final Logger logger = Logger.forClass(UserProvider);

class UserProvider extends ChangeNotifier {
  static final UserProvider _userProvider = UserProvider._internal();
  static final List<String> collections = ['subscriptions', 'appointments', 'dietlists', 'dailyData', 'meals', 'payments'];

  factory UserProvider() => _userProvider;
  UserProvider._internal();

  String? _userId;
  String? get userId => _userId;

  void setUserId(String userId) {
    _userId = userId;
  }

  /// Fetch User Details
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

  /// Update User Details if Email Not Changed
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

  /// Update Email and Migrate Data
  Future<bool> updateEmailAndMigrate({
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
        return false;
      }

      // Step 1: Migrate Firestore data
      final newUid = await _migrateUserDataAndRecreateAuth(
        oldUid: oldUid,
        newEmail: newEmail,
        password: password,
        updatedUser: updatedUser,
      );

      if (newUid == null) {
        logger.err('updateEmailAndMigrate: Data migration or user creation failed.');
        return false;
      }
      /// Silinen kullanıcı, geçici şifreye sahip olmalı. yoksa çalışmaz!!!
      try {
        final oldUser = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: oldEmail,
          password: CreateUserPage.tempPw,
        );
        await oldUser.user?.delete();
        logger.info('Deleted the old user and Successfully updated email and migrated data for oldUid={}', [oldUid]);
      } on Exception catch (e) {
       logger.err('Exception occurred when trying to delete the old user from authentication. {}',[e]);
      }
      await signInAutomatically(); ///TEKRAR ADMIN OLARAK GIRIS YAP

      // Step 2: Delete old Firestore document
      await FirebaseFirestore.instance.collection('users').doc(oldUid).delete();
      logger.info('Deleted old Firestore user document for UID={}', [oldUid]);

      // Update the provider state
      setUserId(newUid);
      notifyListeners();
      return true;
    } catch (e) {
      logger.err('updateEmailAndMigrate: Error during email update and migration: {}', [e]);
      return false;
    }
  }

  /// Migrate Firestore Data and Recreate Auth User
  Future<String?> _migrateUserDataAndRecreateAuth({
    required String oldUid,
    required String newEmail,
    required String password,
    required UserModel updatedUser,
  }) async {
    try {
      // Generate new UID for the user
      final newUid = FirebaseFirestore.instance.collection('users').doc().id;

      // Step 1: Migrate Firestore Data
      await _migrateUserData(oldUid, newUid);

      // Step 2: Create new Firebase Authentication user
      UserCredential newUserCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: newEmail,
        password: password,
      );

      if (newUserCred.user == null) {
        logger.err('Failed to create new Firebase user with email={}', [newEmail]);
        return null;
      }

      // Step 3: Update Firestore Document with new UID
      final updatedUserMap = updatedUser.toMap();
      updatedUserMap['userId'] = newUid;
      await FirebaseFirestore.instance.collection('users').doc(newUid).set(updatedUserMap);

      return newUid;
    } catch (e) {
      logger.err('Error during Firestore data migration and user recreation: {}', [e]);
      return null;
    }
  }

  /// Migrate Top-Level and Subcollections
  Future<void> _migrateUserData(String oldUid, String newUid) async {
    final oldDocRef = FirebaseFirestore.instance.collection('users').doc(oldUid);
    final newDocRef = FirebaseFirestore.instance.collection('users').doc(newUid);

    // Step 1: Migrate Top-Level Data
    final oldDataSnapshot = await oldDocRef.get();
    if (oldDataSnapshot.exists) {
      final userData = oldDataSnapshot.data();
      if (userData != null) {
        userData['userId'] = newUid; // Update UID
        await newDocRef.set(userData, SetOptions(merge: true));
        logger.info('Top-level data migrated from oldUid={} to newUid={}', [oldUid, newUid]);
      }
    }

    // Step 2: Migrate Subcollections
    await _migrateSubcollections(oldDocRef, newDocRef);
  }

  /// Migrate Subcollections
  Future<void> _migrateSubcollections(DocumentReference oldDocRef, DocumentReference newDocRef) async {
    for (String subcollectionName in collections) {
      final oldSubcollectionRef = oldDocRef.collection(subcollectionName);
      final querySnapshot = await oldSubcollectionRef.get();

      for (final doc in querySnapshot.docs) {
        final newDocRefSub = newDocRef.collection(subcollectionName).doc(doc.id);
        await newDocRefSub.set(doc.data());
        logger.info('Migrated document id={} in subcollection={} for newUid={}', [doc.id, subcollectionName, newDocRef.id]);
      }
    }
  }

  /// Fetch Subscriptions
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

  /// Fetch All Users
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
