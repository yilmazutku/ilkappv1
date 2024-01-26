import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class AdminPanelPage extends StatefulWidget {
  @override
  _AdminPanelPageState createState() => _AdminPanelPageState();

  Future<List<String>> fetchUserImages(String userId) async {
    List<String> imageUrls = [];

    final ref = FirebaseStorage.instance.ref('user_uploads/$userId');
    final result = await ref.listAll();

    for (var item in result.items) {
      final url = await item.getDownloadURL();
      imageUrls.add(url);
    }

    return imageUrls;
  }

  @override
  Widget build(BuildContext context) {
    // Assuming 'userId' is available
    final userId = 'some_user_id';

    return FutureBuilder(
      future: fetchUserImages(userId),
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.data == null || snapshot.data!.isEmpty) {
          return Center(child: Text('No images found for this user.'));
        }

        return ListView(
          children: snapshot.data!.map((url) => Image.network(url)).toList(),
        );
      },
    );
  }



}

class _AdminPanelPageState extends State<AdminPanelPage> {
  // TODO: Add state and methods to fetch and display user images

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
      ),
      body: Center(
        // TODO: Display the list of users and their images
      ),
    );
  }
}