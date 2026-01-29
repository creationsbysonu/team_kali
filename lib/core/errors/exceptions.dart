/// Exception classes for the data layer.
/// These are thrown by data sources and caught in repositories.
library;

class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException({this.message = 'Server error occurred', this.statusCode});

  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;

  CacheException({this.message = 'Cache error occurred'});

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;

  NetworkException({this.message = 'Network error occurred'});

  @override
  String toString() => message;
}

class AuthenticationException implements Exception {
  final String message;

  AuthenticationException({this.message = 'Authentication failed'});

  @override
  String toString() => message;
}

class RateLimitException implements Exception {
  final String message;
  final int? retryAfter;

  RateLimitException({
    this.message = 'Too many requests. Please try again later.',
    this.retryAfter,
  });

  @override
  String toString() => message;
}

class OtpException implements Exception {
  final String message;
  final int? attemptsRemaining;

  OtpException({
    this.message = 'OTP verification failed',
    this.attemptsRemaining,
  });

  @override
  String toString() => message;
}
