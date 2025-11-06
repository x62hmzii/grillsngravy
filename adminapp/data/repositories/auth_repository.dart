import 'package:firebase_auth/firebase_auth.dart';
import 'package:grillsngravy_admin/domain/exceptions/auth_exception.dart';

abstract class AuthRepository {
  Future<User?> signInWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  Future<bool> isAdminUser();
  Stream<User?> get authStateChanges;
}

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepositoryImpl({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Verify admin privileges with refreshed token
      final isAdmin = await _verifyAdminPrivileges(userCredential.user!);

      if (!isAdmin) {
        await _firebaseAuth.signOut();
        throw AuthException('Access denied. Admin privileges required.', code: 'admin-required');
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e), code: e.code);
    } catch (e) {
      throw AuthException('Login failed. Please try again.', code: 'unknown-error');
    }
  }

  Future<bool> _verifyAdminPrivileges(User user) async {
    try {
      // Force token refresh to get latest claims
      await user.reload();
      final refreshedUser = _firebaseAuth.currentUser;

      if (refreshedUser == null) return false;

      // Get fresh ID token with claims
      final idTokenResult = await refreshedUser.getIdTokenResult(true);
      final claims = idTokenResult.claims;

      return claims != null && claims['admin'] == true;
    } catch (e) {
      print('Error verifying admin privileges: $e');
      return false;
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No admin account found with this email.';
      case 'wrong-password':
        return 'Invalid password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This admin account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Login failed. Please check your credentials.';
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<bool> isAdminUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;

    return await _verifyAdminPrivileges(user);
  }

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}