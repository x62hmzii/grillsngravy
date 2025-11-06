import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final DateTime createdAt;
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.createdAt,
    this.isAdmin = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAdmin': isAdmin,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    Timestamp timestamp;

    // Handle different timestamp formats
    if (map['createdAt'] is Timestamp) {
      timestamp = map['createdAt'] as Timestamp;
    } else if (map['createdAt'] is Map) {
      timestamp = Timestamp(map['createdAt']['_seconds'], map['createdAt']['_nanoseconds']);
    } else {
      timestamp = Timestamp.now();
    }

    return UserModel(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      phone: map['phone']?.toString(),
      createdAt: timestamp.toDate(),
      isAdmin: map['isAdmin'] ?? false,
    );
  }
}