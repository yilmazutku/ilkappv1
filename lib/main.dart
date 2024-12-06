import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:untitled/pages/login_page.dart';
import 'package:untitled/providers/appointment_manager.dart';
import 'package:untitled/providers/image_manager.dart';
import 'package:untitled/providers/login_manager.dart';
import 'package:untitled/providers/meal_state_and_upload_manager.dart';
import 'package:untitled/providers/user_provider.dart';
import 'package:untitled/providers/payment_provider.dart';
import 'package:untitled/providers/test_provider.dart';
import 'firebase_options.dart';
import 'models/logger.dart';

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

Future<void> signInAutomatically() async {
  const email = 'utkuyy97@gmail.com';
  const password = '612009';
  try {
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ImageManager()),
        ChangeNotifierProvider(create: (_) => MealStateManager()),
        ChangeNotifierProvider(create: (_) => AppointmentManager()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => TestProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[100],
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: Colors.white),
            elevation: 2,
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.black87),
          ),
          cardColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.green),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('tr', 'TR'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    logger.info('Building HomePage with MaterialPageRoute(builder: (context) => const LoginPage()...');
    return Scaffold(
      appBar: AppBar(title: const Text('Ana Sayfa')),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        onTap: (index) {
          if (index == 0) {
            // Handle navigation for "Ana Sayfa"
          } else if (index == 1) {
            // Handle navigation for "Profil"
          }
        },
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: const Text('My Login'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Go to Menu Page'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()), // Update to your menu page
              ),
            ),
          ],
        ),
      ),
    );
  }
}
