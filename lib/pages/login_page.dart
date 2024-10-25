import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/usersAndAccount/reset_password_page.dart';
import 'admin_appointments_page.dart';
import 'appointments_page.dart';
import '../models/logger.dart';
import '../providers/login_manager.dart';
import '../usersAndAccount/admin_create_user_page.dart';
import 'admin_images_page.dart';
import 'file_handler_page.dart';
import 'meal_upload_page.dart';

final Logger logger = Logger.forClass(LoginPage);

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Future<String?> getCurrentSubscriptionId(String userId) async {
    final subscriptionsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('subscriptions');

    final querySnapshot = await subscriptionsCollection
        .where('status', isEqualTo: 'active')
        .orderBy('startDate', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      return doc.id;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
   // logger.info('Building LoginPage');

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
                loginProvider
                    .clearError(); // Clear the error after displaying it
              });
            }

            // Show either login form or main menu after login
            return loginProvider.isLoggedIn
                ? _buildHomePageContent(context) // Show main menu after login
                : _buildLoginForm(context, loginProvider, screenWidth,
                    isLoading); // Show login form if not logged in
          },
        ),
      ),
    );
  }

  // Build the login form
  Widget _buildLoginForm(BuildContext context, LoginProvider loginProvider,
      double screenWidth, bool isLoading) {
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
              MaterialPageRoute(
                  builder: (context) => const ResetPasswordPage()),
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
          onTap: () async {
            final userId = FirebaseAuth.instance.currentUser?.uid;

            if (userId == null) {
              if(!context.mounted)return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User not logged in')),
              );
              return;
            }

            final subscriptionId = await getCurrentSubscriptionId(userId);

            if (subscriptionId == null) {
              if(!context.mounted)return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No active subscription found')),
              );
              return;
            }
            if(!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MealUploadPage(
                  userId: userId,
                  subscriptionId: subscriptionId,
                ),
              ),
            );
          },
        ),
        // ListTile for "Randevu"
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Randevu'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppointmentsPage()),
          ),
        ),
        // ListTile for "Şifre Sıfırla"
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('Şifre Sıfırla'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
          ),
        ),
        // ListTile for "Admin Appointments"
        ListTile(
          leading: const Icon(Icons.assignment),
          title: const Text('Admin Appointments'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AdminAppointmentsPage()),
          ),
        ),
        // ListTile for "Admin Images"
        ListTile(
          leading: const Icon(Icons.image),
          title: const Text('Admin Images'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminImages()),
          ),
        ),
        // ListTile for "Admin Liste"
        ListTile(
          leading: const Icon(Icons.list),
          title: const Text('Admin Liste'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FileHandlerPage()),
          ),
        ),
        // ListTile for "Admin Kullanıcı oluştur"
        ListTile(
          leading: const Icon(Icons.person_add),
          title: const Text('Admin Kullanıcı oluştur'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateUserPage()),
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
