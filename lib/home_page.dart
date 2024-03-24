import 'package:flutter/material.dart';

import 'admin_pages/admin_appointments.dart';
import 'admin_pages/admin_images.dart';
import 'booking.dart';
import 'chat/chat_page.dart';
import 'images/meal_upload_page.dart';
class HomePageAfterLogin extends StatelessWidget {
  const HomePageAfterLogin({super.key});

  @override
  Widget build(BuildContext context) {
    print('Building HomePage...');
    // if(FirebaseAuth.instance.currentUser?.uid=='mChhGVRpH1PBAonozPiEitDm5pE2') {
    // }
    // else {
    return Scaffold(
      appBar:
      AppBar(title: Text(/*'(AppLocalizations.of(context)!.helloWorld),'*/'Trial App v0')),
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