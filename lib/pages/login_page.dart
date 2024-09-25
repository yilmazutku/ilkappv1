import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/usersAndAccount/reset_password_page.dart';
import '../appointments/appointments_page.dart';
import '../commons/logger.dart';
import '../managers/login_manager.dart';
import 'meal_upload_page.dart';

final Logger logger = Logger.forClass(LoginPage);

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    logger.info('Building LoginPage');

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

            // Display error dialog if there is an error
            if (errorMessage.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showErrorDialog(context, errorMessage);
                loginProvider.clearError(); // Clear the error after displaying it
              });
            }

            // Show either login form or main menu after login
            return loginProvider.isLoggedIn
                ? _buildHomePageContent(context) // Show main menu after login
                : _buildLoginForm(context, loginProvider, screenWidth, isLoading); // Show login form if not logged in
          },
        ),
      ),
    );
  }

  // Build the login form
  Widget _buildLoginForm(BuildContext context, LoginProvider loginProvider, double screenWidth, bool isLoading) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Email input
        Center(
          child: SizedBox(
            width: screenWidth * 0.5,
            child: TextField(
              controller: loginProvider.emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Emailinizi giriniz',
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Password input
        Center(
          child: SizedBox(
            width: screenWidth * 0.5,
            child: TextField(
              controller: loginProvider.passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Şifrenizi giriniz',
                labelText: 'Şifre',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: isLoading ? null : () => loginProvider.login(context),
          child: isLoading
              ? const CircularProgressIndicator()
              : const Text('Giriş Yap'),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
            );
          },
          child: const Text('Şifremi Unuttum'),
        ),
      ],
    );
  }

  // Build the main menu after login
  Widget _buildHomePageContent(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
          ),
          child: const Text(
            'Menu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.food_bank),
          title: const Text('Planım'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MealUploadPage()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Randevu'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppointmentsPage()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('Şifre Sıfırla'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
          ),
        ),
        // Add other ListTile entries here as needed...
      ],
    );
  }

  // Show error dialog
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
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }
}
