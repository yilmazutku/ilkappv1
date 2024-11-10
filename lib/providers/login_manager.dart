import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/logger.dart';
final Logger logger = Logger.forClass(LoginProvider);

class LoginProvider extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Login function
  Future<bool> login(BuildContext context) async {
    //TODO gerçek logine çevirmek icin comemnten çıkar
    // if (!_validateInputs()) {
    //   notifyListeners();
    //   return false;
    // }

    _setLoadingState(true);
    _errorMessage = '';

    bool isLoginSuccessful = await _signIn(
        emailController.text.trim(), passwordController.text.trim());

    if (isLoginSuccessful) {
      _isLoggedIn = true;
    }

    _setLoadingState(false);
    notifyListeners();
    return isLoginSuccessful;
  }

  // Sign-in function
  Future<bool> _signIn(String email, String password) async {
    try {
      //TODO gerçek logine çevirmek icin comemnte al 2.yi birinciyi de çıkar
      // await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: 'utkuyy97@gmail.com', password: '612009');
      return true;
    } on FirebaseAuthException catch (e) {
      _handleFirebaseAuthError(e);
      return false;
    } catch (_) {
      _errorMessage = 'Beklenmeyen bir hata oluştu.';
      return false;
    }
return true;  }

  // Handle Firebase errors
  void _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        _errorMessage = 'Geçersiz e-posta adresi.';
        break;
      case 'user-disabled':
        _errorMessage = 'Bu kullanıcı hesabı devre dışı bırakılmış.';
        break;
      case 'user-not-found':
        _errorMessage = 'Kullanıcı adı bulunamadı.';
        break;
      case 'wrong-password':
        _errorMessage = 'Girdiğiniz şifre yanlış. Lütfen tekrar deneyiniz.';
        break;
      default:
        _errorMessage = 'Giriş yaparken beklenmeyen bir hata oluştu.';
        break;
    }
    logger.err('firebase auth err:{}',[e.code]);
    notifyListeners();
  }

  // Clear the error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Input validation
  bool _validateInputs() {
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      _errorMessage = 'Lütfen alanları doldurunuz.';
      return false;
    }
    return true;
  }

  // Set loading state
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
