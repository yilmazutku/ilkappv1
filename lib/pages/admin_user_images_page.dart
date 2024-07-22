// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import '../commons/common.dart';
//
// ///admin panelinde bir kullanıcıya tıklandığında açılır. Recursive bir şekilde kjendini çağırır (? subject to change)
// class UserImagesPage extends StatefulWidget {
//   final String folderName;
//
//   const UserImagesPage({
//     super.key,
//     required this.folderName,
//     /*required this.selectedDateFilter*/
//   });
//
//   @override
//   createState() {
//     return _UserImagesPageState();
//   }
// }
//
// class _UserImagesPageState extends State<UserImagesPage> {
//   ListView? listview;
//   List<String> newImageUrls = [];
//   ViewType currentView = ViewType.list;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchImages();
//   }
//
//   Future<void> fetchImages() async {
//     {
//       String folderName = widget.folderName;
//       final ref =
//           FirebaseStorage.instance.ref('${Constants.urlUsers}$folderName');
//       final ListResult result = await ref.listAll();
//       List<String> imageUrls = [];
//       for (var fileRef in result.items) {
//         // var metadata = await fileRef.getMetadata();
//         // DateTime? createdTime = metadata.timeCreated;
//         // if (metadata != null) {
//         final url = await fileRef.getDownloadURL();
//         imageUrls.add(url);
//         //}
//       }
//       if (mounted) {
//         /*It is an error to call setState unless mounted is true.*/
//         setState(() {
//           if (imageUrls.isNotEmpty) {
//             newImageUrls = imageUrls;
//             listview = ListView.builder(
//               itemCount: imageUrls.length,
//               itemBuilder: (context, index) {
//                 return Image.network(imageUrls[index]);
//               },
//             );
//           } else {
//             //TODO optimize recursive func
//             List<String> folderNames =
//                 result.prefixes.map((folderRef) => folderRef.name).toList();
//             listview = ListView(
//                 children: folderNames
//                     .map((folderName) => ListTile(
//                           title: Text(folderName),
//                           onTap: () {
//                             Navigator.of(context).push(
//                               MaterialPageRoute(
//                                 builder: (context) => UserImagesPage(
//                                   folderName:
//                                       '${widget.folderName}/$folderName',
//                                   //selectedDateFilter: widget.selectedDateFilter,
//                                 ),
//                               ),
//                             );
//                           },
//                         ))
//                     .toList());
//           }
//         });
//       } else {
//         print('no mounting in user images page.');
//       }
//     }
//   }
//
//   Widget get getGridView {
//     return GridView.builder(
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 3, // Adjust the number of columns
//         crossAxisSpacing: 4.0,
//         mainAxisSpacing: 4.0,
//       ),
//       itemCount: newImageUrls.length,
//       itemBuilder: (context, index) {
//         /*builder is called only for those children that are actually visible*/
//         return InkWell(
//           onTap: () => showFullImage(context, newImageUrls[index]),
//           /*
//               Creates a widget that displays an ImageStream obtained from the network.
//               Either the width and height arguments should be specified, or the widget should be
//               placed in a context that sets tight layout constraints.
//               Otherwise, the image dimensions will change as the image is loaded, which will result in ugly layout changes
//            */
//           child: Image.network(
//             newImageUrls[index],
//             fit: BoxFit.cover,
//           ),
//         );
//       },
//     );
//   }
//
//   void showFullImage(BuildContext context, String imageUrl) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           child: Image.network(imageUrl),
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.folderName),
//         actions: <Widget>[
//           IconButton(
//             icon:
//                 Icon(currentView == ViewType.list ? Icons.grid_on : Icons.list),
//             onPressed: () {
//               setState(() {
//                 currentView = currentView == ViewType.list
//                     ? ViewType.grid
//                     : ViewType.list;
//               });
//             },
//           ),
//         ],
//       ),
//       body: currentView == ViewType.list ? listview : getGridView,
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/managers/admin_images_provider.dart';

import '../commons/common.dart';

class UserImagesPage extends StatelessWidget {
  const UserImagesPage({super.key,required String folderName});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminImagesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.folderStack.join('/')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            provider.navigateBack();
            if (provider.folderStack.length == 1) {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(provider.currentView == ViewType.list ? Icons.grid_on : Icons.list),
            onPressed: () {
              provider.toggleView();
            },
          ),
        ],
      ),
      body: provider.currentView == ViewType.list
          ? ListView.builder(
        itemCount: provider.newImageUrls.length + provider.folders.length,
        itemBuilder: (context, index) {
          if (index < provider.folders.length) {
            return ListTile(
              title: Text(provider.folders[index]),
              onTap: () {
                provider.navigateToFolder(provider.folders[index]);
              },
            );
          } else {
            return Image.network(provider.newImageUrls[index - provider.folders.length]);
          }
        },
      )
          : GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: provider.newImageUrls.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () => showFullImage(context, provider.newImageUrls[index]),
            child: Image.network(
              provider.newImageUrls[index],
              fit: BoxFit.cover,
            ),
          );
        },
      ),
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
}
