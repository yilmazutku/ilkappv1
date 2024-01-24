
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
  _ImageUploadPageState createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  // final ImagePicker _picker = ImagePicker();
  XFile? _image;

  bool isUploading=false;

//   Future getImage() async {
//     // final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
// // _image=Image.asset('assets/ecl trg.png') as XFile?;
//     setState(() {
//       // if (pickedFile != null) {
//       //   _image = pickedFile;
//       //   uploadFile();
//       // } else {
//       //   print('No image selected.');
//       // }r
//       _image= XFile('assets/ecl trg.png');
//       // _image=File('assets/ecl trg.png') as XFile?;
//       uploadFile();
//     });
//   }
  Future getImage() async {
    // Path for the asset
    const assetPath = 'assets/ecl trg.PNG';

    // Load the byte data of the image
    final byteData = await rootBundle.load(assetPath);

    // Get temporary directory
    final tempDir = await getTemporaryDirectory();
    final tempPath = path.join(tempDir.path, 'ecl trg.PNG');

    // Write the bytes to a temporary file
    final file = await File(tempPath).writeAsBytes(
        byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes)
    );
    _image = XFile(file.path);
    final fileExists = await File(_image!.path).exists();
    print('File exists: $fileExists'); // This should print true
    if (fileExists) {
      // uploadFile();
    } else {
      print('File does not exist. Cannot upload.');
    }
    print('Future getImage is called.');
    setState(() {
      // Create an XFile from the file path
 if(_image!=null) {
   print('isUploading=false within setState.');
   isUploading=true;
   uploadFile();
 }
    });
  }
  Future uploadFile() async {
    if (_image == null) return;
    var user = FirebaseAuth.instance.currentUser;
    final userId=user!.uid;
    final fileName = _image!.name;
    final destination = '$userId/$fileName';

    try {
      print('Future uploadFile is called.');
      final ref = FirebaseStorage.instance.ref(destination);
      print(' final ref = done');
      var file = File(_image!.path);
      await ref.putFile(file);
      print('ref.putFile done');
      isUploading=false;
    } catch (e) {
      print(e);
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(title: const Text('Upload Image')),
  //     body: Center(
  //       child: _image == null
  //           ? const Text('No image selected.')
  //           : Image.file(File(_image!.path)),
  //     ),
  //     floatingActionButton: FloatingActionButton(
  //       onPressed: getImage,
  //       tooltip: 'Pick Image',
  //       child: const Icon(Icons.add_a_photo),
  //     ),
  //   ); // Corrected the parenthesis here
  // }

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
