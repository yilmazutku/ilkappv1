// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'home_page_after_login.dart';
//
// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});
//
//   @override
//   _LoginPageState createState() => _LoginPageState();
// }
//
// class _LoginPageState extends State<LoginPage> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   bool _isLoading = false; // Indicates loading state
//   String _errorMessage = ''; // Error message for wrong credentials
//
//   // Local variables for error messages
//   final String userNotFoundMessage = 'Kullanıcı adı bulunamadı.';
//   final String wrongPasswordMessage = 'Girdiğiniz şifre yanlış. Lütfen tekrar deneyiniz.';
//   final String fieldsEmptyMsg = 'Lütfen alanları doldurunuz.';
//   final String emailEmptyMsg = 'Kullanıcı adı kısmını lütfen doldurunuz.';
//   final String pwEmptyMsg = 'Şifre kısmını lütfen doldurunuz.';
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Login Page'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             TextField(
//               controller: _emailController,
//               keyboardType: TextInputType.emailAddress,
//               decoration: const InputDecoration(
//                 hintText: 'Enter your email',
//                 labelText: 'Email',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 20),
//             TextField(
//               controller: _passwordController,
//               obscureText: true,
//               decoration: const InputDecoration(
//                 hintText: 'Enter your password',
//                 labelText: 'Password',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _isLoading ? null : _login,
//               // Disable button when loading
//               child: _isLoading
//                   ? const CircularProgressIndicator() // Show loading indicator
//                   : const Text('Login'),
//             ),
//             if (_errorMessage.isNotEmpty) // Show error message if not empty
//               Padding(
//                 padding: const EdgeInsets.only(top: 20),
//                 child: Text(
//                   _errorMessage,
//                   style: const TextStyle(color: Colors.red, fontSize: 16),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> _login() async {
//     setState(() {
//       _isLoading = true; // Start loading
//       _errorMessage = ''; // Reset error message
//     });
//
//     bool isLoginSuccessful = await signInAutomatically(
//         _emailController.value, _passwordController.value);
//     setState(() {});
//     if (!isLoginSuccessful) {
//       setState(() {
//       //  _errorMessage = 'Invalid email or password.'; // Set custom error message
//       });
//     }
//     if (isLoginSuccessful) {
//
//
//       Navigator.pushReplacement(
//           context, MaterialPageRoute(builder: (context) => const HomePageAfterLogin()));
//     }
//
//     setState(() {
//       _isLoading = false; // Stop loading
//     });
//   }
//
//   Future<bool> signInAutomatically(
//       TextEditingValue email, TextEditingValue pw) async {
//     if (email.text.isEmpty && pw.text.isEmpty) {
//       print(fieldsEmptyMsg);
//       _errorMessage = fieldsEmptyMsg;
//       return false;
//     }
//     if (email.text.isEmpty) {
//       print(emailEmptyMsg);
//       _errorMessage = emailEmptyMsg;
//       return false;
//     } else if (pw.text.isEmpty) {
//       print(pwEmptyMsg);
//       _errorMessage = pwEmptyMsg;
//       return false;
//     } else {
//       try {
//         var instance = FirebaseAuth.instance;
//         UserCredential userCredential =
//             await instance.signInWithEmailAndPassword(
//           email: email.text,
//           password: pw.text,
//         );
//         print('Signed in with email: ${userCredential.user?.email}');
//         return true;
//       } on FirebaseAuthException catch (e) {
//         String errMsg = e.code == 'user-not-found'
//             ? userNotFoundMessage
//             : wrongPasswordMessage;
//         _errorMessage = errMsg;
//         print(errMsg);
//         return false;
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../commons/logger.dart';
import '../managers/login_manager.dart';

final Logger logger = Logger.forClass(LoginPage);
class LoginPage extends StatelessWidget {


  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    logger.info('building loginPage');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Consumer<LoginProvider>(
          builder: (context, loginProvider, child) {
            String errorMessage = loginProvider.errorMessage;
            bool isLoading = loginProvider.isLoading;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextField(
                  controller: loginProvider.emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Enter your email',
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: loginProvider.passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Enter your password',
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : () => loginProvider.login(context),
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Login'),
                ),

                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 16), //TODO ileride yeni login yapılmamışsa oncekinin errorunu silmek isteyebiliriz?
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
