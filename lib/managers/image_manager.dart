import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../commons/common.dart';
import '../commons/logger.dart';

class UploadResult {
  final String? downloadUrl;
  final String? errorMessage;

  bool get isUploadOk => downloadUrl != null && errorMessage == null;

  UploadResult({this.downloadUrl, this.errorMessage});
}

class ImageManager extends ChangeNotifier {
  final Logger logger = Logger.forClass(ImageManager);

  //singleton pattern
  // late ImageManager manager;
  //
  // ImageManager get getManager {
  //   manager ??= ImageManager();
  //   return manager;
  // }

  Future<UploadResult> uploadFile(XFile? image, {Meals? meal}) async {
    if (image != null) {
      try {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        String fileName = image.path.split('/').last;
        String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
        String path;
        if (meal != null) {
          path = 'users/$userId/mealPhotos/$date/${meal.url}/$fileName';
        } else {
          path = 'users/$userId/chatPhotos/$date/$fileName';
        }
        Reference ref = FirebaseStorage.instance.ref(path);
        logger.debug('Uploading file to path: $path');
        await ref.putFile(File(image.path));
        // After uploading, get the download URL
        String downloadUrl = await ref.getDownloadURL();
        logger.info('Uploaded file to path: $path, downloadUrl: $downloadUrl');
        return UploadResult(downloadUrl: downloadUrl);
        // if (!mounted) return;
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Image uploaded for $meal')),
        // );
      } on FirebaseException catch (e) {
        logger.err('FirebaseException Error during file upload:{}', [e]);
        return UploadResult(errorMessage: e.message);
      } on Exception catch (e2) {
        logger.err('Unexpected error during file upload:{}', [e2]);
        return UploadResult(
            errorMessage: 'Fotoğraf yüklenirken beklenmeyen bir hata oluştu.');
      }
    } else {
      //logger.warn('No image selected for upload.');
      return UploadResult();
    }
  }
}
