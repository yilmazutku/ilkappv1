import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageUploadPage extends StatefulWidget {
  const ImageUploadPage({super.key});

  @override
  createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  // final ImagePicker _picker = ImagePicker();
  XFile? _image;

  Future getImage() async {
    // Path for the asset
    const assetPath = 'assets/';
    String imgName='ecl trg.PNG';
    // Load the byte data of the image
    File file = await _generateFileFromPath(assetPath,imgName);

    if (_image != null) {
      _image = XFile(file.path);
      File? imgFile;

      final fileExists = await File(_image!.path).exists();
      if (fileExists) {
        imgFile = File(_image!.path);
      } else {
        print('File does not exist. Cannot upload.');
      }
      print('Future getImage is called.');
      setState(() {
        if (imgFile != null) {
          uploadFile(imgFile);
        }
      });
    } else {
      print('constructed XFile img is null.');
    }
  }

  Future<File> _generateFileFromPath(String assetPath, String imgName) async {
    final byteData = await rootBundle.load(assetPath);

    // Get temporary directory
    final tempDir = await getTemporaryDirectory();
    final tempPath = path.join(tempDir.path,imgName);

    // Write the bytes to a temporary file
    final file = await File(tempPath).writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return file;
  }

  Future uploadFile(File imgFile) async {
    if (_image == null) return;
    var user = FirebaseAuth.instance.currentUser;
    final userId = user!.uid;
    final fileName = _image!.name;
    final destination = '$userId/$fileName';

    try {
      final ref = FirebaseStorage.instance.ref(destination);
      await ref.putFile(imgFile);
      print('ref.putFile is done');
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Image')),
      body: Center(
        // child: Image.asset('assets/ecl trg.png'),
        child: _image == null
            ? const Text('No image selected.')
            : Image.file(File(_image!.path)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Pick Image',
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
