import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/logger.dart';

class DietDocument {
  final String docId;
  final DateTime? uploadTime;
  final List<dynamic> subtitles;

  DietDocument({
    required this.docId,
    required this.uploadTime,
    required this.subtitles,
  });

  factory DietDocument.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    final uploadTime = (data?['uploadTime'] as Timestamp?)?.toDate();
    final subtitles = data?['subtitles'] ?? [];
    return DietDocument(
      docId: doc.id,
      uploadTime: uploadTime,
      subtitles: subtitles,
    );
  }

  String get displayName {
    // docId often like "20230101_1145"; or use uploadTime if you prefer
    // Adjust format if needed:
    if (uploadTime != null) {
      final dateStr = '${uploadTime!.year}-${uploadTime!.month.toString().padLeft(2, '0')}-${uploadTime!.day.toString().padLeft(2, '0')}';
      return 'liste_$dateStr';
    }
    return 'liste_${docId}';
  }
}