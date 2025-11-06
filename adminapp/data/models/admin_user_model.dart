import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUser {
  final String uid;
  final String email;
  final String displayName;
  final bool isAdmin;
  final DateTime lastLogin;
  final DateTime createdAt;

  AdminUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.isAdmin,
    required this.lastLogin,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'isAdmin': isAdmin,
      'lastLogin': lastLogin,
      'createdAt': createdAt,
    };
  }

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      lastLogin: (map['lastLogin'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}