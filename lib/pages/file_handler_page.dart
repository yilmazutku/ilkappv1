import 'dart:io';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Cloud Firestore
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:untitled/commons/logger.dart';

import '../commons/common.dart';

final Logger log = Logger.forClass(FileHandlerPage);
/*
Suggested Improvements:
Add more robust error handling in _parseFileContent and _extractSubtitles.
Use user feedback (e.g., dialog, Snackbar) when the user forgets to select a user or when file selection is canceled.
 */
class FileHandlerPage extends StatefulWidget {
  const FileHandlerPage({super.key});

  @override
  createState() => _FileHandlerPageState();
}

class _FileHandlerPageState extends State<FileHandlerPage> {
  String? _localFilePath;
  List<Map<String, dynamic>> subtitles = [];

  List<String> _userList = [];
  String? _selectedUser;

  @override
  void initState() {
    super.initState();
    for (var meal in Meals.values) {
      subtitles.add({
        'name': meal.label,
        'time': meal.defaultTime,
        'content': [],
      });
    }
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
          final subtitle = subtitles[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${subtitle['name']} \t ${subtitle['time']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                for (var content in subtitle['content'])
                  Text('- ${content['content']}'),
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

    // Clear the previous subtitle data
    for (var subtitle in subtitles) {
      subtitle['content'].clear();
      subtitle['time'] = 'Not Specified'; // Reset time for each subtitle
    }

    _extractSubtitles(text);
    setState(() {});
  }


  void _extractSubtitles(String text) {
    log.info('text={}', [text]);

    // Split the text into lines and clean it
    final lines = text.split(RegExp(r'\r\n|\r|\n')).map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    Map<String, dynamic>? currentSubtitle;

    for (var line in lines) {
      log.info('Processing line: {}', [line]);

      // Check if the line contains any of the subtitles
      var foundSubtitle = subtitles.firstWhere(
            (subtitle) => line.contains(subtitle['name']),
        orElse: () => {},
      );

      // If a new subtitle is found, set it as the current subtitle
      if (foundSubtitle.isNotEmpty) {
        log.info('Found subtitle: {}', [foundSubtitle['name']]);
        currentSubtitle = foundSubtitle;

        // Extract numeric time part for the subtitle, if present
        final timeMatch = RegExp(r'(\d{1,2}:\d{2})').firstMatch(line);
        currentSubtitle['time'] = timeMatch?.group(0) ?? '';

        log.info('Extracted time for subtitle {}: {}', [currentSubtitle['name'], currentSubtitle['time']]);
      }
      // If no subtitle is found but there's a current subtitle, treat the line as content
      else if (currentSubtitle != null) {
        log.info('Adding content to subtitle {}: {}', [currentSubtitle['name'], line]);

        // Add content to the current subtitle's content list
        currentSubtitle['content'].add({
          'content': line,
        });
      } else {
        log.warn('No subtitle found and no active subtitle for line: {}', [line]);
      }
    }

    log.info('Parsed subtitles: {}', [subtitles]);
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
      // Convert subtitles list to a structure suitable for Firestore
      List<Map<String, dynamic>> dataToUpload = subtitles.map((subtitle) {
        return {
          'name': subtitle['name'],
          'time': subtitle['time'],
          'content': subtitle['content'],
        };
      }).toList();

      // Upload to Cloud Firestore
      DocumentReference ref = FirebaseFirestore.instance.doc(documentPath);
      await ref.set({
        'uploadTime': FieldValue.serverTimestamp(), // Automatically store current server time
        'subtitles': dataToUpload //        // Other document fields...
      });
      //await ref.set({'subtitles': dataToUpload});
      documentPath = 'userinfo/$_selectedUser/currentDietList';

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
          // Clear subtitles
          for (var subtitle in subtitles) {
            subtitle['content'].clear();
            subtitle['time'] = 'Not Specified'; // Reset time
          }
        });
      }
    }
  }
}
