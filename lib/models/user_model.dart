import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String role; // 'admin' or 'customer'
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      name: data['name'],
      email: data['email'],
      role: data['role'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  @override
  String toString() {
    return 'UserModel{userId: $userId, name: $name, email: $email, role: $role, createdAt: $createdAt}';
  }

  Map<String, dynamic> toMap() {
    return {
      'userId':userId,
      'name': name,
      'email': email,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}