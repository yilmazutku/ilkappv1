import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/logger.dart';
import '../pages/login_page.dart';

final Logger logger = Logger.forClass(ResetPasswordPage);

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Enter your email',
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendPasswordResetEmail,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Send Reset Link'),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendPasswordResetEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    String email = _emailController.text;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      logger.info('Sent passwordResetEmail to:{}', [email]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifre sıfırlama linki gönderildi!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  const LoginPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      logger.err('Error when sending passwordResetEmail to:{}, err={}',
          [email, e.message!]);
      if (mounted) {
        setState(() {
          _errorMessage =
              'Bir hata oluştu. Lütfen girdiğiniz mail adresini kontrol ediniz.'; //e.message ?? 'Bir hata oluştu.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
