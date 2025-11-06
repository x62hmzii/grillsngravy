import 'package:flutter/foundation.dart';
import 'package:grillsngravy_admin/data/models/order_model.dart';
import 'package:grillsngravy_admin/services/firebase_admin_service.dart';

class OrderProvider with ChangeNotifier {
  bool _isLoading = false;
  List<OrderModel> _orders = [];
  List<OrderModel> _filteredOrders = [];
  String _searchQuery = '';
  String _statusFilter = 'all';

  bool get isLoading => _isLoading;
  List<OrderModel> get orders => _filteredOrders;
  List<OrderModel> get allOrders => _orders;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  // Status options for filter
  final List<String> statusOptions = [
    'all',
    'pending',
    'confirmed',
    'preparing',
    'delivered',
    'cancelled'
  ];

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get all orders from Firebase
      final ordersStream = FirebaseAdminService.getAllOrders();
      await for (final orders in ordersStream) {
        _orders = orders;
        _applyFilters();
        break; // Take first snapshot
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading orders: $e');
      }
      _orders = [];
      _filteredOrders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyFilters();
  }

  void _applyFilters() {
    List<OrderModel> filtered = List.from(_orders);

    // Apply status filter
    if (_statusFilter != 'all') {
      filtered = filtered.where((order) =>
      order.status.toLowerCase() == _statusFilter.toLowerCase()
      ).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((order) {
        final orderId = order.id.toLowerCase();
        final customerName = order.shippingAddress.fullName.toLowerCase();
        final customerPhone = order.shippingAddress.phone.toLowerCase();

        return orderId.contains(_searchQuery) ||
            customerName.contains(_searchQuery) ||
            customerPhone.contains(_searchQuery);
      }).toList();
    }

    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _filteredOrders = filtered;
    notifyListeners();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseAdminService.updateOrderStatus(orderId, newStatus);

      // Update local state
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(status: newStatus);
        _applyFilters();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating order status: $e');
      }
      rethrow;
    }
  }

  Future<void> refreshOrders() async {
    await loadOrders();
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = 'all';
    _applyFilters();
  }

  // Get statistics
  Map<String, int> getOrderStatistics() {
    final stats = <String, int>{
      'total': _orders.length,
      'pending': _orders.where((order) => order.status == 'pending').length,
      'confirmed': _orders.where((order) => order.status == 'confirmed').length,
      'preparing': _orders.where((order) => order.status == 'preparing').length,
      'delivered': _orders.where((order) => order.status == 'delivered').length,
      'cancelled': _orders.where((order) => order.status == 'cancelled').length,
    };

    return stats;
  }
}