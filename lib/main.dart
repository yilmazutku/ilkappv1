// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:untitled/pages/login_page.dart';
// import 'package:untitled/providers/appointment_manager.dart';
// import 'package:untitled/providers/diet_provider.dart';
// import 'package:untitled/providers/image_manager.dart';
// import 'package:untitled/providers/login_manager.dart';
// import 'package:untitled/providers/meal_state_and_upload_manager.dart';
// import 'package:untitled/providers/user_provider.dart';
// import 'package:untitled/providers/payment_provider.dart';
// import 'package:untitled/providers/test_provider.dart';
// import 'package:untitled/providers/meas_provider.dart';
// import 'firebase_options.dart';
// import 'models/logger.dart';
//
// final logger = Logger('MyApp');
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:untitled/pages/admin_appointments_page.dart';
import 'package:untitled/pages/admin_create_user_page.dart';
import 'package:untitled/pages/admin_images_page.dart';
import 'package:untitled/pages/admin_timeslots_page.dart';
import 'package:untitled/pages/appointments_page.dart';
import 'package:untitled/pages/login_page.dart';
import 'package:untitled/pages/meal_upload_page.dart';
import 'package:untitled/pages/meas_page.dart';
import 'package:untitled/pages/profile_page.dart'; // Import ProfilePage
import 'package:untitled/pages/user_payments_page.dart';
import 'package:untitled/providers/appointment_manager.dart';
import 'package:untitled/providers/diet_provider.dart';
import 'package:untitled/providers/image_manager.dart';
import 'package:untitled/providers/login_manager.dart';
import 'package:untitled/providers/meal_state_and_upload_manager.dart';
import 'package:untitled/providers/meas_provider.dart';
import 'package:untitled/providers/payment_provider.dart';
import 'package:untitled/providers/test_provider.dart';
import 'package:untitled/providers/user_provider.dart';

import 'diet_list_pages/file_handler_page.dart';
import 'diet_list_pages/odeme_takip_handler.dart';
import 'firebase_options.dart';
import 'models/logger.dart';

final logger = Logger('MyApp');

void main() async {
  logger.info('Application started');
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Uncomment the line below for testing auto-login; remove for production
  // await signInAutomatically();

  runApp(const MyApp());
}

// Keep this for testing purposes; remove or modify for production
Future<void> signInAutomatically() async {
  const email = 'utkuyy97@gmail.com';
  const password = '612009';
  try {
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
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
        ChangeNotifierProvider(create: (_) => MeasProvider()),
        ChangeNotifierProvider(create: (_) => TestProvider()),
        ChangeNotifierProvider(create: (_) => DietProvider()),
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
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              logger.info('User is logged in, showing HomePage');
              return const HomePage();
            }
            logger.info('No user logged in, showing LoginPage');
            return const LoginPage();
          },
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Fetch user role (optional, for admin features)
  Future<String> _getUserRole(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data()?['role'] ?? 'user';
  }

  // Navigation method for "Planım" (example)
  Future<void> _navigateToMeal(BuildContext context, String userId) async {
    // Replace with your actual logic, e.g., fetching subscription ID
    const subscriptionId = 'example-subscription-id'; // Placeholder
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MealUploadPage(userId: userId, subscriptionId: subscriptionId),
      ),
    );
  }

  // Navigation method for "Ödemelerim" (example)
  void _navigateToPayments(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            UserPaymentsPage(userId: userId), // Replace with your page
      ),
    );
  }

  // Navigation method for "Profilim"
  void _navigateToProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(userId: userId),
      ),
    );
  }

  void _navigateToMeas(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeasurementPage(userId: userId),
      ),
    );
  }

  void _navigateToAppointments(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentsPage(
          userId: userId,
          subscriptionId: 'default',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text('Kullanıcı bulunamadı'));
    }

    // Use FutureBuilder to fetch role (optional, can simplify if no admin features needed)
    return FutureBuilder<String>(
      future: _getUserRole(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final role = snapshot.data ?? 'user';
        final isAdmin = true;//role == 'admin';

        // List of grid items for all users
      
        final List<Map<String, dynamic>> gridItems = [
          {
            'icon': Icons.food_bank,
            'label': 'Planım',
            'onTap': () => _navigateToMeal(context, userId),
          },
          {
            'icon': Icons.payments,
            'label': 'Ödemelerim',
            'onTap': () => _navigateToPayments(context, userId),
          },
          // Add more options as needed, e.g.:
          {
            'icon': Icons.fitness_center,
            'label': 'Ölçümlerim',
            'onTap': () => _navigateToMeas(context, userId),
          },
          {
            'icon': Icons.event,
            'label': 'Randevu Al',
            'onTap': () => _navigateToAppointments(context, userId),
          },
          {
            'icon': Icons.person,
            'label': 'Profilim',
            'onTap': () => _navigateToProfile(context, userId),
          },

        ];
        if (isAdmin) {
          gridItems.addAll([
            {
              'icon': Icons.timeline,
              'label': 'Admin Zamanlar',
              'onTap': () => _navigateToAdminTimeSlots(context),
            },
            {
              'icon': Icons.assignment,
              'label': 'Admin Randevular',
              'onTap': () => _navigateToAdminAppointments(context),
            },
            {
              'icon': Icons.admin_panel_settings,
              'label': 'Admin Kontrol',
              'onTap': () => _navigateToAdminImages(context),
            },
            {
              'icon': Icons.list,
              'label': 'Admin Liste Yükle',
              'onTap': () => _navigateToFileHandler(context),
            },
            {
              'icon': Icons.manage_accounts,
              'label': 'Kullanıcı Yönetimi',
              'onTap': () => _navigateToCreateUser(context),
            },
            {
              'icon': Icons.payment,
              'label': 'Admin Ödeme Takip',
              'onTap': () => _navigateToOdemeTakipHandler(context),
            },
          ]);
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Ana Sayfa'),
            centerTitle: true,
          ),
          // Optional: Add drawer for admins if needed
          drawer: isAdmin ? _buildAdminDrawer(context) : null,
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.count(
              crossAxisCount: 2,
              // 2 columns
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.2,
              // Adjusts the shape of rectangles
              children: gridItems.map((item) {
                return _buildGridItem(
                  context,
                  item['icon'] as IconData,
                  item['label'] as String,
                  item['onTap'] as VoidCallback,
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // Helper to build each grid item (pushable rectangle)
  Widget _buildGridItem(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminDrawer(BuildContext context) {
    final List<Map<String, dynamic>> adminDrawerItems = [
      {
        'icon': Icons.timeline,
        'label': 'Admin Zamanlar',
        'onTap': () => _navigateToAdminTimeSlots(context),
      },
      {
        'icon': Icons.assignment,
        'label': 'Admin Randevular',
        'onTap': () => _navigateToAdminAppointments(context),
      },
      {
        'icon': Icons.image,
        'label': 'Admin Panel',
        'onTap': () => _navigateToAdminImages(context),
      },
      {
        'icon': Icons.list,
        'label': 'Admin Liste Yükle',
        'onTap': () => _navigateToFileHandler(context),
      },
      {
        'icon': Icons.person_add,
        'label': 'Admin Kullanıcı Oluştur',
        'onTap': () => _navigateToCreateUser(context),
      },
      {
        'icon': Icons.payment,
        'label': 'Admin Ödeme Takip',
        'onTap': () => _navigateToOdemeTakipHandler(context),
      },
    ];

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Admin Menüsü',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          ...adminDrawerItems.map((item) => ListTile(
            leading: Icon(item['icon']),
            title: Text(item['label']),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              item['onTap'](); // Navigate to the admin page
            },
          )),
        ],
      ),
    );
  }
}
void _navigateToAdminTimeSlots(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AdminTimeSlotsPage()),
  );
}

void _navigateToAdminAppointments(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AdminAppointmentsPage()),
  );
}

void _navigateToAdminImages(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AdminImages()),
  );
}

void _navigateToFileHandler(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const FileHandlerPage()),
  );
}

void _navigateToCreateUser(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CreateUserPage()),
  );
}

void _navigateToOdemeTakipHandler(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const OdemeTakipFileHandlerPage()),
  );
}
// class HomePage extends StatelessWidget {
//   const HomePage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     logger.info('Building HomePage with MaterialPageRoute(builder: (context) => const LoginPage()...');
//     return Scaffold(
//       appBar: AppBar(title: const Text('Ana Sayfa')),
//       bottomNavigationBar: BottomNavigationBar(
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
//         ],
//         onTap: (index) {
//           if (index == 0) {
//             // Handle navigation for "Ana Sayfa"
//           } else if (index == 1) {
//             // Handle navigation for "Profil"
//           }
//         },
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             ElevatedButton(
//               child: const Text('My Login'),
//               onPressed: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const LoginPage()),
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               child: const Text('Go to Menu Page'),
//               onPressed: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const LoginPage()), // Update to your menu page
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
