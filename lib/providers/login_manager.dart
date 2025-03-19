import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/logger.dart';

final Logger logger = Logger.forClass(LoginProvider);

///TODO: mail/şifre yanlış girince defaulta düşüyor. login methodu commentler yer değiştirmeli uncommented yerlerle
class LoginProvider extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  /// Attempts to log in with the provided email and password.
  Future<bool> login(BuildContext context) async {
    // if (!_validateInputs()) {
    //   notifyListeners();
    //   return false;
    // }

    _setLoadingState(true);
    _errorMessage = '';

    bool isLoginSuccessful = await _signIn(
       'utkuyy97@gmail.com',
        '612009'
      // emailController.text.trim(),
      //passwordController.text.trim(),
    );

    _setLoadingState(false);
    notifyListeners();
    return isLoginSuccessful;
  }

  /// Signs in using Firebase Authentication.
  Future<bool> _signIn(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _handleFirebaseAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = 'Beklenmeyen bir hata oluştu.';
      logger.err('Unexpected error during sign-in: {}', [e.toString()]);
      return false;
    }
  }

  /// Handles Firebase Authentication errors and sets appropriate error messages.
  void _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        _errorMessage = 'Geçersiz e-posta adresi.';
        break;
      case 'user-disabled':
        _errorMessage = 'Bu kullanıcı hesabı devre dışı bırakılmış.';
        break;
      case 'user-not-found':
        _errorMessage = 'Kullanıcı bulunamadı.';
        break;
      case 'wrong-password':
        _errorMessage = 'Girdiğiniz şifre yanlış. Lütfen tekrar deneyiniz.';
        break;
      default:
        _errorMessage = 'Giriş yaparken beklenmeyen bir hata oluştu. Lütfen mailinizi ve şifrenizi kontrol ediniz.';
        break;
    }
    logger.err('Firebase auth error: {}', [e.code]);
    notifyListeners();
  }

  /// Clears the error message.
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  /// Validates that email and password fields are not empty.
  bool _validateInputs() {
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      _errorMessage = 'Lütfen alanları doldurunuz.';
      return false;
    }
    return true;
  }

  /// Updates the loading state and notifies listeners.
  void _setLoadingState(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}