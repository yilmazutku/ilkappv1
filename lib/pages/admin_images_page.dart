import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/logger.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import 'customer_sum.dart';

final Logger logger = Logger.forClass(AdminImages);

class AdminImages extends StatefulWidget {
  const AdminImages({super.key});

  @override
  State<AdminImages> createState() => _AdminImagesState();
}

class _AdminImagesState extends State<AdminImages> {
  List<UserModel> users = [];
  // bool isLoading = true;

  @override
  void initState() {
    super.initState();
    //fetchUsers();
  }

  // Future<void> fetchUsers() async {
  //   try {
  //     final snapshot = await FirebaseFirestore.instance.collection('users').get();
  //     setState(() {
  //       users = snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
  //       isLoading = false;
  //     });
  //   } catch (e) {
  //     logger.err('Error fetching users: {}', [e]);
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    // Get the UserProvider instance
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Fetch users if not already loaded
    if (userProvider.users.isEmpty && !userProvider.isLoading) {
      userProvider.fetchUsers();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel - Users'),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final users = userProvider.users;
          final isLoading = userProvider.isLoading;

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                title: Text(user.name),
                subtitle: Text(user.email),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CustomerSummaryPage(userId: user.userId),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
