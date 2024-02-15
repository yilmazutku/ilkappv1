import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:untitled/images/user_images_page.dart';

import '../commons/common.dart';

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

  //ViewType currentView = ViewType.list;

  void updateDateFilter(DateFilter filter) {
    setState(() {
      selectedDateFilter = filter;
    });
    // fetchImagesFromFolder(
    //     currentFolder); // Assuming you store the current folder name in this variable
  }

  // TODO: Add state and methods to fetch and display user images
  @override
  initState() {
    super.initState();
    fetchUserFolderNames();
  }

  Future<List<String>> fetchUserFolderNames() async {
    print('Fetching UserFolders...');
    final ref = FirebaseStorage.instance.ref('users');
    final ListResult result = await ref.listAll();

    List<String> folderNames =
        result.prefixes.map((folderRef) => folderRef.name).toList();
    // folders = folderNames;
    // ListView  listview = ListView(
    //       children: folders
    //           .map((folderName) => ListTile(
    //                 title: Text(folderName),
    //                 onTap: () {
    //                   Navigator.of(context).push(
    //                     MaterialPageRoute(
    //                       builder: (context) => UserImagesPage(
    //                         folderName: folderName,
    //                        // selectedDateFilter: selectedDateFilter,
    //                       ),
    //                     ),
    //                   );
    //                 },
    //               ))
    //           .toList());
    print('Fetching UserFolderNames  complete.');
    return folderNames;
  }

  // Future<ListView> fetchImagesFromFolder(String folderName) async {
  //   currentFolder = folderName;
  //   final ref = FirebaseStorage.instance.ref('users/$folderName');
  //   final ListResult result = await ref.listAll();
  //
  //   // Determine the start date for filtering based on the selectedDateFilter
  //   DateTime startDate = DateTime.now();
  //   switch (selectedDateFilter) {
  //     case DateFilter.last3Days:
  //       startDate = DateTime.now().subtract(const Duration(days: 3));
  //       break;
  //     case DateFilter.last7Days:
  //       startDate = DateTime.now().subtract(const Duration(days: 7));
  //       break;
  //     case DateFilter.last30Days:
  //       startDate = DateTime.now().subtract(const Duration(days: 30));
  //       break;
  //     case DateFilter.today:
  //       startDate = DateTime.now().subtract(const Duration(days: 1));
  //       break;
  //     default:
  //       break;
  //   }
  //
  //   List<String> imageUrls = [];
  //   for (var fileRef in result.items) {
  //     var metadata = await fileRef.getMetadata();
  //     DateTime? createdTime = metadata.timeCreated;
  //     if (createdTime != null &&
  //         startDate.isBefore(createdTime) &&
  //         createdTime.isBefore(DateTime.now())) {
  //       final url = await fileRef.getDownloadURL();
  //       imageUrls.add(url);
  //     }
  //   }
  //   newImageUrls = imageUrls;
  //   ListView listview = ListView.builder(
  //     itemCount: imageUrls.length,
  //     itemBuilder: (context, index) {
  //       return Image.network(imageUrls[index]);
  //     },
  //   );
  //   return listview;
  // }

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
              // Data is still loading, show a progress indicator
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
