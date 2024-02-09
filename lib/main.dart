import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:untitled/admin_pages/admin_appointments.dart';
import 'package:untitled/admin_pages/admin_panel_page.dart';
import 'package:untitled/images/meal_upload_page.dart';
import 'admin_pages/admin_appointments.dart';
import 'booking.dart';
import 'chat/chat_page.dart';

String email = 'utkuyy97@gmail.com';
String password = '612009aa';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
              child: const Text('Admin Appointments'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminAppointmentsPage()),
              ),

            ),
            ElevatedButton(
              child: const Text('Admin Panel'),
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
}


