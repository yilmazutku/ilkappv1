import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/pages/login_page.dart';
import 'package:untitled/providers/appointment_manager.dart';
import 'package:untitled/providers/image_manager.dart';
import 'package:untitled/providers/login_manager.dart';
import 'package:untitled/providers/meal_state_and_upload_manager.dart';
import 'package:untitled/providers/user_provider.dart';
import 'package:untitled/providers/payment_provider.dart';
import 'package:untitled/providers/test_provider.dart';

import 'models/logger.dart';
import 'firebase_options.dart';
String email = 'utkuyy97@gmail.com';
String password = '612009aa';
final logger = Logger('MyApp');

void main() async {
  logger.info('Application started');
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await signInAutomatically();
  runApp(const MyApp());

}

Future<void> signInAutomatically() async { //TODO launchta kaldırılacak user sidedan
  try {
    var instance = FirebaseAuth.instance;
    UserCredential userCredential = await instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    logger.info('Signed in with email: ${userCredential.user?.email}');
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      logger.warn('No user found for that email.');
    } else if (e.code == 'wrong-password') {
      logger.warn('Wrong password provided for that user.');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // return MediaQuery(
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ImageManager()),
        ChangeNotifierProvider(create: (context) => MealStateManager()),
        ChangeNotifierProvider(create: (context) => AppointmentManager()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => TestProvider()),
      ],
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
       home: const HomePage(), // Your initial route or home widget

      ),
    // ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    logger.info('Building HomePage with MaterialPageRoute(builder: (context) =>  const LoginPage()...');
    // if(FirebaseAuth.instance.currentUser?.uid=='mChhGVRpH1PBAonozPiEitDm5pE2') {
  // }
    // else {
        return Scaffold(
          appBar:
          AppBar(title: const Text(/*'(AppLocalizations.of(context)!.helloWorld),'*/'Trial App v0')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[

                ElevatedButton(
                  //TODO ogunlere gore secıolmesın gunluk tum fotolar gozuksun dedi nilay
                  child: const Text('My Login'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>   const LoginPage()),
                  ),
                ),
              ],
            ),
          ),
        );
      }

    // }
  }

