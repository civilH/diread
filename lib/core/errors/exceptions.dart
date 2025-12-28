class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  NetworkException([String message = 'Network error occurred'])
      : super(message, code: 'NETWORK_ERROR');
}

class ServerException extends AppException {
  final int? statusCode;

  ServerException(String message, {this.statusCode})
      : super(message, code: 'SERVER_ERROR');
}

class AuthException extends AppException {
  AuthException(String message) : super(message, code: 'AUTH_ERROR');
}

class UnauthorizedException extends AuthException {
  UnauthorizedException([String message = 'Unauthorized'])
      : super(message);
}

class TokenExpiredException extends AuthException {
  TokenExpiredException([String message = 'Token expired'])
      : super(message);
}

class InvalidCredentialsException extends AuthException {
  InvalidCredentialsException([String message = 'Invalid credentials'])
      : super(message);
}

class UserAlreadyExistsException extends AuthException {
  UserAlreadyExistsException([String message = 'User already exists'])
      : super(message);
}

class ValidationException extends AppException {
  final Map<String, dynamic>? errors;

  ValidationException(String message, {this.errors})
      : super(message, code: 'VALIDATION_ERROR', details: errors);
}

class FileException extends AppException {
  FileException(String message) : super(message, code: 'FILE_ERROR');
}

class FileTooLargeException extends FileException {
  FileTooLargeException([String message = 'File too large'])
      : super(message);
}

class InvalidFileTypeException extends FileException {
  InvalidFileTypeException([String message = 'Invalid file type'])
      : super(message);
}

class StorageException extends AppException {
  StorageException(String message) : super(message, code: 'STORAGE_ERROR');
}

class CacheException extends AppException {
  CacheException(String message) : super(message, code: 'CACHE_ERROR');
}

class NotFoundException extends AppException {
  NotFoundException([String message = 'Resource not found'])
      : super(message, code: 'NOT_FOUND');
}
