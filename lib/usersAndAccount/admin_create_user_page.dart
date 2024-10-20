import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../commons/logger.dart';
import '../models/subs_model.dart';
import '../models/user_model.dart';
final Logger logger = Logger.forClass(CreateUserPage);
class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _statusMessage = '';

  String generateSalt([int length = 16]) {
    final random = Random.secure();
    final salt = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Url.encode(salt);
  }

  String hashPassword(String password, String salt) {
    final saltedPassword = password + salt;
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> createUser(String username, String email, String password) async {
    final salt = generateSalt();
    final hashedPassword = hashPassword(password, salt);

    try {
      // Create user with Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final userId = userCredential.user?.uid;

      if (userId == null) {
        throw Exception('User creation failed: userId is null.');
      }

      // Create UserModel instance
      final newUser = UserModel(
        userId: userId,
        name: username,
        email: email,
        role: 'customer', // Default role for new users
        createdAt: DateTime.now(),
      );

      // Store user data in Firestore
      await _firestore.collection('users').doc(userId).set(newUser.toMap());

      // Create a default SubscriptionModel instance with a dummy package
      final defaultSubscription = SubscriptionModel(
        subscriptionId: _firestore.collection('subscriptions').doc().id,
        userId: userId,
        packageName: 'temporary_package', // Dummy package
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: 30)), // Example: 30 days trial
        totalMeetings: 10,
        meetingsRemaining: 10,
        totalAmount: 0.0,
      );

      // Store subscription data in Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('subscriptions')
          .doc(defaultSubscription.subscriptionId)
          .set(defaultSubscription.toMap());

      setState(() {
        _statusMessage = 'User $username created successfully!';
      });
      logger.info('User created: {}.',[newUser,defaultSubscription]) ;
    } catch (e) {
      logger.err('Failed to create user: {}',[e]);
      setState(() {
        _statusMessage = 'Failed to create user: $e';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New User'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Enter Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Enter Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Enter Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final username = _usernameController.text.trim();
                final email = _emailController.text.trim();
                final password = _passwordController.text.trim();

                if (username.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
                  createUser(username, email, password);
                } else {
                  setState(() {
                    _statusMessage = 'Please fill in all fields.';
                  });
                }
              },
              child: const Text('Create User'),
            ),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              style: TextStyle(
                color: _statusMessage.startsWith('Failed') ? Colors.red : Colors.green,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
