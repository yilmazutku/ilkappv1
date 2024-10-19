// tabs/details_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class DetailsTab extends StatelessWidget {
  final String userId;

  const DetailsTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // Fetch user details if not already fetched
    if (userProvider.user == null && !userProvider.isLoading) {
      userProvider.fetchUserDetails(userId);
    }

    if (userProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (userProvider.user == null) {
      return const Center(child: Text('No user details available.'));
    }

    final user = userProvider.user!;

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
}
