part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {
  final bool forceCheck;
  CheckAuthStatusEvent({this.forceCheck = false});

  @override
  List<Object?> get props => [forceCheck];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  final String? placeSlug;
  final String? ministrySlug;
  final String? serviceSlug;

  LoginEvent({
    required this.email,
    required this.password,
    this.placeSlug,
    this.ministrySlug,
    this.serviceSlug,
  });

  @override
  List<Object?> get props => [
    email,
    password,
    placeSlug,
    ministrySlug,
    serviceSlug,
  ];
}

class LogoutEvent extends AuthEvent {}
