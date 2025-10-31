import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grillsngravy/data/models/product_model.dart';

class CartItem {
  final String id;
  final ProductModel product;
  int quantity;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.addedAt,
  });

  double get totalPrice => product.price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'quantity': quantity,
      'addedAt': addedAt,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map, ProductModel product) {
    return CartItem(
      id: map['id'] ?? '',
      product: product,
      quantity: map['quantity'] ?? 1,
      addedAt: (map['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class Cart {
  final List<CartItem> items;

  Cart({required this.items});

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get deliveryFee => 100.0; // Fixed delivery fee

  double get total => subtotal + deliveryFee;

  bool get isEmpty => items.isEmpty;

  void addItem(CartItem newItem) {
    final existingIndex = items.indexWhere((item) => item.product.id == newItem.product.id);
    if (existingIndex != -1) {
      items[existingIndex].quantity += newItem.quantity;
    } else {
      items.add(newItem);
    }
  }

  void removeItem(String productId) {
    items.removeWhere((item) => item.product.id == productId);
  }

  void updateQuantity(String productId, int newQuantity) {
    final itemIndex = items.indexWhere((item) => item.product.id == productId);
    if (itemIndex != -1) {
      if (newQuantity <= 0) {
        items.removeAt(itemIndex);
      } else {
        items[itemIndex].quantity = newQuantity;
      }
    }
  }

  void clear() {
    items.clear();
  }
}