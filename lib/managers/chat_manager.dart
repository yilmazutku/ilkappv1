import 'dart:ffi';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../commons/common.dart';
import 'image_manager.dart';

class ChatManager extends ChangeNotifier {
  final TextEditingController _messageController = TextEditingController();
  TextEditingController get messageController => _messageController;

  final String adminId = 'admin'; // Example admin ID
  //final String chatId = 'chat_id2'; // Static chat ID for simplicity
  final String chatId = FirebaseAuth.instance.currentUser!.uid;
  final ImageManager imageManager;
  ChatManager({required this.imageManager});

  Future<void> sendMessage({XFile? image}) async {
    String? imageUrl;
    if (image != null) {
      imageUrl = await imageManager.uploadFile(image); // Upload image and get URL
    }

    // Create MessageData object including the imageUrl if available
    MessageData message = MessageData(
      msg: _messageController.text,
      timestamp: Timestamp.now(),
      imageUrl: imageUrl,
    );

    await FirebaseFirestore.instance
        .collection(Constants.urlChats)
        .doc(chatId)
        .collection('messages')
        .add(message.toJson());
    _messageController.clear();
    notifyListeners();
  }
  //Asset yükleyerek denemek için
  // Future<String?> uploadAssetImage(String assetPath) async {
  //   try {
  //     // Load the image from assets
  //     ByteData byteData = await rootBundle.load(assetPath);
  //     Uint8List imageData = byteData.buffer.asUint8List();
  //
  //     final userId = FirebaseAuth.instance.currentUser!.uid;
  //     String fileName = assetPath.split('/').last;
  //     String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  //     String path = '${Constants.urlUsers}$userId';
  //
  //     // Determine the path based on whether it's a meal photo or a chat photo
  //       path = '$path/${Constants.urlChatPhotos}/$date/$fileName';
  //
  //     // Upload the byte data as a file
  //     Reference ref = FirebaseStorage.instance.ref(path);
  //     await ref.putData(imageData);
  //
  //     // After uploading, get the download URL
  //     String downloadUrl = await ref.getDownloadURL();
  //     return downloadUrl;
  //   } catch (e) {
  //     print('Error uploading asset image: $e');
  //   }
  // }
  Stream<QuerySnapshot> getMessagesStream() {
    return FirebaseFirestore.instance
        .collection(Constants.urlChats)
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
