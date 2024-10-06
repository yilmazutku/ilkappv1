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
/*
o1-preview önerisi:
Error Handling and Edge Cases
User Authentication Null Check:

Improvement: Before accessing currentUser!.uid, check if FirebaseAuth.instance.currentUser is not null to avoid potential crashes.
dart
Copy code
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  // Handle the case where the user is not logged in
  return UploadResult(errorMessage: 'User not authenticated.');
}
final userId = user.uid;
File Existence and Accessibility:

Ensure that the file at image.path still exists and is accessible before attempting to upload.
 */
/// MealUploadPage kullanır resim yüklerken.
class ImageManager extends ChangeNotifier {
  final Logger logger = Logger.forClass(ImageManager);

  Future<UploadResult> uploadFile(XFile? image, {Meals? meal}) async {
    if (image != null) {
      try {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        String fileName = image.path.split('/').last;
        String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
        String path;
        if (meal != null) {
          path = 'users/$userId/mealPhotos/$date/${meal.url}/$fileName';
        }
        /**
         * Aşağısı  gpt o1-preview önerisi:
         *Suggestions for Improvement
            A. Storing the Download URL in Firestore
            After uploading the image and obtaining the download URL, it's essential to store this URL in
            Firestore within the relevant document. Here's how you can modify your code:
         */

        // if (meal != null) {
        //   // Create a new meal document or update an existing one
        //   final mealDocRef = FirebaseFirestore.instance
        //       .collection('users')
        //       .doc(userId)
        //       .collection('meals')
        //       .doc(); // Use a generated ID or specify one
        //
        //   MealModel mealModel = MealModel(
        //     mealId: mealDocRef.id,
        //     mealType: meal,
        //     imageUrl: downloadUrl,
        //     timestamp: DateTime.now(),
        //     // Include other required fields
        //   );
        //
        //   await mealDocRef.set(mealModel.toMap());
        // }

        else {
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
