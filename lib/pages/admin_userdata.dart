import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

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
    String userPath = 'userinfo/$username';
    final salt = generateSalt();
    final hashedPassword = hashPassword(password, salt);

    try {
      // Create user document with username, email, hashed password, and salt
      await _firestore.collection('userinfo').doc(username).set({
        'username': username,
        'email': email,
        'hashedpw': hashedPassword,
        'saltkey': salt,
      });

      // Create dietlists subcollection
      await _firestore.collection('$userPath/dietlists').add({
        'initialDiet': [],
      });

      setState(() {
        _statusMessage = 'User $username created successfully!';
      });
    } catch (e) {
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
