// image_manager.dart

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../commons/logger.dart';
import '../models/meal_model.dart';

class UploadResult {
  final String? downloadUrl;
  final String? errorMessage;

  bool get isUploadOk => downloadUrl != null && errorMessage == null;

  UploadResult({this.downloadUrl, this.errorMessage});
}

class ImageManager extends ChangeNotifier {
  final Logger logger = Logger.forClass(ImageManager);

  Future<UploadResult> uploadFile(File? imageFile,
      {Meals? meal, required String userId}) async {
    if (imageFile == null) {
      return UploadResult(errorMessage: 'No image selected for upload.');
    }

    try {
      String fileName = imageFile.path.split('/').last;
      String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String path;

      if (meal != null) {
        path = 'users/$userId/mealPhotos/$date/${meal.name}/$fileName';
      } else {
        path = 'users/$userId/chatPhotos/$date/$fileName';
      }

      Reference ref = FirebaseStorage.instance.ref(path);
      logger.debug('Uploading file to path: $path');

      UploadTask uploadTask = ref.putFile(imageFile);

      await uploadTask;

      // After uploading, get the download URL
      String downloadUrl = await ref.getDownloadURL();
      logger.info('Uploaded file to path: $path, downloadUrl: $downloadUrl');
      return UploadResult(downloadUrl: downloadUrl);
    } on FirebaseException catch (e) {
      logger.err('FirebaseException Error during file upload: {}', [e]);
      return UploadResult(errorMessage: e.message);
    } catch (e2) {
      logger.err('Unexpected error during file upload: {}', [e2]);
      return UploadResult(
          errorMessage: 'An unexpected error occurred during photo upload.');
    }
  }
}
