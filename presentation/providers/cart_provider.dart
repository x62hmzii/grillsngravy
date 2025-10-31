import 'package:flutter/foundation.dart';
import 'package:grillsngravy/data/models/cart_model.dart';
import 'package:grillsngravy/data/models/product_model.dart';
import 'package:grillsngravy/services/firebase_service.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _cartItems = [];
  bool _isLoading = false;

  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  int get totalItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get deliveryFee => 100.0;
  double get total => subtotal + deliveryFee;
  bool get isEmpty => _cartItems.isEmpty;

  Future<void> loadCart() async {
    if (FirebaseService.currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final stream = FirebaseService.getUserCartItems(FirebaseService.currentUser!.uid);
      await for (final items in stream) {
        _cartItems = items;
        notifyListeners();
        break; // Take first snapshot
      }
    } catch (e) {
      print('Error loading cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(CartItem newItem) async {
    if (FirebaseService.currentUser == null) return;

    try {
      await FirebaseService.addToCart(
        userId: FirebaseService.currentUser!.uid,
        productId: newItem.product.id,
        quantity: newItem.quantity,
      );

      // Reload cart to get updated data
      await loadCart();
    } catch (e) {
      print('Error adding to cart: $e');
      rethrow;
    }
  }

  Future<void> updateQuantity(String productId, int newQuantity) async {
    if (FirebaseService.currentUser == null) return;

    try {
      await FirebaseService.updateCartQuantity(
        userId: FirebaseService.currentUser!.uid,
        productId: productId,
        quantity: newQuantity,
      );

      // Reload cart to get updated data
      await loadCart();
    } catch (e) {
      print('Error updating cart quantity: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(String productId) async {
    if (FirebaseService.currentUser == null) return;

    try {
      await FirebaseService.removeFromCart(
        userId: FirebaseService.currentUser!.uid,
        productId: productId,
      );

      // Reload cart to get updated data
      await loadCart();
    } catch (e) {
      print('Error removing from cart: $e');
      rethrow;
    }
  }

  Future<void> clearCart() async {
    if (FirebaseService.currentUser == null) return;

    try {
      await FirebaseService.clearCart(FirebaseService.currentUser!.uid);
      _cartItems.clear();
      notifyListeners();
    } catch (e) {
      print('Error clearing cart: $e');
      rethrow;
    }
  }
  // method to your CartProvider class
  void clearCartOnLogout() {
    _cartItems.clear();
    notifyListeners();
  }

  bool isProductInCart(String productId) {
    return _cartItems.any((item) => item.product.id == productId);
  }

  int getProductQuantity(String productId) {
    final item = _cartItems.firstWhere(
          (item) => item.product.id == productId,
      orElse: () => CartItem(
        id: '',
        product: ProductModel(
          id: '',
          name: '',
          price: 0,
          description: '',
          imageUrl: '',
          categoryId: '',
          keywords: [],
          createdAt: DateTime.now(),
        ),
        quantity: 0,
        addedAt: DateTime.now(),
      ),
    );
    return item.quantity;
  }
}