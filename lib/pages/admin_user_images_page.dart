
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/managers/admin_images_manager.dart';

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
