import 'package:flutter/material.dart';

import '../commons/logger.dart';
import 'admin_appointments_page.dart';
import 'admin_images_page.dart';
import 'booking_page.dart';
import 'chat_page.dart';
import 'meal_upload_page.dart';

final Logger logger = Logger.forClass(HomePageAfterLogin);

class HomePageAfterLogin extends StatelessWidget {
  const HomePageAfterLogin({super.key});

  @override
  Widget build(BuildContext context) {
    logger.info('Building HomePage...');
    // if(FirebaseAuth.instance.currentUser?.uid=='mChhGVRpH1PBAonozPiEitDm5pE2') {
    // }
    // else {
    return Scaffold(
      appBar:
      AppBar(title: const Text('Trial App v0')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: const Text('My Plan'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MealUploadPage()),
              ),
            ),
            ElevatedButton(
              child: const Text('Chat with Admin'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatPage()),
              ),
            ),
            ElevatedButton(
              child: const Text('Book'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BookingPage()),
              ),
            ),
            ElevatedButton(
              child: const Text('Admin Appointments'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminAppointmentsPage()),
              ),
            ),
            ElevatedButton(
              child: const Text('Admin Images'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminImages()),
              ),
            ),
          ],
        ),
      ),
    );
  }

// }
}