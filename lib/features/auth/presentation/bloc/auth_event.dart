part of 'auth_bloc.dart';

/// Base class for all auth events.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check authentication status on app startup.
class CheckAuthStatusEvent extends AuthEvent {}

/// Event to request OTP for email.
class RequestOtpEvent extends AuthEvent {
  final String email;

  const RequestOtpEvent({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Event to verify OTP.
class VerifyOtpEvent extends AuthEvent {
  final String email;
  final String otp;

  const VerifyOtpEvent({required this.email, required this.otp});

  @override
  List<Object?> get props => [email, otp];
}

/// Event to resend OTP.
class ResendOtpEvent extends AuthEvent {
  final String email;

  const ResendOtpEvent({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Event to get user profile.
class GetProfileEvent extends AuthEvent {}

/// Event to logout user.
class LogoutEvent extends AuthEvent {}

/// Event to clear error state.
class ClearAuthErrorEvent extends AuthEvent {}
