import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'document_reader.dart';


import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'document_reader.dart'; // Import the DocumentReader class

class PdfParserPage extends StatefulWidget {
  @override
  _PdfParserPageState createState() => _PdfParserPageState();
}

class _PdfParserPageState extends State<PdfParserPage> {
  String _pdfContent = "Select a PDF file to parse.";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Parser'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickAndParsePdf,
              child: Text('Pick and Parse PDF'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Text(_pdfContent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndParsePdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // Ensures that we get the file bytes directly
    );

    if (result != null) {
      // On web, use the bytes property
      Uint8List? fileBytes = result.files.single.bytes;

      if (fileBytes != null) {
        // Use the DocumentReader class to parse the PDF
        final documentReader = DocumentReader();
        await documentReader.readPdfFile(fileBytes);

        // Extracted subtitles and their lines
        final subtitles = documentReader.subtitles;

        // Convert the extracted data to a string for display
        final StringBuffer displayContent = StringBuffer();

        subtitles.forEach((subtitle, lines) {
          displayContent.writeln(subtitle);
          for (var line in lines) {
            displayContent.writeln(' - $line');
          }
          displayContent.writeln(); // Add an extra line for spacing
        });

        setState(() {
          _pdfContent = displayContent.toString();
        });
      } else {
        setState(() {
          _pdfContent = "Error: Unable to read file content.";
        });
      }
    } else {
      setState(() {
        _pdfContent = "File selection canceled.";
      });
    }
  }
}
