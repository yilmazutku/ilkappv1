import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:untitled/admin_appointments.dart';
import 'package:untitled/admin_panel_page.dart';
import 'package:untitled/images/meal_upload_page.dart';
import 'admin_appointments.dart';
import 'booking.dart';
import 'chat/chat_page.dart';

String email = 'utkuyy97@gmail.com';
String password = '612009aa';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //print('ensuredInitialized');
  await Firebase.initializeApp();
  // await FirebaseAppCheck.instance.activate(
  // //  webRecaptchaSiteKey: 'recaptcha-v3-site-key',
  //   // Set androidProvider to `AndroidProvider.debug`
  //   androidProvider: AndroidProvider.playIntegrity,
  // );
  // await FirebaseAppCheck.instance.activate(
  //   // You can also use a `ReCaptchaEnterpriseProvider` provider instance as an
  //   // argument for `webProvider`
  //   webProvider: ReCaptchaV3Provider('AIzaSyD5TJtwhUHcA1zwq_9N2vE_F_L6-TjHSEA'),
  //   // Default provider for Android is the Play Integrity provider. You can use the "AndroidProvider" enum to choose
  //   // your preferred provider. Choose from:
  //   // 1. Debug provider
  //   // 2. Safety Net provider
  //   // 3. Play Integrity provider
  //   androidProvider: AndroidProvider.playIntegrity,
  //   // Default provider for iOS/macOS is the Device Check provider. You can use the "AppleProvider" enum to choose
  //   // your preferred provider. Choose from:
  //   // 1. Debug provider
  //   // 2. Device Check provider
  //   // 3. App Attest provider
  //   // 4. App Attest provider with fallback to Device Check provider (App Attest provider is only available on iOS 14.0+, macOS 14.0+)
  //   appleProvider: AppleProvider.appAttest,
  // );
  // await FirebaseAppCheck.instance.activate(
  //   // Set appleProvider to `AppleProvider.debug`
  //   androidProvider: AndroidProvider.playIntegrity,
  // );
  await signInAutomatically(); print('running');
  runApp(MyApp());
}
Future<void> signInAutomatically() async {

  try {
    var instance = FirebaseAuth.instance;
    UserCredential userCredential = await instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    String uid=instance.currentUser!.uid;
    print('Signed in with email: ${userCredential.user?.email}');
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      print('No user found for that email.');
    } else if (e.code == 'wrong-password') {
      print('Wrong password provided for that user.');
    }
  }
}
class MyApp extends StatelessWidget {
   MyApp({super.key});
  String? uid;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Service App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
  void generateUid  () async{
    FirebaseAuth? instance;
    try {
       instance = FirebaseAuth.instance;
      UserCredential userCredential = await instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
      on FirebaseAuthException catch (e) {
        //TODO
    }
      uid=instance!.currentUser!.uid;
  }
    String? get uidGet {
    return uid;
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // ElevatedButton(
            //   child: const Text('Schedule Appointment'),
            //   onPressed: () => Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (context) => const AppointmentPage(), allowSnapshotting:false),
            //   ),
            // ),
            ElevatedButton(
              child: const Text('Meal Plan'),
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
              child: const Text('Book '),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BookingPage()),
              ),

            ),    ElevatedButton(
              child: const Text('Admin Appts'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminAppointmentsPage()),
              ),

            ),
            ElevatedButton(
              child: const Text('Admin Panel'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminPanelPage()),
              ),

            ),
          ],
        ),
      ),
    );
  }
}


