// image_manager.dart


import 'dart:typed_data'; // Import for Uint8List

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/logger.dart';
import '../models/meal_model.dart';

class UploadResult {
  final String? downloadUrl;
  final String? errorMessage;

  bool get isUploadOk => downloadUrl != null && errorMessage == null;

  UploadResult({this.downloadUrl, this.errorMessage});
}

class ImageManager extends ChangeNotifier {
  static final Logger logger = Logger.forClass(ImageManager);

  Future<UploadResult> uploadFile(XFile? imageFile,
      {Meals? meal, required String userId}) async {
    if (imageFile == null) {
      return UploadResult(errorMessage: 'No image selected for upload.');
    }

    try {
      String fileName = imageFile.name;
      String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String path;

      if (meal != null) {
        path = 'users/$userId/mealPhotos/$date/${meal.name}/$fileName';
      } else {
        path = 'users/$userId/chatPhotos/$date/$fileName';
      }

      Reference ref = FirebaseStorage.instance.ref(path);
      logger.debug('Uploading file to path: $path');

      // Read the file as bytes
      Uint8List imageData = await imageFile.readAsBytes();

      // Determine the content type
      String? mimeType = imageFile.mimeType;
      if (mimeType == null) {
        // Infer from file extension if mimeType is null
        if (fileName.toLowerCase().endsWith('.png')) {
          mimeType = 'image/png';
        } else if (fileName.toLowerCase().endsWith('.jpg') ||
            fileName.toLowerCase().endsWith('.jpeg')) {
          mimeType = 'image/jpeg';
        } else {
          mimeType = 'application/octet-stream';
        }
      }

      SettableMetadata metadata = SettableMetadata(contentType: mimeType);

      // UploadTask uploadTask = ref.putData(imageData, metadata);
      await ref.putData(imageData, metadata);

     // await uploadTask;

      // After uploading, get the download URL
      String downloadUrl = await ref.getDownloadURL();
      logger.info('Uploaded file to path: $path, downloadUrl: $downloadUrl');
      return UploadResult(downloadUrl: downloadUrl);
    } on FirebaseException catch (e) {
      logger.err('FirebaseException Error during file upload: {}', [e.message??'exception does not have message.']);
      return UploadResult(errorMessage: e.message);
    } catch (e2) {
      logger.err('Unexpected error during file upload: {}', [e2.toString()]);
      return UploadResult(
          errorMessage: 'An unexpected error occurred during photo upload.');
    }
  }

  Future<void> deleteFile(String imageUrl) async {
    try {
      final Reference ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
      logger.info('Deleted file at URL: $imageUrl');
    } catch (e) {
      logger.err('Error deleting file at URL {}: {}', [imageUrl, e.toString()]);
    }
  }

}
