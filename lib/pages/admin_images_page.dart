import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../commons/logger.dart';
import '../models/user_model.dart';
import 'customer_sum.dart';

final Logger logger = Logger.forClass(AdminImages);

class AdminImages extends StatefulWidget {
  const AdminImages({super.key});

  @override
  State<AdminImages> createState() => _AdminImagesState();
}

class _AdminImagesState extends State<AdminImages> {
  List<UserModel> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        users = snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
        isLoading = false;
      });
    } catch (e) {
      logger.err('Error fetching users: {}', [e]);
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel - Users'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
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
      ),
    );
  }
}
