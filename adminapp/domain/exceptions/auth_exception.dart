class AuthException implements Exception {
  final String message;
  final String code;

  AuthException(this.message, {this.code = 'unknown'});

  @override
  String toString() => 'AuthException: $message';
}