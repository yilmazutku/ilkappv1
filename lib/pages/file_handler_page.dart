import 'dart:io';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Cloud Firestore
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:untitled/commons/logger.dart';

final Logger log = Logger.forClass(FileHandlerPage);

class FileHandlerPage extends StatefulWidget {
  const FileHandlerPage({super.key});

  @override
  createState() => _FileHandlerPageState();
}

class _FileHandlerPageState extends State<FileHandlerPage> {
  String? _localFilePath;
  Map<String, List<String>> subtitles = {
    'Subtitle 1': [],
    'Subtitle 2': [],
    'Subtitle 3': [],
    'Subtitle 4': [],
  };
  List<String> _userList = [];
  String? _selectedUser;

  @override
  void initState() {
    super.initState();
    _fetchUserList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste Yukleyici'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _userDropdown(), // Dropdown to select user
            ElevatedButton(
              onPressed: _pickAndSaveFile,
              child: const Text('Pick and Parse File'),
            ),
            const SizedBox(height: 20),
            _localFilePath != null
                ? Text('File saved at: $_localFilePath')
                : const Text('No file selected.'),
            const SizedBox(height: 20),
            _buildParsedContent(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _deleteFile,
              child: const Text('Delete File'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userDropdown() {
    return DropdownButton<String>(
      value: _selectedUser,
      hint: const Text('Select a User'),
      onChanged: (String? newValue) {
        setState(() {
          _selectedUser = newValue;
        });
      },
      items: _userList.map<DropdownMenuItem<String>>((String user) {
        return DropdownMenuItem<String>(
          value: user,
          child: Text(user),
        );
      }).toList(),
    );
  }

  Widget _buildParsedContent() {
    if (_localFilePath == null) return Container();

    return Expanded(
      child: ListView.builder(
        itemCount: subtitles.length,
        itemBuilder: (context, index) {
          String key = subtitles.keys.elementAt(index);
          List<String> values = subtitles[key]!;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                for (var value in values) Text('- $value'),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Fetch user list from Cloud Firestore
  Future<void> _fetchUserList() async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('userinfo').get();
      final List<QueryDocumentSnapshot> documents = querySnapshot.docs;

      setState(() {
        _userList = documents.map((doc) => doc.id).toList();
      });

      log.info('Fetched user list: {}', [_userList]);
    } catch (e) {
      log.err('Error fetching user list: {}', [e.toString()]);
    }
  }

  /// Step 2: Pick a file, save it to a temporary local directory, and parse it
  Future<void> _pickAndSaveFile() async {
    if (_selectedUser == null) {
      log.warn('Please select a user first.');
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx', 'pdf'], // Allows DOCX or PDF files
    );

    if (result != null) {
      String? selectedFilePath = result.files.single.path;

      if (selectedFilePath != null) {
        Directory tempDir = await getTemporaryDirectory();
        String fileName = path.basename(selectedFilePath);
        File localFile = File('${tempDir.path}/$fileName');
        await File(selectedFilePath).copy(localFile.path);

        setState(() {
          _localFilePath = localFile.path;
        });

        await _parseFileContent(localFile);
        await _uploadContentToFirestore(); // Updated to upload to Firestore
      }
    } else {
      log.info('File selection canceled.');
    }
  }

  /// Step 3: Parse the content of the file to extract subtitles
  Future<void> _parseFileContent(File file) async {
    final bytes = await file.readAsBytes();
    String text = docxToText(bytes);
    subtitles.forEach((key, value) => value.clear());
    _extractSubtitles(text);
    setState(() {});
  }

  void _extractSubtitles(String text) {
    final lines = text.split(RegExp(r'\r\n|\r|\n')).map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    String? currentSubtitle;

    for (var line in lines) {
      if (subtitles.containsKey(line)) {
        log.info('Found subtitle: {}', [line]);
        currentSubtitle = line;
      } else if (currentSubtitle != null) {
        subtitles[currentSubtitle]!.add(line);
      }
    }
    log.info('Parsed text: {}', [subtitles]);
  }

  /// Updated Step 4: Upload the parsed content to Cloud Firestore
  Future<void> _uploadContentToFirestore() async {
    if (_selectedUser == null) {
      log.warn('No user selected for upload.');
      return;
    }

    // Generate a unique path with current date and time
    String currentDateTime = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    String documentPath = 'userinfo/$_selectedUser/dietlists/$currentDateTime';

    try {
      // Convert subtitles map to a structure suitable for Firestore
      Map<String, dynamic> dataToUpload = {};
      subtitles.forEach((subtitle, lines) {
        dataToUpload[subtitle] = lines;
      });

      // Upload to Cloud Firestore
      DocumentReference ref = FirebaseFirestore.instance.doc(documentPath);
      await ref.set(dataToUpload);

      log.info('Diet list stored successfully at path: {}', [documentPath]);
    } catch (e) {
      log.err('Failed to upload diet list: {}', [e.toString()]);
    }
  }

  /// Step 5: Delete the file from the temporary directory
  Future<void> _deleteFile() async {
    if (_localFilePath != null) {
      File file = File(_localFilePath!);
      if (await file.exists()) {
        await file.delete();
        log.info('File deleted.');

        setState(() {
          _localFilePath = null;
          subtitles.forEach((key, value) => value.clear());
        });
      }
    }
  }
}
