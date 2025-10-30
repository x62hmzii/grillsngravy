import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final bool active;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.active = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    Timestamp timestamp;

    // Handle different timestamp formats
    if (map['createdAt'] is Timestamp) {
      timestamp = map['createdAt'] as Timestamp;
    } else if (map['createdAt'] is Map) {
      timestamp = Timestamp(map['createdAt']['_seconds'], map['createdAt']['_nanoseconds']);
    } else {
      timestamp = Timestamp.now();
    }

    return CategoryModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      active: map['active'] ?? true,
      createdAt: timestamp.toDate(),
    );
  }
}