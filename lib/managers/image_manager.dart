import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../commons/common.dart';

class ImageManager extends ChangeNotifier {
  //singleton pattern
  // late ImageManager manager;
  //
  // ImageManager get getManager {
  //   manager ??= ImageManager();
  //   return manager;
  // }

  Future<String?> uploadFile(XFile? image, {Meals? meal}) async {
    if (image != null) {
      try {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        String fileName = image.path.split('/').last;
        String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
        String path = '${Constants.urlUsers}$userId';
        if (meal != null) {
          path = '$path/${Constants.urlMealPhotos}$date/${meal.url}$fileName';
        } else {
          //chatphoto
          path = '$path/${Constants.urlChatPhotos}$date/$fileName';
        }
        Reference ref = FirebaseStorage.instance.ref(path);
        print('isChatPhoto=${meal == null}, uploading File path=$path');
        await ref.putFile(File(image.path));
        // After uploading, get the download URL
        String downloadUrl = await ref.getDownloadURL();
        print('uploaded File path=$path, downloadUrl=$downloadUrl');
        return downloadUrl; // Return the URL of the uploaded image
        // if (!mounted) return;
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Image uploaded for $meal')),
        // );
      } on FirebaseException {
        // if (!mounted) return;
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text(e.message ?? 'Error during file upload')),
        // );
      }
    } else {
      print('No image is selected.');
      return null; // Return null if no image was selected or upload failed
    }
    return null;
  }
}
