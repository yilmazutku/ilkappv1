import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled/pages/home_page_after_login.dart';
class LoginProvider extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  final String userNotFoundMessage = 'Kullanıcı adı bulunamadı.';
  final String wrongPasswordMessage = 'Girdiğiniz şifre yanlış. Lütfen tekrar deneyiniz.';
  final String fieldsEmptyMsg = 'Lütfen alanları doldurunuz.';
  final String emailEmptyMsg = 'Kullanıcı adı kısmını lütfen doldurunuz.';
  final String pwEmptyMsg = 'Şifre kısmını lütfen doldurunuz.';

  Future<void> login(BuildContext context) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    bool isLoginSuccessful = await signInAutomatically(
        emailController.value, passwordController.value);
    isLoginSuccessful=true;
    if (!isLoginSuccessful) {
      notifyListeners();
    }
    else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomePageAfterLogin()));
    }
  //TODO: bu loading'in get yapildigi yerde true false bakıyor, true iken buraya tekrar getirtip durumu konttol et. sanırım hala giriş yapılmaya çalışılıyorken tekrar logine basınca bu durum gerçekleşebilir.
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signInAutomatically(
      TextEditingValue email, TextEditingValue pw) async {
    if (email.text.isEmpty && pw.text.isEmpty) {
      _errorMessage = fieldsEmptyMsg;
      return false;
    }
    if (email.text.isEmpty) {
      _errorMessage = emailEmptyMsg;
      return false;
    } else if (pw.text.isEmpty) {
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
        return true;
      } on FirebaseAuthException catch (e) {
        _errorMessage = e.code == 'user-not-found'
            ? userNotFoundMessage
            : wrongPasswordMessage;
        return false;
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
