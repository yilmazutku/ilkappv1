import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../models/logger.dart';
import '../models/meal_model.dart';
import '../models/user_model.dart';
import 'delete_file_mobile.dart';
import 'file_handler.dart'; // New conditional import

final Logger log = Logger.forClass(FileHandlerPage);

/*
Suggested Improvements:
- Added more robust error handling in _parseFileContent and _extractSubtitles.
- Added user feedback using Snackbar when the user forgets to select a user or when file selection is canceled.
*/

class FileHandlerPage extends StatefulWidget {
  const FileHandlerPage({super.key});

  @override
  createState() => _FileHandlerPageState();
}

class _FileHandlerPageState extends State<FileHandlerPage> {
  String? _localFilePath;
  List<Map<String, dynamic>> subtitles = [];

  Map<String, String> _userMap = {}; // Store userId as key and userName as value
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
        title: const Text('Liste Yükleyici'),
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
          _selectedUser = newValue; // newValue will be the user ID
        });
      },
      items: _userMap.entries.map<DropdownMenuItem<String>>((entry) {
        return DropdownMenuItem<String>(
          value: entry.key, // Use user ID as value
          child: Text(entry.value), // Display user name
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
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
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
      final QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('users').get();
      final List<QueryDocumentSnapshot> documents = querySnapshot.docs;

      setState(() {
        _userMap = {for (var doc in documents) doc.id: UserModel.fromDocument(doc).name};
      });

      log.info('Fetched user list: {}', [_userMap]);
    } catch (e) {
      log.err('Error fetching user list: {}', [e.toString()]);
      _showSnackbar('Error fetching user list.');
    }
  }

  /// Step 2: Pick a file, save it to a temporary local directory, and parse it
  Future<void> _pickAndSaveFile() async {
    if (_selectedUser == null) {
      log.warn('Please select a user first.');
      _showSnackbar('Please select a user first.');
      return;
    }
    for (var subtitle in subtitles) {
      subtitle['content'].clear();  // Clear the content list
      subtitle['time'] = '-';  // Reset the time field
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
      withData: true,
    );

    if (result != null) {
      try {
        Uint8List? fileBytes = result.files.single.bytes;
        String fileName = result.files.single.name;

        if (fileBytes != null) {
          await handleFile(fileBytes, fileName, _onFileProcessed, _onFileProcessingError);
        }
      } catch (e) {
        _onFileProcessingError(e.toString());
      }
    } else {
      log.info('File selection canceled.');
      _showSnackbar('File selection canceled.');
    }
  }

  void _onFileProcessed(String text, String filePath) {
    setState(() {
      _localFilePath = filePath;
    });
    _extractSubtitles(text);
    _uploadContentToFirestore();
  }

  void _onFileProcessingError(String error) {
    log.err('Error processing file: {}', [error]);
    _showSnackbar('Error processing file: $error');
  }

  void _extractSubtitles(String text) {
    log.info('text={}', [text]);

    // Split the text into lines and clean it
    final lines = text
        .split(RegExp(r'\r\n|\r|\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
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

        log.info('Extracted time for subtitle {}: {}',
            [currentSubtitle['name'], currentSubtitle['time']]);
      }
      // If no subtitle is found but there's a current subtitle, treat the line as content
      else if (currentSubtitle != null) {
        log.info('Adding content to subtitle {}: {}',
            [currentSubtitle['name'], line]);

        // Add content to the current subtitle's content list
        currentSubtitle['content'].add({
          'content': line,
        });
      } else {
        log.warn(
            'No subtitle found and no active subtitle for line: {}', [line]);
      }
    }

    log.info('Parsed subtitles: {}', [subtitles]);
  }

  /// Updated Step 4: Upload the parsed content to Cloud Firestore
  Future<void> _uploadContentToFirestore() async {
    if (_selectedUser == null) {
      log.warn('No user selected for upload.');
      _showSnackbar('No user selected for upload.');
      return;
    }

    String currentDateTime = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    String documentPath = 'users/$_selectedUser/dietlists/$currentDateTime';

    try {
      List<Map<String, dynamic>> dataToUpload = subtitles.map((subtitle) {
        return {
          'name': subtitle['name'],
          'time': subtitle['time'],
          'content': subtitle['content'],
        };
      }).toList();

      DocumentReference ref = FirebaseFirestore.instance.doc(documentPath);
      await ref.set({
        'uploadTime': FieldValue.serverTimestamp(),
        'subtitles': dataToUpload,
      });

      log.info('Diet list uploaded at: {}', [documentPath]);
    } catch (e) {
      log.err('Error uploading diet list: {}', [e.toString()]);
      _showSnackbar('Failed to upload diet list.');
    }
  }


  /// Step 5: Delete the file from the temporary directory

  Future<void> _deleteFile() async {
    if (_localFilePath != null) {
      try {
        await deleteFile(_localFilePath!);
        log.info('File deleted.');

        setState(() {
          _localFilePath = null;
          // Clear subtitles
          for (var subtitle in subtitles) {
            subtitle['content'].clear();
            subtitle['time'] = 'Not Specified'; // Reset time
          }
        });

        _showSnackbar('File deleted successfully.');
      } catch (e) {
        log.err('Error deleting file: {}', [e.toString()]);
        _showSnackbar('Error deleting file: ${e.toString()}');
      }
    } else {
      _showSnackbar('No file to delete.');
    }
  }

  /// Helper method to show Snackbars for user feedback
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
