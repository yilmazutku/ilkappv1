import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String password; // For Firebase user creation
  final String role; // 'admin' or 'customer'
  final DateTime createdAt;
  final String? surname;
  final int? age;
  final String? reference;
  final String? notes;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.createdAt,
    this.surname,
    this.age,
    this.reference,
    this.notes,
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      password: '', // Password should not be stored in Firestore
      role: data['role'] ?? 'customer',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      surname: data['surname'],
      age: data['age'],
      reference: data['reference'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      if (surname != null) 'surname': surname,
      if (age != null) 'age': age,
      if (reference != null) 'reference': reference,
      if (notes != null) 'notes': notes,
    };
  }

  @override
  String toString() {
    return 'UserModel{userId: $userId, name: $name, email: $email, role: $role, createdAt: $createdAt, surname: $surname, age: $age, reference: $reference, notes: $notes}';
  }
}
