import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';


import '../commons/common.dart';
import 'admin_user_images_page.dart';

class AdminImages extends StatefulWidget {
  const AdminImages({super.key});

  @override
  State<AdminImages> createState() {
    return _AdminImagesState();
  }
}

class _AdminImagesState extends State<AdminImages> {
  List<String> newImageUrls = [];
  List<String> folders = [];
  ListView? listview;
  DateFilter selectedDateFilter =
      DateFilter.last30Days; // default filter option
  String currentFolder = '';

  void updateDateFilter(DateFilter filter) {
    setState(() {
      selectedDateFilter = filter;
    });
  }

  // TODO: Add state and methods to fetch and display user images
  @override
  initState() {
    super.initState();
  }

  Future<List<String>> fetchUserFolderNames() async {
    print('Fetching UserFolders...');
    final ref = FirebaseStorage.instance.ref('users');
    final ListResult result = await ref.listAll();
    List<String> folderNames =
        result.prefixes.map((folderRef) => folderRef.name).toList();
    print('Fetching UserFolderNames  complete.');
    return folderNames;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      // body: listview,

      body: FutureBuilder<List<String>>(
          future: fetchUserFolderNames(),
          builder: (context, snapshot) {
            // Check the state of the snapshot
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              // If there's an error loading the data, show an error message
              return const Center(child: Text("Error loading user folders"));
            }
            folders.addAll(snapshot.data!);
            return ListView(
                children: folders
                    .map((folderName) => ListTile(
                          title: Text(folderName),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => UserImagesPage(
                                  folderName: folderName,
                                  // selectedDateFilter: selectedDateFilter,
                                ),
                              ),
                            );
                          },
                        ))
                    .toList());
          }),

      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     fetchUserFolderNames();
      //   },
      //   child: const Icon(Icons.refresh),
      // ),
    );
  }
}
