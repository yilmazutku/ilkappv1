import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ImageUploadPage extends StatefulWidget {
  const ImageUploadPage({Key? key}) : super(key: key);

  @override
  _ImageUploadPageState createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;

  Future<void> getImage() async {
    final XFile? selectedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (selectedImage != null) {
      setState(() {
        _image = selectedImage;
      });
      await uploadFile(File(selectedImage.path));
    }
  }

  Future<void> uploadFile(File imgFile) async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      final userId = user!.uid;
      final fileName = path.basename(imgFile.path);
      final destination = '$userId/$fileName';

      final ref = FirebaseStorage.instance.ref(destination);
      await ref.putFile(imgFile);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image successfully uploaded!')),
      );
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during upload: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Image')),
      body: Center(
        child: _image == null
            ? const Text('No image selected.')
            : Image.file(File(_image!.path)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Pick Image', //externalize edilecek
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
