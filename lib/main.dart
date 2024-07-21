import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:untitled/managers/chat_manager.dart';
import 'package:untitled/managers/image_manager.dart';
import 'package:untitled/pages/login_page.dart';

import 'managers/appointment_manager.dart';
import 'managers/meal_state_manager.dart';

String email = 'utkuyy97@gmail.com';
String password = '612009aa';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await signInAutomatically();
  runApp(const MyApp());
}

Future<void> signInAutomatically() async {
  try {
    var instance = FirebaseAuth.instance;
    UserCredential userCredential = await instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ImageManager()),
        ChangeNotifierProxyProvider<ImageManager, ChatManager>(
          create: (context) => ChatManager(imageManager:Provider.of<ImageManager>(context, listen: false)),
          update: (context, imageManager, previousChatManager) => ChatManager(imageManager:imageManager),
        ),
        ChangeNotifierProvider(create: (context) => MealStateManager()),
        ChangeNotifierProvider(create: (context) => AppointmentManager()),
      ],
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
       home: const HomePage(), // Your initial route or home widget

        // Define other properties as needed
        // Your MaterialApp configuration
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    print('Building HomePage...');
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
                    MaterialPageRoute(builder: (context) =>  const LoginPage()),
                  ),
                ),
              ],
            ),
          ),
        );
      }

    // }
  }

