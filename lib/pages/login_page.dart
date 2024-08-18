import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/pages/reset_password_page.dart';

import '../commons/logger.dart';
import '../managers/login_manager.dart';

final Logger logger = Logger.forClass(LoginPage);

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    logger.info('building loginPage');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıc\u0131 Girişi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Consumer<LoginProvider>(
          builder: (context, loginProvider, child) {
            String errorMessage = loginProvider.errorMessage;
            bool isLoading = loginProvider.isLoading;
            if (errorMessage.isNotEmpty) {
              // hata varsa dialog aç
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showErrorDialog(context, errorMessage);
                loginProvider.setError(''); // Reset the error after displaying
              });
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: SizedBox(
                    width: screenWidth * 0.5, // Set your desired width here
                    child: TextField(
                      // mail giriş
                      controller: loginProvider.emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Enter your email',
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: SizedBox(
                    //pw giriş
                    width: screenWidth * 0.5,
                    child: TextField(
                      controller: loginProvider.passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Enter your password',
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed:
                      isLoading ? null : () => loginProvider.login(context),
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Login'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ResetPasswordPage()),
                    );
                  },
                  child: const Text('Forgot Password?'),
                ),
                // if (errorMessage.isNotEmpty)
                //   Padding(
                //     padding: const EdgeInsets.only(top: 10),
                //     child: Text(
                //       errorMessage,
                //       style: const TextStyle(color: Colors.red, fontSize: 16), //TODO ileride yeni login yapılmamışsa oncekinin errorunu silmek isteyebiliriz?
                //     ),
                //   ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hata'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
