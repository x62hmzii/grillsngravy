import 'package:flutter/foundation.dart';
import 'package:grillsngravy_admin/data/models/order_model.dart';
import 'package:grillsngravy_admin/services/firebase_admin_service.dart';

class DashboardProvider with ChangeNotifier {
  bool _isLoading = false;
  int _totalUsers = 0;
  int _totalOrders = 0;
  int _totalProducts = 0;
  double _totalRevenue = 0.0;
  int _todayOrders = 0;
  int _pendingOrders = 0;
  List<OrderModel> _recentOrders = [];

  bool get isLoading => _isLoading;
  int get totalUsers => _totalUsers;
  int get totalOrders => _totalOrders;
  int get totalProducts => _totalProducts;
  double get totalRevenue => _totalRevenue;
  int get todayOrders => _todayOrders;
  int get pendingOrders => _pendingOrders;
  List<OrderModel> get recentOrders => _recentOrders;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load all data in parallel for better performance
      await Future.wait([
        _loadUserStats(),
        _loadOrderStats(),
        _loadProductStats(),
        _loadRecentOrders(),
      ]);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading dashboard data: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserStats() async {
    try {
      _totalUsers = await FirebaseAdminService.getTotalUsers();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user stats: $e');
      }
      _totalUsers = 0;
    }
  }

  Future<void> _loadOrderStats() async {
    try {
      final stats = await FirebaseAdminService.getOrderStats();
      _totalOrders = stats['totalOrders'] ?? 0;
      _totalRevenue = (stats['totalRevenue'] ?? 0).toDouble();
      _todayOrders = stats['todayOrders'] ?? 0;
      _pendingOrders = stats['pendingOrders'] ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading order stats: $e');
      }
      _totalOrders = 0;
      _totalRevenue = 0.0;
      _todayOrders = 0;
      _pendingOrders = 0;
    }
  }

  Future<void> _loadProductStats() async {
    try {
      _totalProducts = await FirebaseAdminService.getTotalProducts();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading product stats: $e');
      }
      _totalProducts = 0;
    }
  }

  Future<void> _loadRecentOrders() async {
    try {
      _recentOrders = await FirebaseAdminService.getRecentOrders(limit: 5);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading recent orders: $e');
      }
      _recentOrders = [];
    }
  }
}