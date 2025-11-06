import 'package:flutter/foundation.dart';
import 'package:grillsngravy_admin/data/repositories/auth_repository.dart';
import 'package:grillsngravy_admin/domain/exceptions/auth_exception.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider() : _authRepository = AuthRepositoryImpl();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;
  bool get hasSuccess => _successMessage != null;

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    _clearMessages();

    try {
      await _authRepository.signInWithEmailAndPassword(email, password);
      _successMessage = 'Login successful!';
    } catch (e) {
      // Handle all exceptions
      if (e is AuthException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _clearMessages();
    try {
      await _authRepository.signOut();
      _successMessage = 'Logged out successfully';
    } catch (e) {
      _errorMessage = 'Logout failed. Please try again.';
    } finally {
      notifyListeners();
    }
  }

  Future<bool> checkAdminStatus() async {
    try {
      return await _authRepository.isAdminUser();
    } catch (e) {
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }
}