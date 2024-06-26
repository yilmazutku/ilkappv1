import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'main.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false; // Indicates loading state
  String _errorMessage = ''; // Error message for wrong credentials

  // Local variables for error messages
  final String userNotFoundMessage = 'Kullanıcı adı bulunamadı.';
  final String wrongPasswordMessage = 'Girdiğiniz şifre yanlış. Lütfen tekrar deneyiniz.';
  final String fieldsEmptyMsg = 'Lütfen alanları doldurunuz.';
  final String emailEmptyMsg = 'Kullanıcı adı kısmını lütfen doldurunuz.';
  final String pwEmptyMsg = 'Şifre kısmını lütfen doldurunuz.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter your password',
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              // Disable button when loading
              child: _isLoading
                  ? CircularProgressIndicator() // Show loading indicator
                  : Text('Login'),
            ),
            if (_errorMessage.isNotEmpty) // Show error message if not empty
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true; // Start loading
      _errorMessage = ''; // Reset error message
    });

    bool isLoginSuccessful = await signInAutomatically(
        _emailController.value, _passwordController.value);
    setState(() {});
    if (!isLoginSuccessful) {
      setState(() {
      //  _errorMessage = 'Invalid email or password.'; // Set custom error message
      });
    }
    if (isLoginSuccessful) {


      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomePageAfterLogin()));
    }

    setState(() {
      _isLoading = false; // Stop loading
    });
  }

  Future<bool> signInAutomatically(
      TextEditingValue email, TextEditingValue pw) async {
    if (email.text.isEmpty && pw.text.isEmpty) {
      print(fieldsEmptyMsg);
      _errorMessage = fieldsEmptyMsg;
      return false;
    }
    if (email.text.isEmpty) {
      print(emailEmptyMsg);
      _errorMessage = emailEmptyMsg;
      return false;
    } else if (pw.text.isEmpty) {
      print(pwEmptyMsg);
      _errorMessage = pwEmptyMsg;
      return false;
    } else {
      try {
        var instance = FirebaseAuth.instance;
        UserCredential userCredential =
            await instance.signInWithEmailAndPassword(
          email: email.text,
          password: pw.text,
        );
        print('Signed in with email: ${userCredential.user?.email}');
        return true;
      } on FirebaseAuthException catch (e) {
        String errMsg = e.code == 'user-not-found'
            ? userNotFoundMessage
            : wrongPasswordMessage;
        _errorMessage = errMsg;
        print(errMsg);
        return false;
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
