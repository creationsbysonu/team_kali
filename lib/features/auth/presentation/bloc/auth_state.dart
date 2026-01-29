part of 'auth_bloc.dart';

/// Base class for all auth states.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any auth action.
class AuthInitial extends AuthState {}

/// Loading state while performing auth operations.
class AuthLoading extends AuthState {}

/// State when user is authenticated.
class Authenticated extends AuthState {
  final UserEntity user;
  final bool isNewUser;
  final bool isProfileComplete;

  const Authenticated({
    required this.user,
    this.isNewUser = false,
    this.isProfileComplete = false,
  });

  @override
  List<Object?> get props => [user, isNewUser, isProfileComplete];
}

/// State when user is not authenticated.
class Unauthenticated extends AuthState {}

/// State when OTP has been sent successfully.
class OtpSent extends AuthState {
  final String email;

  const OtpSent({required this.email});

  @override
  List<Object?> get props => [email];
}

/// State when OTP has been resent successfully.
class OtpResent extends AuthState {
  final String email;

  const OtpResent({required this.email});

  @override
  List<Object?> get props => [email];
}

/// State when an error occurs during auth.
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
