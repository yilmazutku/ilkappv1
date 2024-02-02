import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:untitled/images/user_images_page.dart';
import 'commons/df_vt_enums.dart';

class AdminPanelPage extends StatefulWidget {
  @override
  State<AdminPanelPage> createState() {
    return _AdminPanelPageState();
  }
}



class _AdminPanelPageState extends State<AdminPanelPage> {
  List<String> newImageUrls = [];
  List<String> folders = [];
  ListView? listview;
  DateFilter selectedDateFilter = DateFilter.today; // default filter option
  String currentFolder = '';
  ViewType currentView = ViewType.list;

  void updateDateFilter(DateFilter filter) {
    setState(() {
      selectedDateFilter = filter;
    });
    fetchImagesFromFolder(
        currentFolder); // Assuming you store the current folder name in this variable
  }

  // TODO: Add state and methods to fetch and display user images
  @override
  initState() {
    super.initState();
    fetchUserFolders();
  }

  Future fetchUserFolders() async {
    List<String> imageUrls = [];
    print('Fetching UserFolders...');
    // final ref = FirebaseStorage.instance.ref('users');
    // await listFiles(ref);
    final ref = FirebaseStorage.instance.ref('users');
    final ListResult result = await ref.listAll();

    List<String> folderNames =
        result.prefixes.map((folderRef) => folderRef.name).toList();

    setState(() {
      folders = folderNames;
      listview = ListView(
          children: folders
              .map((folderName) => ListTile(
                    title: Text(folderName),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UserImagesPage(
                            folderName: folderName,
                            selectedDateFilter: selectedDateFilter,
                          ),
                        ),
                      );
                    },
                  ))
              .toList());
    });

    print('Fetching UserFolders complete.');
  }

  Future<void> fetchImagesFromFolder(String folderName) async {
    currentFolder = folderName;
    final ref = FirebaseStorage.instance.ref('users/$folderName');
    final ListResult result = await ref.listAll();

    // Determine the start date for filtering based on the selectedDateFilter
    DateTime startDate = DateTime.now();
    switch (selectedDateFilter) {
      case DateFilter.last3Days:
        startDate = DateTime.now().subtract(const Duration(days: 3));
        break;
      case DateFilter.last7Days:
        startDate = DateTime.now().subtract(const Duration(days: 7));
        break;
      case DateFilter.last30Days:
        startDate = DateTime.now().subtract(const Duration(days: 30));
        break;
      case DateFilter.today:
        startDate = DateTime.now().subtract(const Duration(days: 1));
        break;
      default:
        break;
    }

    List<String> imageUrls = [];
    for (var fileRef in result.items) {
      var metadata = await fileRef.getMetadata();
      DateTime? createdTime = metadata.timeCreated;
      if (createdTime != null &&
          startDate.isBefore(createdTime!) &&
          createdTime!.isBefore(DateTime.now())) {
        final url = await fileRef.getDownloadURL();
        imageUrls.add(url);
      }
    }
    setState(() {
      newImageUrls = imageUrls;
      listview = ListView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Image.network(imageUrls[index]);
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: listview,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          fetchUserFolders();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
