import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../commons/common.dart';
import '../managers/image_manager.dart';
import '../managers/chat_manager.dart';
// Import necessary Firebase libraries

class ChatPage extends StatelessWidget  {

  final String adminId = 'admin'; // Example admin ID
  final String fieldTxid = 'tx_id';
  final String fieldRxid = 'rx_id';
  final String fieldMsg = 'msg';
  final String fieldTimestamp = 'timestamp';

  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ImagePicker picker = ImagePicker();
    final chatManager = Provider.of<ChatManager>(context);
    final imageManager = Provider.of<ImageManager>(context);
    XFile? image;
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: chatManager.getMessagesStream(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  reverse: true,
                  children: snapshot.data!.docs.map((doc) {
                    return ListTile(
                      title: Text(doc[fieldMsg]),
                      subtitle: Text(doc[fieldTxid]),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: chatManager.messageController,
                    decoration:
                        const InputDecoration(labelText: 'Enter a message...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: chatManager.sendMessage,
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () async => {
                    image =
                        await picker.pickImage(source: ImageSource.gallery),
                    imageManager.uploadFile(image, null)
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
