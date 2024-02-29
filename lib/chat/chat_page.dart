import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../commons/common.dart';
import '../managers/image_manager.dart';
import '../managers/chat_manager.dart';
// Import necessary Firebase libraries

class ChatPage extends StatelessWidget {
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
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  reverse: true,
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data()
                        as Map<String, dynamic>; // Cast the document to a Map
                    final msg = data['msg'] as String;
                    final txId = data['tx_id'] as String;
                    final imageUrl = data.containsKey('imageUrl')
                        ? data['imageUrl'] as String?
                        : null; // Check if imageUrl exists
                    return Column(
                      children: [
                        ListTile(
                          title: Text(msg),
                          subtitle: Text(txId),
                          //   trailing: imageUrl != null ? Image.network(imageUrl) : null, // Display image if available
                        ),
                        // if (imageUrl != null)
                        //   Image.network(imageUrl),
                        if (imageUrl !=
                            null) // Conditionally display the image if the URL exists
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 72.0, bottom: 8.0),
                            /**
                             * Wrap the Image.network widget with a GestureDetector or
                             * InkWell widget and handle the onTap event to show the image
                             * in a larger view.
                             */
                            child: /*Image.network(imageUrl, fit: BoxFit.cover)*/
                                GestureDetector(
                              onTap: () {
                                showImageDialog(context,
                                    imageUrl); // Function to show the image in a dialog
                              },
                              child: Image.network(
                                imageUrl,
                                width: MediaQuery.of(context).size.width *
                                    0.3, // 80% of screen width
                                height: MediaQuery.of(context).size.height *
                                    0.1, // 50% of screen height
                              ),
                            ),
                          ),
                      ],
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
                  onPressed:chatManager.sendMessage
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () async => {
                    image = await picker.pickImage(source: ImageSource.gallery),
                   chatManager.sendMessage(image:image)
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width:
                MediaQuery.of(context).size.width * 0.8, // 80% of screen width
            height: MediaQuery.of(context).size.height *
                0.5, // 50% of screen height
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}
