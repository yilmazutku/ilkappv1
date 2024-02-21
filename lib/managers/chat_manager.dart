import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../commons/common.dart';

class ChatManager extends ChangeNotifier {
  final TextEditingController messageController = TextEditingController();
  final String adminId = 'admin'; // Example admin ID
  final String chatId = 'chat_id2'; // Static chat ID for simplicity

  Future<void> sendMessage() async {
    if (messageController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection(Constants.urlChats)
          .doc(chatId)
          .collection('messages')
          .add({
        'tx_id': FirebaseAuth.instance.currentUser!.uid,
        'rx_id': adminId,
        'msg': messageController.text,
        'timestamp': Timestamp.now(),
      });
      messageController.clear();
      notifyListeners();
    }
  }

  Stream<QuerySnapshot> getMessagesStream() {
    return FirebaseFirestore.instance
        .collection(Constants.urlChats)
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
