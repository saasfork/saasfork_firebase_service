abstract class AuthException implements Exception {
  final String message;
  final String code;

  AuthException(this.message, this.code);

  @override
  String toString() => message;

  // Constantes pour les codes d'erreur
  static const String userNotFoundCode = 'user_not_found';
  static const String invalidCredentialsCode = 'invalid_credentials';
  static const String emailAlreadyInUseCode = 'email_already_in_use';
  static const String recentLoginRequiredCode = 'recent_login_required';
  static const String invalidEmailCode =
      'invalid_email'; // Ajout de la constante pour email invalide
  static const String unknownCode = 'unknown';
}

class UserNotFoundException extends AuthException {
  UserNotFoundException()
    : super('No user found with this email', AuthException.userNotFoundCode);
}

class InvalidCredentialsException extends AuthException {
  InvalidCredentialsException()
    : super('Incorrect password', AuthException.invalidCredentialsCode);
}

class EmailAlreadyInUseException extends AuthException {
  EmailAlreadyInUseException()
    : super(
        'This email address is already in use',
        AuthException.emailAlreadyInUseCode,
      );
}

class RecentLoginRequiredException extends AuthException {
  RecentLoginRequiredException()
    : super(
        'This operation requires a recent login. Please sign in again.',
        AuthException.recentLoginRequiredCode,
      );
}

class InvalidEmailException extends AuthException {
  InvalidEmailException()
    : super(
        'The email address provided is invalid',
        AuthException.invalidEmailCode,
      );
}

class UnknownAuthException extends AuthException {
  UnknownAuthException(String message)
    : super(message, AuthException.unknownCode);
}
