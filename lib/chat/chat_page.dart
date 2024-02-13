import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../commons/common.dart';
// Import necessary Firebase libraries

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  // Add chat logic with Firebase

  @override
  createState() {
    return _ChatPageState();
  }
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final String adminId = 'admin'; // Example admin ID
  final String fieldTxid = 'tx_id';
  final String fieldRxid = 'rx_id';
  final String fieldMsg = 'msg';
  final String fieldTimestamp = 'timestamp';

  Future<void> sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection(Constants.urlChats)
          .doc('chat_id2') // Use appropriate chat ID
          .collection('messages')
          .add({
        fieldTxid: FirebaseAuth.instance.currentUser!.uid,
        fieldRxid: adminId,
        fieldMsg: _messageController.text,
        fieldTimestamp: Timestamp.now(),
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc('chat_id2') // Use appropriate chat ID
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
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
                    controller: _messageController,
                    decoration:
                        const InputDecoration(labelText: 'Enter a message...'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
