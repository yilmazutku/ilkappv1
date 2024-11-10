import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';

class DetailsTab extends StatefulWidget {
  final String userId;

  const DetailsTab({super.key, required this.userId});

  @override
   createState() => _DetailsTabState();
}

class _DetailsTabState extends State<DetailsTab> {
  late Future<UserModel?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = UserProvider().fetchUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error fetching user details: ${snapshot.error}'));
        } else if (snapshot.data == null) {
          return const Center(child: Text('No user details available.'));
        } else {
          final user = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              ListTile(
                title: const Text('Name'),
                subtitle: Text(user.name),
              ),
              ListTile(
                title: const Text('Email'),
                subtitle: Text(user.email),
              ),
              // Add more user details as needed
            ],
          );
        }
      },
    );
  }
}
