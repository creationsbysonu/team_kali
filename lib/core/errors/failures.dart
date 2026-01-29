import 'package:equatable/equatable.dart';

/// Failure classes for the domain layer.
/// These are returned from repositories using Either type.

abstract class Failure extends Equatable {
  final String message;

  const Failure({this.message = ''});

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Server failure occurred'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache failure occurred'});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection'});
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure({super.message = 'Authentication failed'});
}

class ValidationFailure extends Failure {
  const ValidationFailure({super.message = 'Validation failed'});
}

class RateLimitFailure extends Failure {
  final int? retryAfter;

  const RateLimitFailure({
    super.message = 'Too many requests. Please try again later.',
    this.retryAfter,
  });

  @override
  List<Object> get props => [message, retryAfter ?? 0];
}

class OtpFailure extends Failure {
  final int? attemptsRemaining;

  const OtpFailure({
    super.message = 'OTP verification failed',
    this.attemptsRemaining,
  });

  @override
  List<Object> get props => [message, attemptsRemaining ?? 0];
}
