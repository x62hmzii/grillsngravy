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
    DateTime createdAt;

    try {
      if (map['createdAt'] is Timestamp) {
        createdAt = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is Map) {
        final timestampMap = map['createdAt'] as Map<String, dynamic>;
        final seconds = timestampMap['_seconds'] as int? ?? 0;
        final nanoseconds = timestampMap['_nanoseconds'] as int? ?? 0;
        createdAt = DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + (nanoseconds ~/ 1000000),
        );
      } else if (map['createdAt'] is String) {
        createdAt = DateTime.parse(map['createdAt'] as String);
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      print('Error parsing createdAt: $e');
      createdAt = DateTime.now();
    }

    return UserModel(
      id: map['id']?.toString() ?? map['uid']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? map['displayName']?.toString() ?? 'Unknown User',
      phone: map['phone']?.toString(),
      createdAt: createdAt,
      isAdmin: map['isAdmin'] ?? false,
    );
  }
}