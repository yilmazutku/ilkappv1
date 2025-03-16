import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/diet_list_pages/odeme_takip_handler.dart';
import 'package:untitled/pages/meas_page.dart';
import 'package:untitled/pages/profile_page.dart';
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
    logger.info('getting sub id for userId={}', [userId]);
    final subscriptionsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('subscriptions');

    final querySnapshot = await subscriptionsCollection
        .where('status', isEqualTo: 'active')
        .orderBy('startDate', descending: true)
        .limit(1)
        .get();

    // Return the document ID if available, else null.
    return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first.id : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Girişi'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Consumer<LoginProvider>(
          builder: (context, loginProvider, child) {
            final errorMessage = loginProvider.errorMessage;
            final isLoading = loginProvider.isLoading;

            if (errorMessage.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showErrorDialog(context, errorMessage);
                loginProvider.clearError();
              });
            }

            return loginProvider.isLoggedIn
                ? _buildHomePageContent(context)
                : _buildLoginForm(context, loginProvider, isLoading);
          },
        ),
      ),
    );
  }

  Widget _buildLoginForm(
      BuildContext context, LoginProvider loginProvider, bool isLoading) {
    final screenWidth = MediaQuery.of(context).size.width;

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
                builder: (context) => const ResetPasswordPage(email: ''),
              ),
            );
          },
          child: const Text('Şifremi Unuttum'),
        ),
      ],
    );
  }

  Widget _buildHomePageContent(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox();

    return FutureBuilder<String>(
      future: _getUserRole(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final role = snapshot.data ?? 'user';
        final isAdmin = role == 'admin';

        // User-specific grid items
        final List<Map<String, dynamic>> userGridItems = [
          {
            'icon': Icons.food_bank,
            'label': 'Planım',
            'onTap': () => _navigateToMeal(context),
          },
          {
            'icon': Icons.fitness_center,
            'label': 'Ölçümlerim',
            'onTap': () => _navigateToMeas(context),
          },
          {
            'icon': Icons.calendar_today,
            'label': 'Geçmiş Randevularım',
            'onTap': () => _navigateToPastAppointments(context),
          },
          {
            'icon': Icons.payments,
            'label': 'Ödemelerim',
            'onTap': () => _navigateToPayments(context),
          },
          {
            'icon': Icons.event,
            'label': 'Randevu Al',
            'onTap': () => _navigateToUserAppointments(context),
          },
          {
            'icon': Icons.person,
            'label': 'Profil',
            'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfilePage(userId: userId)),
            ),
          },
        ];

        // Admin-specific drawer items
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

        return Scaffold(
          appBar: AppBar(
            title: const Text('Ana Sayfa'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Provider.of<LoginProvider>(context, listen: false).logout();
                },
              ),
            ],
          ),
          drawer: isAdmin
              ? Drawer(
            child: ListView(
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.blue),
                  child: Text('Admin Menüsü', style: TextStyle(color: Colors.white, fontSize: 20)),
                ),
                ...adminDrawerItems.map((item) => ListTile(
                  leading: Icon(item['icon']),
                  title: Text(item['label']),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    item['onTap']();
                  },
                )),
              ],
            ),
          )
              : null,
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.2,
              children: userGridItems.map((item) {
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

// Helper method to fetch user role
  Future<String> _getUserRole(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data()?['role'] ?? 'user';
  }

// Updated _buildGridItem for better styling
  Widget _buildGridItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
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
  //16.03.2025 değiştirildi grok3 ile:
  // Widget _buildHomePageContent(BuildContext context) {
  //   // Define our grid items using a list of maps for brevity.
  //   final List<Map<String, dynamic>> gridItems = [
  //     {
  //       'icon': Icons.food_bank,
  //       'label': 'Planım',
  //       'onTap': () => _navigateToMeal(context),
  //     },
  //     {
  //       'icon': Icons.food_bank,
  //       'label': 'Ölçümlerim',
  //       'onTap': () => _navigateToMeas(context),
  //     },
  //     {
  //       'icon': Icons.calendar_today,
  //       'label': 'Geçmiş Randevularım',
  //       'onTap': () => _navigateToPastAppointments(context),
  //     },
  //     {
  //       'icon': Icons.payments,
  //       'label': 'Ödemelerim',
  //       'onTap': () => _navigateToPayments(context),
  //     },
  //     {
  //       'icon': Icons.timeline,
  //       'label': 'Admin Zamanlar',
  //       'onTap': () => _navigateToAdminTimeSlots(context),
  //     },
  //     {
  //       'icon': Icons.event,
  //       'label': 'Randevu Al',
  //       'onTap': () => _navigateToUserAppointments(context),
  //     },
  //     {
  //       'icon': Icons.lock,
  //       'label': 'Şifre Sıfırla',
  //       'onTap': () => _navigateToResetPassword(context),
  //     },
  //     {
  //       'icon': Icons.assignment,
  //       'label': 'Admin Randevular',
  //       'onTap': () => _navigateToAdminAppointments(context),
  //     },
  //     {
  //       'icon': Icons.image,
  //       'label': 'Admin Panel',
  //       'onTap': () => _navigateToAdminImages(context),
  //     },
  //     {
  //       'icon': Icons.list,
  //       'label': 'Admin Liste Yükle',
  //       'onTap': () => _navigateToFileHandler(context),
  //     },
  //     {
  //       'icon': Icons.person_add,
  //       'label': 'Admin Kullanıcı Oluştur',
  //       'onTap': () => _navigateToCreateUser(context),
  //     },
  //     {
  //       'icon': Icons.person_add,
  //       'label': 'Admin Odeme Takip Cizelge Yukle',
  //       'onTap': () => _navigateToOdemeTakipHandler(context),
  //     },
  //   ];
  //
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('Ana Sayfa'),
  //       centerTitle: true,
  //     ),
  //     body: Padding(
  //       padding: const EdgeInsets.all(2.0),
  //       child: GridView.count(
  //         crossAxisCount: 4,
  //         mainAxisSpacing: 4,
  //         crossAxisSpacing: 4,
  //         // Adjust childAspectRatio to make items appear smaller.
  //         childAspectRatio: 5,
  //         children: gridItems.map((item) {
  //           return _buildGridItem(
  //             context,
  //             item['icon'] as IconData,
  //             item['label'] as String,
  //             item['onTap'] as VoidCallback,
  //           );
  //         }).toList(),
  //       ),
  //     ),
  //   );
  // }
//16.03.2025 değiştirildi grok3 ile:
  // Widget _buildGridItem(
  //     BuildContext context,
  //     IconData icon,
  //     String label,
  //     VoidCallback onTap,
  //     ) {
  //   return Card(
  //     elevation: 1,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
  //     child: InkWell(
  //       onTap: onTap,
  //       borderRadius: BorderRadius.circular(2),
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           // Reduce icon size to make it smaller.
  //           Icon(icon, size: 18),
  //           const SizedBox(height: 4),
  //           Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // -- Navigation helpers below --

  Future<void> _navigateToMeas(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MeasurementPage(userId: userId)),
    );
  }

  Future<void> _navigateToMeal(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final subscriptionId = await getCurrentSubscriptionId(userId);
    if (subscriptionId == null || !context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MealUploadPage(userId: userId, subscriptionId: subscriptionId),
      ),
    );
  }

  void _navigateToPastAppointments(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PastAppointmentsPage(userId: userId)),
    );
  }

  void _navigateToPayments(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserPaymentsPage(userId: userId)),
    );
  }

  void _navigateToAdminTimeSlots(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminTimeSlotsPage()),
    );
  }

  Future<void> _navigateToUserAppointments(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final subscriptionId = await getCurrentSubscriptionId(userId);
    if (subscriptionId == null) return;
    if(!context.mounted)return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentsPage(userId: userId, subscriptionId: subscriptionId),
      ),
    );
  }

  void _navigateToResetPassword(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResetPasswordPage(email: email)),
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

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}

// // login_page.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:untitled/diet_list_pages/odeme_takip_handler.dart';
// import 'package:untitled/pages/meas_page.dart';
// import 'package:untitled/pages/reset_password_page.dart';
// import 'package:untitled/pages/user_past_appointments_page.dart';
// import 'package:untitled/pages/user_payments_page.dart';
// import 'admin_appointments_page.dart';
// import 'admin_timeslots_page.dart';
// import 'appointments_page.dart';
// import '../models/logger.dart';
// import '../providers/login_manager.dart';
// import 'admin_create_user_page.dart';
// import 'admin_images_page.dart';
// import '../diet_list_pages/file_handler_page.dart';
// import 'meal_upload_page.dart';
//
// final Logger logger = Logger.forClass(LoginPage);
//
// class LoginPage extends StatelessWidget {
//   const LoginPage({super.key});
//
//   Future<String?> getCurrentSubscriptionId(String userId) async {
//     logger.info('getting sub id for user with userId={}', [userId]);
//     final subscriptionsCollection = FirebaseFirestore.instance
//         .collection('users')
//         .doc(userId)
//         .collection('subscriptions');
//
//     final querySnapshot = await subscriptionsCollection
//         .where('status', isEqualTo: 'active')
//         .orderBy('startDate', descending: true)
//         .limit(1)
//         .get();
//
//     if (querySnapshot.docs.isNotEmpty) {
//       final doc = querySnapshot.docs.first;
//       return doc.id;
//     } else {
//       return null;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Kullanıcı Girişi'),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(10.0),
//         child: Consumer<LoginProvider>(
//           builder: (context, loginProvider, child) {
//             String errorMessage = loginProvider.errorMessage;
//             bool isLoading = loginProvider.isLoading;
//
//             if (errorMessage.isNotEmpty) {
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 _showErrorDialog(context, errorMessage);
//                 loginProvider.clearError();
//               });
//             }
//
//             return loginProvider.isLoggedIn
//                 ? _buildHomePageContent(context)
//                 : _buildLoginForm(context, loginProvider, screenWidth, isLoading);
//           },
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLoginForm(BuildContext context, LoginProvider loginProvider,
//       double screenWidth, bool isLoading) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: <Widget>[
//         SizedBox(
//           width: screenWidth * 0.7,
//           child: TextField(
//             controller: loginProvider.emailController,
//             keyboardType: TextInputType.emailAddress,
//             decoration: const InputDecoration(
//               hintText: 'Emailinizi giriniz',
//               labelText: 'Email',
//               border: OutlineInputBorder(),
//             ),
//           ),
//         ),
//         const SizedBox(height: 10),
//         SizedBox(
//           width: screenWidth * 0.7,
//           child: TextField(
//             controller: loginProvider.passwordController,
//             obscureText: true,
//             decoration: const InputDecoration(
//               hintText: 'Şifrenizi giriniz',
//               labelText: 'Şifre',
//               border: OutlineInputBorder(),
//             ),
//           ),
//         ),
//         const SizedBox(height: 10),
//         ElevatedButton(
//           onPressed: isLoading ? null : () => loginProvider.login(context),
//           child: isLoading
//               ? const CircularProgressIndicator()
//               : const Text('Giriş Yap'),
//         ),
//         const SizedBox(height: 10),
//         TextButton(
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                   builder: (context) => const ResetPasswordPage(email: '')),
//             );
//           },
//           child: const Text('Şifremi Unuttum'),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildHomePageContent(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Ana Sayfa'),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(2.0),
//         child: GridView.count(
//           crossAxisCount: 2,
//           mainAxisSpacing: 8,
//           crossAxisSpacing: 8,
//           children: [
//             _buildGridItem(context, Icons.food_bank, 'Planım', () => _navigateToMeal(context)),
//             _buildGridItem(context, Icons.food_bank, 'Meas', () => _navigateToMeas(context)),
//             _buildGridItem(context, Icons.calendar_today, 'Geçmiş Randevularım',
//                     () => _navigateToPastAppointments(context)),
//             _buildGridItem(context, Icons.payments, 'Ödemelerim',
//                     () => _navigateToPayments(context)),
//             _buildGridItem(context, Icons.timeline, 'Admin Timeslots',
//                     () => _navigateToAdminTimeSlots(context)),
//             _buildGridItem(context, Icons.event, 'Randevu',
//                     () => _navigateToAppointments(context)),
//             _buildGridItem(context, Icons.lock, 'Şifre Sıfırla',
//                     () => _navigateToResetPassword(context)),
//             _buildGridItem(context, Icons.assignment, 'Admin Appointments',
//                     () => _navigateToAdminAppointments(context)),
//             _buildGridItem(context, Icons.image, 'Admin Images',
//                     () => _navigateToAdminImages(context)),
//             _buildGridItem(context, Icons.list, 'Admin Liste',
//                     () => _navigateToFileHandler(context)),
//             _buildGridItem(context, Icons.person_add, 'Admin Kullanıcı Oluştur',
//                     () => _navigateToCreateUser(context)),
//             _buildGridItem(context, Icons.person_add, 'Admin Odeme Cizelge',
//                     () => _navigateToOdemeTakipHandler(context)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildGridItem(
//       BuildContext context, IconData icon, String label, VoidCallback onTap) {
//     return Card(
//       elevation: 1,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1)),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(1),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 20),
//             const SizedBox(height: 2),
//             Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> _navigateToMeas(BuildContext context) async {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;
//     // final subscriptionId = await getCurrentSubscriptionId(userId);
//     // if (subscriptionId == null) return;
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) =>  MeasurementPage(userId: userId,
//
//         ),
//       ),
//     );
//   }
//
//   Future<void> _navigateToMeal(BuildContext context) async {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;
//     final subscriptionId = await getCurrentSubscriptionId(userId);
//     if (subscriptionId == null) return;
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => MealUploadPage(
//           userId: userId,
//           subscriptionId: subscriptionId,
//         ),
//       ),
//     );
//   }
//
//   void _navigateToPastAppointments(BuildContext context) {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => PastAppointmentsPage(userId: userId),
//       ),
//     );
//   }
//
//   void _navigateToPayments(BuildContext context) {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => UserPaymentsPage(userId: userId),
//       ),
//     );
//   }
//
//   void _navigateToAdminTimeSlots(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const AdminTimeSlotsPage(),
//       ),
//     );
//   }
//
//   Future<void> _navigateToAppointments(BuildContext context) async {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;
//     final subscriptionId = await getCurrentSubscriptionId(userId);
//     if (subscriptionId == null) return;
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => AppointmentsPage(
//           userId: userId,
//           subscriptionId: subscriptionId,
//         ),
//       ),
//     );
//   }
//
//   void _navigateToResetPassword(BuildContext context) {
//     final email = FirebaseAuth.instance.currentUser?.email ?? '';
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ResetPasswordPage(email: email),
//       ),
//     );
//   }
//
//   void _navigateToAdminAppointments(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const AdminAppointmentsPage(),
//       ),
//     );
//   }
//
//   void _navigateToAdminImages(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const AdminImages(),
//       ),
//     );
//   }
//
//   void _navigateToFileHandler(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const FileHandlerPage(),
//       ),
//     );
//   }
//
//   void _navigateToCreateUser(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const CreateUserPage(),
//       ),
//     );
//   }
//
//   void _navigateToOdemeTakipHandler(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const OdemeTakipFileHandlerPage(),
//       ),
//     );
//   }
//
//   void _showErrorDialog(BuildContext context, String message) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Hata'),
//           content: Text(message),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text('Tamam'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
