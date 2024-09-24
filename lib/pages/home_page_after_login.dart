import 'package:flutter/material.dart';
import 'package:untitled/usersAndAccount/reset_password_page.dart';

import '../commons/logger.dart';
import '../appointments/admin_appointments_page.dart';
import '../usersAndAccount/admin_create_user_page.dart';
import 'admin_images_page.dart';
import '../appointments/appointments_page.dart';
import 'file_handler_page.dart';
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
      appBar: AppBar(title: const Text('Trial App v0')),
      drawer: Drawer(
        child: ListView(
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
            // ListTile for "Planım"
            ListTile(
              leading: const Icon(Icons.food_bank),
              title: const Text('Planım'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MealUploadPage()),
              ),
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
                MaterialPageRoute(builder: (context) => const AdminAppointmentsPage()),
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
          ],
        ),
      ),
      body: const Center(
        child: Text('Select an option from the side menu'),
      ),
    );
    // return Scaffold(
    //   appBar: AppBar(title: const Text('Trial App v0')),
    //   body: Center(
    //     child: Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: <Widget>[
    //         ElevatedButton(
    //           child: const Text('Planım'),
    //           onPressed: () => Navigator.push(
    //             context,
    //             MaterialPageRoute(builder: (context) => const MealUploadPage()),
    //           ),
    //         ),
    //         // ElevatedButton(
    //         //   child: const Text('Chat with Admin'),
    //         //   onPressed: () => Navigator.push(
    //         //     context,
    //         //     MaterialPageRoute(builder: (context) => const ChatPage()),
    //         //   ),
    //         // ),
    //         ElevatedButton(
    //           child: const Text('Randevu'),
    //           onPressed: () => Navigator.push(
    //             context,
    //             MaterialPageRoute(builder: (context) => const BookingPage()),
    //           ),
    //         ),
    //
    //         ElevatedButton(
    //           child: const Text('Şifre Sıfırla'),
    //           onPressed: () => Navigator.push(
    //             context,
    //             MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
    //           ),
    //         ),
    //         ElevatedButton(
    //           child: const Text('Admin Appointments'),
    //           onPressed: () => Navigator.push(
    //             context,
    //             MaterialPageRoute(
    //                 builder: (context) => const AdminAppointmentsPage()),
    //           ),
    //         ),
    //         ElevatedButton(
    //           child: const Text('Admin Images'),
    //           onPressed: () => Navigator.push(
    //             context,
    //             MaterialPageRoute(builder: (context) => const AdminImages()),
    //           ),
    //         ),
    //         ElevatedButton(
    //           child: const Text('Admin Liste'),
    //           onPressed: () => Navigator.push(
    //             context,
    //             MaterialPageRoute(builder: (context) => const FileHandlerPage()),
    //           ),
    //         ),
    //
    //         ElevatedButton(
    //           child: const Text('Admin Kullanıcı oluştur'),
    //           onPressed: () => Navigator.push(
    //             context,
    //             MaterialPageRoute(builder: (context) => const CreateUserPage()),
    //           ),
    //         ),
    //       ],
    //     ),
    //   ),
    // );
  }

// }
}
