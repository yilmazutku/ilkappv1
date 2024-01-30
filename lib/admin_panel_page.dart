import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class AdminPanelPage extends StatefulWidget {
  @override
  State<AdminPanelPage> createState() {
    return _AdminPanelPageState();
  }

  // _AdminPanelPageState createState() => _AdminPanelPageState();

  Future<List<String>> fetchUserImages(String userId) async {
    List<String> imageUrls = [];

    final ref = FirebaseStorage.instance.ref('user_uploads/$userId');
    final CollectionReference collectionReference =
        FirebaseFirestore.instance.collection('user_uploads');
    final result = await ref.listAll();

    for (var item in result.items) {
      final url = await item.getDownloadURL();
      imageUrls.add(url);
    }

    return imageUrls;
  }

  // @override
  // Widget build(BuildContext context) {
  //   // Assuming 'userId' is available
  //   final userId = 'some_user_id';
  //
  //   return FutureBuilder(
  //     future: fetchUserImages(userId),
  //     builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return Center(child: CircularProgressIndicator());
  //       }
  //
  //       if (snapshot.hasError) {
  //         return Center(child: Text('Error: ${snapshot.error}'));
  //       }
  //
  //       if (snapshot.data == null || snapshot.data!.isEmpty) {
  //         return Center(child: Text('No images found for this user.'));
  //       }
  //
  //       return ListView(
  //         children: snapshot.data!.map((url) => Image.network(url)).toList(),
  //       );
  //     },
  //   );
  // }
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  var newImageUrls;
  // TODO: Add state and methods to fetch and display user images
  void fetchUserImages() async {
    List<String> imageUrls = [];
    print('asd');
    final ref = FirebaseStorage.instance.ref('files');
    final CollectionReference collectionReference =
        FirebaseFirestore.instance.collection('files');
    final result = await ref.listAll();
    
List <Image> listImgs= [];
List <Image> listImg=[];
    for (var item in result.items) {
      final url = await item.getDownloadURL();
      imageUrls.add(url);
      listImg.add(Image.network(url));
    }
    setState(() {
      newImageUrls = imageUrls;
    });

    print('asd');
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
      ),
      body: Center(
        child: TextButton(
          onPressed: () async {
           fetchUserImages();
          },
          child:  Expanded(
            child: ListView.builder(
              itemCount: newImageUrls.length,
              itemBuilder: (context, index) {
                return Image.network(newImageUrls[index]);
              },
            ),
          ),
          // TODO: Display the list of users and their images
        ),
      ),
    );
  }
}
