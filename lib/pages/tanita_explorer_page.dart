import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meas_provider.dart';
import '../models/logger.dart';
import 'package:url_launcher/url_launcher.dart'; // for opening PDF in browser/app

final Logger log = Logger.forClass(TanitaExplorerPage);

class TanitaExplorerPage extends StatefulWidget {
  final String userId;
  const TanitaExplorerPage({super.key, required this.userId});

  @override
  State<TanitaExplorerPage> createState() => _TanitaExplorerPageState();
}

class _TanitaExplorerPageState extends State<TanitaExplorerPage> {
  late Future<List<TanitaPdfModel>> _pdfListFuture;

  @override
  void initState() {
    super.initState();
    _pdfListFuture = _fetchTanitaPdfs();
  }

  Future<List<TanitaPdfModel>> _fetchTanitaPdfs() async {
    // We assume each doc in "users/{userId}/measurements/tanita" has fields
    // { "pdfUrl": ..., "fileName": ..., "uploadTime": ... }
    final collectionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('measurements')
        .doc('tanita')                 // optional: you could do a subcollection
        .collection('pdfFiles');       // or you can store them in "users/{u}/measurements/tanita" directly
    final snapshot = await collectionRef.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return TanitaPdfModel(
        docId: doc.id,
        pdfUrl: data['pdfUrl'] ?? '',
        fileName: data['fileName'] ?? '',
        uploadTime: (data['uploadTime'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  Future<void> _pickAndUploadPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) {
      log.info('No PDF selected.');
      return;
    }

    final file = result.files.single;
    final fileBytes = file.bytes;
    final filePath = file.path;
    final fileName = file.name; // e.g. "document.pdf"

    if (fileBytes == null) {
      // If bytes are null, maybe read them from file path
      if (filePath != null) {
        final f = File(filePath);
        if (await f.exists()) {
          final readBytes = await f.readAsBytes();
          await _uploadToProvider(fileName, readBytes);
        }
      }
    } else {
      await _uploadToProvider(fileName, fileBytes);
    }
  }

  Future<void> _uploadToProvider(String fileName, List<int> fileBytes) async {
    final provider = Provider.of<MeasProvider>(context, listen: false);
    try {
      await provider.uploadTanitaPdfFile(
        userId: widget.userId,
        fileName: fileName,
        fileBytes: fileBytes,
      );
      setState(() {
        // re-fetch PDF list to refresh UI
        _pdfListFuture = _fetchTanitaPdfs();
      });
    } catch (e) {
      log.err('Error uploading PDF: {}', [e]);
     if(mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF yükleme hatası: $e')),
      );
     }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tanita PDF Listesi'),
        actions: [
          TextButton.icon(
            onPressed: _pickAndUploadPdf,
            icon: const Icon(Icons.add),
            label: const Text('Ekle'), // Add "Ekle" text
            style: TextButton.styleFrom(
              foregroundColor: Colors.white, // Set text/icon color (matches AppBar)
            ),
          ),
        ],

      ),
      body: FutureBuilder<List<TanitaPdfModel>>(
        future: _pdfListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          final pdfList = snapshot.data ?? [];
          if (pdfList.isEmpty) {
            return const Center(child: Text('Hiç PDF dosyası yok.'));
          }
          return ListView.builder(
            itemCount: pdfList.length,
            itemBuilder: (context, index) {
              final pdf = pdfList[index];
              return ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(pdf.fileName),
                subtitle: Text(pdf.uploadTime?.toLocal().toString() ?? ''),
                onTap: () async {
                  // Open PDF URL in external PDF viewer or browser
                  if (await canLaunchUrl(Uri.parse(pdf.pdfUrl))) {
                    await launchUrl(Uri.parse(pdf.pdfUrl),
                        mode: LaunchMode.externalApplication
                    );
                  } else {
                    if(mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('PDF açılamadı: ${pdf.pdfUrl}')),
                    );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// A small model for a Tanita PDF
class TanitaPdfModel {
  final String docId;
  final String pdfUrl;
  final String fileName;
  final DateTime? uploadTime;

  TanitaPdfModel({
    required this.docId,
    required this.pdfUrl,
    required this.fileName,
    required this.uploadTime,
  });
}
