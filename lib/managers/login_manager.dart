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

  Future<bool> login(BuildContext context) async {
    if (!_validateInputs()) {
      notifyListeners();
      return false;
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
      if (context.mounted) {
        //page kısmında TODO
      }
    }
    _setLoadingState(false);
    return isLoginSuccessful;
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
      switch (e.code) {
        case 'invalid-email':
          setError('Geçersiz e-posta adresi.');
          break;
        case 'user-disabled':
          setError('Bu kullanıcı hesabı devre dışı bırakılmış.');
          break;
        case 'user-not-found':
          setError('Kullanıcı adı bulunamadı.');
          break;
        case 'wrong-password':
          setError('Girdiğiniz şifre yanlış. Lütfen tekrar deneyiniz.');
          break;
        case 'account-exists-with-different-credential':
          setError(
              'Bu e-posta adresiyle daha önce farklı bir yöntemle giriş yapılmış.');
          break;
        case 'credential-already-in-use':
          setError(
              'Bu kimlik bilgileri zaten başka bir kullanıcı tarafından kullanılıyor.');
          break;
        case 'operation-not-allowed':
          setError('Bu işlem şu anda yapılamıyor.');
          break;
        case 'invalid-credential':
          setError(
              'Girilen e-mail adresi ve/veya şifre hatalı. Lütfen kontrol edip tekrar deneyiniz.'); //Sağlanan kimlik bilgileri yanlış, hatalı veya süresi dolmuş.
          break;
        default:
          setError(
              'FirebaseAuthException: Giriş yaparken beklenmeyen bir hata oluştu.');
          break;
      }
      return false;
    } catch (e) {
      setError('Giriş yaparken beklenmeyen bir hata oluştu.');
      return false;
    }
  }

  void _setLoadingState(bool isLoading) {
    _isLoading = isLoading;
    logger.info('Loading state changed: $_isLoading');
    notifyListeners();
  }

  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  bool _validateInputs() {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      setError(fieldsEmptyMsg);
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
