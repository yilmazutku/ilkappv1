// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import '../commons/common.dart';
// import 'image_manager.dart';
//
// class ChatManager extends ChangeNotifier {
//   final TextEditingController _messageController = TextEditingController();
//
//   TextEditingController get messageController => _messageController;
//
//   final String adminId = 'admin'; // Example admin ID
//   final String chatId = FirebaseAuth.instance.currentUser!.uid;
//   final ImageManager imageManager;
//
//   ChatManager({required this.imageManager});
//
//   Future<void> sendMessage({XFile? image}) async {
//     String? imageUrl;
//     if (image != null) {
//       UploadResult result =
//           await imageManager.uploadFile(image); // Upload image and get URL
//       imageUrl = result.downloadUrl;
//     }
//     imageUrl = imageUrl ?? 'hatalı';
//     // Create MessageData object including the imageUrl if available
//     MessageData message = MessageData(
//       msg: _messageController.text,
//       timestamp: Timestamp.now(),
//       imageUrl: imageUrl, //null olabilir
//     );
//
//     await FirebaseFirestore.instance
//         .collection(Constants.urlChats)
//         .doc(chatId)
//         .collection('messages')
//         .add(message.toJson());
//     _messageController.clear();
//     notifyListeners();
//   }
//
//   Stream<QuerySnapshot> getMessagesStream() {
//     return FirebaseFirestore.instance
//         .collection(Constants.urlChats)
//         .doc(chatId)
//         .collection('messages')
//         .orderBy('timestamp', descending: true)
//         .snapshots();
//   }
//
//   @override
//   void dispose() {
//     // Clean up the controller when the widget is disposed.
//     _messageController.dispose();
//     super.dispose();
//   }
// }
