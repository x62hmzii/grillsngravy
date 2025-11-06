import 'package:flutter/foundation.dart';
import 'package:grillsngravy_admin/data/models/user_model.dart';
import 'package:grillsngravy_admin/services/firebase_admin_service.dart';
import 'dart:async';

class UserProvider with ChangeNotifier {
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<UserModel>>? _usersSubscription;

  List<UserModel> get allUsers => _allUsers;
  List<UserModel> get filteredUsers => _filteredUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  void loadUsers() {
    // Cancel existing subscription
    _usersSubscription?.cancel();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Listen to real-time stream
      _usersSubscription = FirebaseAdminService.getAllUsers().listen(
            (users) {
          _allUsers = users;
          _filteredUsers = users;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = 'Failed to load users: ${error.toString()}';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to load users: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchUsers(String query) {
    if (query.isEmpty) {
      _filteredUsers = _allUsers;
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredUsers = _allUsers.where((user) {
        return user.email.toLowerCase().contains(lowerQuery) ||
            user.fullName.toLowerCase().contains(lowerQuery) ||
            (user.phone?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Naya complete deletion function use karein
      await FirebaseAdminService.deleteUserCompletely(userId);

      // Remove from local lists (fast UI update)
      _allUsers.removeWhere((user) => user.id == userId);
      _filteredUsers.removeWhere((user) => user.id == userId);

      notifyListeners();

    } catch (e) {
      _errorMessage = 'Failed to delete user: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    super.dispose();
  }
}