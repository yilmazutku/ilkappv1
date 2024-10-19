import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../commons/logger.dart';
import '../models/test_model.dart';

class AddTestDialog extends StatefulWidget {
  final String userId;
  final Function onTestAdded;

  const AddTestDialog({
    super.key,
    required this.userId,
    required this.onTestAdded,
  });

  @override
  createState() => _AddTestDialogState();
}

class _AddTestDialogState extends State<AddTestDialog> {
  final Logger logger = Logger.forClass(AddTestDialog);

  // Controllers and variables
  final TextEditingController _testNameController = TextEditingController();
  final TextEditingController _testDescriptionController =
      TextEditingController();
  DateTime? _selectedTestDate;
  File? _testFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Test'),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            TextField(
              controller: _testNameController,
              decoration: const InputDecoration(labelText: 'Test Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _testDescriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_selectedTestDate == null
                  ? 'Select Test Date'
                  : 'Test Date: ${_selectedTestDate!.toLocal().toString().split(' ')[0]}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedTestDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedTestDate = pickedDate;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _pickTestFile(),
              child: const Text('Upload Test File'),
            ),
            const SizedBox(height: 16),
            _testFile != null
                ? Text('File selected: ${_testFile!.path.split('/').last}')
                : const Text('No file selected'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _addTest(),
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Add Test'),
        ),
      ],
    );
  }

  Future<void> _pickTestFile() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    // Alternatively, use `pickImage` for images or `pickVideo` for videos
    // For PDFs, you might need to use a different package like `file_picker`

    if (pickedFile != null) {
      setState(() {
        _testFile = File(pickedFile.path);
        logger.info('Test file selected: {}', [pickedFile.path]);
      });
    } else {
      logger.err('No test file selected.');
    }
  }

  Future<void> _addTest() async {
    if (_testNameController.text.isEmpty ||
        _selectedTestDate == null ||
        _testFile == null) {
      logger.err('Please fill all required fields.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Upload the test file
      String testFileUrl = await _uploadTestFile();

      // Create a new test document
      final testDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('tests')
          .doc(); // Generate a new test ID

      TestModel testModel = TestModel(
        testId: testDocRef.id,
        userId: widget.userId,
        testName: _testNameController.text,
        testDescription: _testDescriptionController.text,
        testDate: _selectedTestDate!,
        testFileUrl: testFileUrl,
      );

      await testDocRef.set(testModel.toMap());
      logger.info('Test added successfully for user {}', [widget.userId]);

      // Notify parent widget to refresh data
      widget.onTestAdded();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop(); // Close the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test added successfully.')),
      );
    } catch (e) {
      logger.err('Error adding test: {}', [e]);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding test: $e')),
      );
    }
  }

  Future<String> _uploadTestFile() async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_testFile!.path.split('/').last}';
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/${widget.userId}/tests/$fileName');
      final uploadTask = ref.putFile(_testFile!);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      logger.info('Test file uploaded: {}', [downloadUrl]);

      return downloadUrl;
    } catch (e) {
      logger.err('Error uploading test file: {}', [e]);
      throw Exception('Error uploading test file: $e');
    }
  }

  @override
  void dispose() {
    _testNameController.dispose();
    _testDescriptionController.dispose();
    super.dispose();
  }
}
