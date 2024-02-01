import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class AdminPanelPage extends StatefulWidget {
  @override
  State<AdminPanelPage> createState() {
    return _AdminPanelPageState();
  }

// _AdminPanelPageState createState() => _AdminPanelPageState();

// Future<List<String>> fetchUserImages(String userId) async {
//   List<String> imageUrls = [];
//
//   final ref = FirebaseStorage.instance.ref('user_uploads/$userId');
//   final CollectionReference collectionReference =
//       FirebaseFirestore.instance.collection('user_uploads');
//   final result = await ref.listAll();
//
//   for (var item in result.items) {
//     final url = await item.getDownloadURL();
//     imageUrls.add(url);
//   }
//
//   return imageUrls;
// }

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

enum DateFilter { today, last3Days, last7Days, last30Days }

class _AdminPanelPageState extends State<AdminPanelPage> {
  List<String> newImageUrls = [];
  List<String> folders = [];
  ListView? listvieww;
  DateFilter selectedDateFilter = DateFilter.today; // default filter option
  String currentFolder = '';

  Map<String, List<String>> userImages = {
    'utku': [],
    'fatih': [],
  };

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
      listvieww = ListView(
          children: folders
              .map((folderName) => ListTile(
                    title: Text(folderName),
                    onTap: () => {
                      fetchImagesFromFolder(folderName),
                      currentFolder = folderName
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
        startDate = DateTime.now().subtract(Duration(days: 3));
        break;
      case DateFilter.last7Days:
        startDate = DateTime.now().subtract(Duration(days: 7));
        break;
      case DateFilter.last30Days:
        startDate = DateTime.now().subtract(Duration(days: 30));
        break;
      case DateFilter.today:
      default:
        break;
    }

    List<String> imageUrls = [];
    for (var fileRef in result.items) {
      DateTime? createdTime;
      fileRef.getMetadata().then((value) => createdTime = value.timeCreated);
      if (startDate.isBefore(createdTime!) &&
          createdTime!.isBefore(DateTime.now())) {
        final url = await fileRef.getDownloadURL();
        imageUrls.add(url);
      }
    }
    setState(() {
      newImageUrls = imageUrls;
      listvieww = ListView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Image.network(imageUrls[index]);
        },
      );
    });
  }

  Future<void> listFiles(Reference ref) async {
    final ListResult result = await ref.listAll();
    String foldername = '';
    // Check for "folders" (prefixes)
    for (var folderRef in result.prefixes) {
      // Recursive call for each "folder"
      await listFiles(folderRef);
      foldername = folderRef.name;
    }

    // Check for "files" (items)
    for (var fileRef in result.items) {
      // Get download URL for each file
      final url = await fileRef.getDownloadURL();
      print('File: $url');
      newImageUrls.add(url);
      userImages.putIfAbsent(foldername, () => newImageUrls);
      userImages.keys.forEach((element) {
        print('(element)=$element');
        print('(element)=');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
      ),
      body: listvieww,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          fetchUserFolders();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: AppBar(
//       title: Text('Admin Panel'),
//     ),
//     body: Center(
//       child: TextButton(
//         onPressed: () async {
//           fetchUserFolders();
//         },
//         child: newImageUrls.isEmpty
//             ? const Text('empty for now')
//             : Expanded(
//                 child: //Text('$newImageUrls.length')
//                     ListView.builder(
//                   itemCount: newImageUrls.length,
//                   itemBuilder: (context, index) {
//                     return Image.network(newImageUrls[index]);
//                   },
//                 ),
//               ),
//         // TODO: Display the list of users and their images
//       ),
//     ),
//   );
// }
}
