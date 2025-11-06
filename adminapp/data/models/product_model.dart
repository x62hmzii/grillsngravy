import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final double price;
  final double? originalPrice;
  final String description;
  final String imageUrl;
  final String categoryId;
  final List<String> keywords;
  final bool featured;
  final bool active;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice,
    required this.description,
    required this.imageUrl,
    required this.categoryId,
    required this.keywords,
    this.featured = false,
    this.active = true,
    required this.createdAt,
  });

  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((originalPrice! - price) / originalPrice!) * 100;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'originalPrice': originalPrice,
      'description': description,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'keywords': keywords,
      'featured': featured,
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    // Handle price conversion safely
    double priceValue;
    if (map['price'] == null) {
      priceValue = 0.0; // Default value if price is null
    } else if (map['price'] is String) {
      priceValue = double.tryParse(map['price'] as String) ?? 0.0;
    } else {
      priceValue = (map['price'] as num).toDouble();
    }

    // Handle originalPrice conversion safely
    double? originalPriceValue;
    if (map['originalPrice'] != null) {
      if (map['originalPrice'] is String) {
        originalPriceValue = double.tryParse(map['originalPrice'] as String);
      } else {
        originalPriceValue = (map['originalPrice'] as num).toDouble();
      }
    }

    Timestamp timestamp;

    // Handle different timestamp formats
    if (map['createdAt'] is Timestamp) {
      timestamp = map['createdAt'] as Timestamp;
    } else if (map['createdAt'] is Map) {
      final createdAtMap = map['createdAt'] as Map<String, dynamic>;
      timestamp = Timestamp(
          createdAtMap['_seconds'] ?? 0,
          createdAtMap['_nanoseconds'] ?? 0
      );
    } else {
      timestamp = Timestamp.now();
    }

    return ProductModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      price: priceValue,
      originalPrice: originalPriceValue,
      description: map['description']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      categoryId: map['categoryId']?.toString() ?? '',
      keywords: List<String>.from(map['keywords'] ?? []),
      featured: map['featured'] ?? false,
      active: map['active'] ?? true,
      createdAt: timestamp.toDate(),
    );
  }
}