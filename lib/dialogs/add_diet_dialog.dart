import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Replace with your actual imports
import '../models/logger.dart';
import '../models/meal_model.dart';       // For Meals enum
import '../diet_list_pages/file_handler.dart';    // For handleFile
import '../diet_list_pages/delete_file_mobile.dart'; // For deleteFile

/// We'll create a logger for this dialog
final Logger log = Logger.forClass(AddDietDialog);

class AddDietDialog extends StatefulWidget {
  final String userId; // Which user to upload diets for

  const AddDietDialog({super.key, required this.userId});

  @override
  State<AddDietDialog> createState() => _AddDietDialogState();
}

class _AddDietDialogState extends State<AddDietDialog> {
  // Subtitles structure, same as FileHandlerPage
  List<Map<String, dynamic>> subtitles = [];

  // Local file path where docx is saved
  String? _localFilePath;
  // Track whether we've parsed and have a preview
  bool _hasParsedPreview = false;

  @override
  void initState() {
    super.initState();
    // Initialize subtitles with Meals enum
    for (var meal in Meals.values) {
      subtitles.add({
        'name': meal.label,
        'time': meal.defaultTime, // from meal_model.dart
        'content': [],
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Diyet Yükle'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: _hasParsedPreview ? _buildParsedContent() : _buildPickFileButton(),
      ),
      actions: _hasParsedPreview
          ? _buildParsedButtons()
          : [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat'))],
    );
  }

  /// 1) Show a button for picking/parsing file if we haven't yet
  Widget _buildPickFileButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _pickAndSaveFile,
        child: const Text('Pick and Parse .docx'),
      ),
    );
  }

  /// 2) Show a preview of parsed subtitles if we have them
  Widget _buildParsedContent() {
    if (_localFilePath == null) {
      return const Center(child: Text('No file selected.'));
    }

    // A scrollable ListView of subtitles
    return Column(
      children: [
        Text('File saved at: $_localFilePath'),
        const SizedBox(height: 10),
        Expanded(
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
        ),
      ],
    );
  }

  /// 3) Actions once we have preview: “Vazgeç” or “Onayla”
  List<Widget> _buildParsedButtons() {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context), // just close
        child: const Text('Vazgeç'),
      ),
      ElevatedButton(
        onPressed: _uploadContentToFirestore,
        child: const Text('Onayla'),
      ),
    ];
  }

  /// Replicates _pickAndSaveFile from FileHandlerPage, minus the user dropdown
  Future<void> _pickAndSaveFile() async {
    // Clear any old parse data
    for (var subtitle in subtitles) {
      subtitle['content'].clear();
      subtitle['time'] = '-';
    }
    _localFilePath = null;
    _hasParsedPreview = false;

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
          // handleFile is from your file_handler.dart
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

  /// Called once file_handler.dart finishes reading the docx into plain text
  void _onFileProcessed(String text, String filePath) {
    setState(() {
      _localFilePath = filePath;
    });
    // Now parse the text into subtitles
    _extractSubtitles(text);
    // Show the preview
    setState(() {
      _hasParsedPreview = true;
    });
  }

  void _onFileProcessingError(String error) {
    log.err('Error processing file: {}', [error]);
    _showSnackbar('Error processing file: $error');
  }

  /// EXACT logic from your FileHandlerPage’s _extractSubtitles
  void _extractSubtitles(String text) {
    log.info('text={}', [text]);

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

      if (foundSubtitle.isNotEmpty) {
        log.info('Found subtitle: {}', [foundSubtitle['name']]);
        currentSubtitle = foundSubtitle;

        // Extract numeric time part if present
        final timeMatch = RegExp(r'(\d{1,2}:\d{2})').firstMatch(line);
        currentSubtitle['time'] = timeMatch?.group(0) ?? '';

        log.info('Extracted time for subtitle {}: {}',
            [currentSubtitle['name'], currentSubtitle['time']]);
      } else if (currentSubtitle != null) {
        // If we have an active subtitle, treat this line as content
        log.info('Adding content to subtitle {}: {}',
            [currentSubtitle['name'], line]);
        currentSubtitle['content'].add({
          'content': line,
        });
      } else {
        log.warn('No subtitle found and no active subtitle for line: {}', [line]);
      }
    }

    log.info('Parsed subtitles: {}', [subtitles]);
  }

  /// EXACT logic from your FileHandlerPage’s _uploadContentToFirestore
  Future<void> _uploadContentToFirestore() async {
    final userId = widget.userId;
    if (userId.isEmpty) {
      log.warn('No userId provided. Cannot upload.');
      _showSnackbar('No userId provided. Cannot upload.');
      return;
    }

    final currentDateTime = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final documentPath = 'users/$userId/dietlists/$currentDateTime';

    try {
      // Prepare data to upload
      final dataToUpload = subtitles.map((subtitle) {
        return {
          'name': subtitle['name'],
          'time': subtitle['time'],
          'content': subtitle['content'],
        };
      }).toList();

      final ref = FirebaseFirestore.instance.doc(documentPath);
      await ref.set({
        'uploadTime': FieldValue.serverTimestamp(),
        'subtitles': dataToUpload,
      });

      log.info('Diet list uploaded at: {}', [documentPath]);
      Navigator.pop(context); // Close dialog
    } catch (e) {
      log.err('Error uploading diet list: {}', [e.toString()]);
      _showSnackbar('Failed to upload diet list: $e');
    }
  }

  /// Optionally, if you want to let user delete the local file from this dialog,
  /// you could add a button calling _deleteFile. (But not required if you only want Onayla/Vazgeç)

  /*
  Future<void> _deleteFile() async {
    if (_localFilePath != null) {
      try {
        await deleteFile(_localFilePath!);
        setState(() {
          _localFilePath = null;
          for (var subtitle in subtitles) {
            subtitle['content'].clear();
            subtitle['time'] = 'Not Specified';
          }
          _hasParsedPreview = false;
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
  */

  /// Helper for user feedback
  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
