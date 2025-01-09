// login_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/pages/meas_page.dart';
import 'package:untitled/pages/reset_password_page.dart';
import 'package:untitled/pages/user_past_appointments_page.dart';
import 'package:untitled/pages/user_payments_page.dart';
import 'admin_appointments_page.dart';
import 'admin_timeslots_page.dart';
import 'appointments_page.dart';
import '../models/logger.dart';
import '../providers/login_manager.dart';
import 'admin_create_user_page.dart';
import 'admin_images_page.dart';
import '../diet_list_pages/file_handler_page.dart';
import 'meal_upload_page.dart';

final Logger logger = Logger.forClass(LoginPage);

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Future<String?> getCurrentSubscriptionId(String userId) async {
    logger.info('getting sub id for user with userId={}', [userId]);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Girişi'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Consumer<LoginProvider>(
          builder: (context, loginProvider, child) {
            String errorMessage = loginProvider.errorMessage;
            bool isLoading = loginProvider.isLoading;

            if (errorMessage.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showErrorDialog(context, errorMessage);
                loginProvider.clearError();
              });
            }

            return loginProvider.isLoggedIn
                ? _buildHomePageContent(context)
                : _buildLoginForm(context, loginProvider, screenWidth, isLoading);
          },
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, LoginProvider loginProvider,
      double screenWidth, bool isLoading) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: screenWidth * 0.7,
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
        const SizedBox(height: 10),
        SizedBox(
          width: screenWidth * 0.7,
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
                  builder: (context) => const ResetPasswordPage(email: '')),
            );
          },
          child: const Text('Şifremi Unuttum'),
        ),
      ],
    );
  }

  Widget _buildHomePageContent(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(2.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _buildGridItem(context, Icons.food_bank, 'Planım', () => _navigateToMeal(context)),
            _buildGridItem(context, Icons.food_bank, 'Meas', () => _navigateToMeas(context)),
            _buildGridItem(context, Icons.calendar_today, 'Geçmiş Randevularım',
                    () => _navigateToPastAppointments(context)),
            _buildGridItem(context, Icons.payments, 'Ödemelerim',
                    () => _navigateToPayments(context)),
            _buildGridItem(context, Icons.timeline, 'Admin Timeslots',
                    () => _navigateToAdminTimeSlots(context)),
            _buildGridItem(context, Icons.event, 'Randevu',
                    () => _navigateToAppointments(context)),
            _buildGridItem(context, Icons.lock, 'Şifre Sıfırla',
                    () => _navigateToResetPassword(context)),
            _buildGridItem(context, Icons.assignment, 'Admin Appointments',
                    () => _navigateToAdminAppointments(context)),
            _buildGridItem(context, Icons.image, 'Admin Images',
                    () => _navigateToAdminImages(context)),
            _buildGridItem(context, Icons.list, 'Admin Liste',
                    () => _navigateToFileHandler(context)),
            _buildGridItem(context, Icons.person_add, 'Admin Kullanıcı Oluştur',
                    () => _navigateToCreateUser(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToMeas(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final subscriptionId = await getCurrentSubscriptionId(userId);
    if (subscriptionId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MeasurementPage(

        ),
      ),
    );
  }

  Future<void> _navigateToMeal(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final subscriptionId = await getCurrentSubscriptionId(userId);
    if (subscriptionId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealUploadPage(
          userId: userId,
          subscriptionId: subscriptionId,
        ),
      ),
    );
  }

  void _navigateToPastAppointments(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PastAppointmentsPage(userId: userId),
      ),
    );
  }

  void _navigateToPayments(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserPaymentsPage(userId: userId),
      ),
    );
  }

  void _navigateToAdminTimeSlots(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminTimeSlotsPage(),
      ),
    );
  }

  Future<void> _navigateToAppointments(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final subscriptionId = await getCurrentSubscriptionId(userId);
    if (subscriptionId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentsPage(
          userId: userId,
          subscriptionId: subscriptionId,
        ),
      ),
    );
  }

  void _navigateToResetPassword(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResetPasswordPage(email: email),
      ),
    );
  }

  void _navigateToAdminAppointments(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminAppointmentsPage(),
      ),
    );
  }

  void _navigateToAdminImages(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminImages(),
      ),
    );
  }

  void _navigateToFileHandler(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FileHandlerPage(),
      ),
    );
  }

  void _navigateToCreateUser(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateUserPage(),
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
                Navigator.of(context).pop();
              },
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }
}
