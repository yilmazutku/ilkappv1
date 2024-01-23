import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
class ImageUploadPage extends StatefulWidget {
  const ImageUploadPage({super.key});

  @override
  _ImageUploadPageState createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  File? _image;
  final picker = ImagePicker();

  Future getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Image'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image == null ? const Text('No image selected.') : Image.file(_image!),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => getImage(ImageSource.camera),
              child: const Text('Pick from Camera'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => getImage(ImageSource.gallery),
              child: const Text('Pick from Gallery'),
            ),
          ],
        ),
      ),
    );
  }
}
