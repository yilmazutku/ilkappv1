import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/logger.dart';
final Logger log = Logger.forClass(ChangePasswordPage);

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String _statusMessage = '';

  Future<void> reauthenticateAndChangePassword(String email, String currentPassword, String newPassword) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _statusMessage = 'No user is currently signed in.';
      });
      return;
    }

    try {
      // Re-authenticate the user
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      log.info('User re-authenticated successfully.');

      // Update the password
      await user.updatePassword(newPassword);
      log.info('Password updated successfully.');

      // Optionally, sign the user out and redirect to login page
      await FirebaseAuth.instance.signOut();
      log.info('User signed out. Redirect to login page.');

      setState(() {
        _statusMessage = 'Password updated successfully! Please log in again.';
      });

      // Here you would typically navigate to the login page.
      // Navigator.of(context).pushReplacementNamed('/login');

    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to update password: $e';
      });
      log.info('Failed to update password: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              controller: _currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Enter Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              decoration: const InputDecoration(
                labelText: 'Enter New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final email = _emailController.text.trim();
                final currentPassword = _currentPasswordController.text.trim();
                final newPassword = _newPasswordController.text.trim();
                final confirmPassword = _confirmPasswordController.text.trim();

                if (email.isEmpty || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
                  setState(() {
                    _statusMessage = 'Please fill in all fields.';
                  });
                  return;
                }

                if (newPassword != confirmPassword) {
                  setState(() {
                    _statusMessage = 'New passwords do not match.';
                  });
                  return;
                }

                await reauthenticateAndChangePassword(email, currentPassword, newPassword);
              },
              child: const Text('Change Password'),
            ),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              style: TextStyle(
                color: _statusMessage.contains('successfully') ? Colors.green : Colors.red,
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
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
