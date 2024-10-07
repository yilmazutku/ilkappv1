import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';


import '../commons/common.dart';
import '../commons/userclass.dart';
import 'admin_user_images_page.dart';
//TODO bir sayfada tum fotograflari gormek istiyor.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_user_images_page.dart';

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
      // Handle error
      print('Error fetching users: $e');
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
          : ListView(
        children: users.map((user) {
          return ListTile(
            title: Text(user.name),
            subtitle: Text(user.email),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UserImagesPage(userId: user.userId),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

