import 'package:cloud_firestore/cloud_firestore.dart';

class TestModel {
  final String testId;
  final String userId;
  final String testName;
  final String? testDescription;
  final DateTime testDate;
  final String? testFileUrl; // URL to the uploaded test file (image, PDF)

  TestModel({
    required this.testId,
    required this.userId,
    required this.testName,
    this.testDescription,
    required this.testDate,
    this.testFileUrl,
  });

  factory TestModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TestModel(
      testId: doc.id,
      userId: data['userId'],
      testName: data['testName'],
      testDescription: data['testDescription'],
      testDate: (data['testDate'] as Timestamp).toDate(),
      testFileUrl: data['testFileUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'testName': testName,
      'testDescription': testDescription,
      'testDate': Timestamp.fromDate(testDate),
      'testFileUrl': testFileUrl,
    };
  }
}