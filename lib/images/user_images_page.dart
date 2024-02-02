import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../commons/df_vt_enums.dart';

class UserImagesPage extends StatefulWidget {
  final String folderName;
  final DateFilter selectedDateFilter;

  const UserImagesPage(
      {super.key, required this.folderName, required this.selectedDateFilter});

  @override
  createState() {
    return _UserImagesPageState();
  }
}

class _UserImagesPageState extends State<UserImagesPage> {
  ListView? listview;
  List<String> newImageUrls = [];
  ViewType currentView = ViewType.list;

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  Future<void> fetchImages() async {
    {
      // currentFolder = folderName;
      String folderName = widget.folderName;
      final ref = FirebaseStorage.instance.ref('users/$folderName');
      final ListResult result = await ref.listAll();

      // Determine the start date for filtering based on the selectedDateFilter
      DateTime startDate = DateTime.now();
      switch (widget.selectedDateFilter) {
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
          startDate = DateTime.now().subtract(const Duration(days: 30));
          break;
        default:
          break;
      }
      var asd = result.items.length;
      print('result.itemsLength=$asd');
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
      if (mounted) {
        setState(() {
          newImageUrls = imageUrls;
          listview = ListView.builder(
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return Image.network(imageUrls[index]);
            },
          );
        });
      } else {
        print('no mounting in user images page.');
      }
    }
  }

  Widget get getGridView {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Adjust the number of columns
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: newImageUrls.length,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () => showFullImage(context, newImageUrls[index]),
          child: Image.network(
            newImageUrls[index],
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  void showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            child: Image.network(imageUrl),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        actions: <Widget>[
          IconButton(
            icon:
                Icon(currentView == ViewType.list ? Icons.grid_on : Icons.list),
            onPressed: () {
              setState(() {
                currentView = currentView == ViewType.list
                    ? ViewType.grid
                    : ViewType.list;
              });
            },
          ),
        ],
      ),
      body: currentView == ViewType.list ? listview : getGridView,
    );
  }
}
