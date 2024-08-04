import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled/pages/home_page_after_login.dart';

import '../commons/logger.dart';

class LoginProvider extends ChangeNotifier {
  final Logger logger = Logger.forClass(LoginProvider);

  final String userNotFoundMessage = 'Kullanıcı adı bulunamadı.';
  final String wrongPasswordMessage =
      'Girdiğiniz şifre yanlış. Lütfen tekrar deneyiniz.';
  final String fieldsEmptyMsg = 'Lütfen alanları doldurunuz.';
  final String emailEmptyMsg = 'Kullanıcı adı kısmını lütfen doldurunuz.';
  final String pwEmptyMsg = 'Şifre kısmını lütfen doldurunuz.';

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading {
    logger.info('isLoading getter called, isLoading: $_isLoading');
    return _isLoading;
  }

  String get errorMessage {
    logger.info('errorMessage getter called, errorMessage: $_errorMessage');
    // String strTempErrMsg=StringBuffer(_errorMessage).toString();
    // _errorMessage='';
    // logger.info('errorMessage getter called, strTempErrMsg: $strTempErrMsg');
    return _errorMessage;
  }

  Future<void> login(BuildContext context) async {
    if (!_validateInputs()) {
      notifyListeners();
      return;
    }

    _setLoadingState(true);
    _errorMessage = '';
    notifyListeners();

    bool isLoginSuccessful = await signIn(
        emailController.text.trim(), passwordController.text.trim());
    isLoginSuccessful = true; //TODO
    if (isLoginSuccessful) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePageAfterLogin()),
        );
      }
    } else {
      notifyListeners();
    }

    _setLoadingState(false);
  }

  Future<bool> signIn(String email, String password) async {
    // const bool isProduction = bool.fromEnvironment('dart.vm.product');
    //
    // if (!isProduction) { //debug ortamındayım
    //   logger.debug(
    //       'signInAutomatically called with email: $email, password: $password');
    // } else {
    //   logger.info('signInAutomatically called with email: $email');
    // }
    logger.debug(
        'signInAutomatically called with email: $email, password: $password');
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _setError(userNotFoundMessage);
      } else if (e.code == 'wrong-password') {
        _setError(wrongPasswordMessage);
      } else {
        _setError('Giriş yaparken beklenmeyen bir hata oluştu.');
      }
      return false;
    } catch (e) {
      _setError('Giriş yaparken beklenmeyen bir hata oluştu.');
      return false;
    }
  }

  void _setLoadingState(bool isLoading) {
    _isLoading = isLoading;
    logger.info('Loading state changed: $_isLoading');
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  bool _validateInputs() {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _setError(fieldsEmptyMsg);
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
