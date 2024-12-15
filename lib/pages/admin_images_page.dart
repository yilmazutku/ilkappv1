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
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = Provider.of<UserProvider>(context, listen: false).fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel - Users'),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            logger.err('Error fetching users: {}', [snapshot.error??'snapshot error']);
            return Center(child: Text('Error fetching users: ${snapshot.error}'));
          } else {
            final users = snapshot.data ?? [];

            if (users.isEmpty) {
              return const Center(child: Text('No users found.'));
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
                        builder: (context) => const CustomerSummaryPage(),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
