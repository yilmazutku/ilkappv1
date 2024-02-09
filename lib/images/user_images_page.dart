import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../commons/common.dart';

///admin panelinde bir kullanıcıya tıklandığında açılır. Recursive bir şekilde kjendini çağırır (? subject to change)
class UserImagesPage extends StatefulWidget {
  final String folderName;

  //final DateFilter selectedDateFilter;

  const UserImagesPage({
    super.key,
    required this.folderName,
    /*required this.selectedDateFilter*/
  });

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
      final ref =
          FirebaseStorage.instance.ref('${Constants.urlUsers}$folderName');
      final ListResult result = await ref.listAll();
      List<String> imageUrls = [];
      for (var fileRef in result.items) {
       // var metadata = await fileRef.getMetadata();
        // DateTime? createdTime = metadata.timeCreated;
       // if (metadata != null) {
          final url = await fileRef.getDownloadURL();
          imageUrls.add(url);
        //}
      }
      if (mounted) { /*It is an error to call setState unless mounted is true.*/
        setState(() {
          if (imageUrls.isNotEmpty) {
            newImageUrls = imageUrls;
            listview = ListView.builder(
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return Image.network(imageUrls[index]);
              },
            );
          } else {
            //TODO optimize recursive func
            List<String> folderNames =
                result.prefixes.map((folderRef) => folderRef.name).toList();
            listview = ListView(
                children: folderNames
                    .map((folderName) => ListTile(
                          title: Text(folderName),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => UserImagesPage(
                                  folderName:
                                      '${widget.folderName}/$folderName',
                                  //selectedDateFilter: widget.selectedDateFilter,
                                ),
                              ),
                            );
                          },
                        ))
                    .toList());
          }
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
        /*builder is called only for those children that are actually visible*/
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
          child: Image.network(imageUrl),
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
