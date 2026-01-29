import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/auth/domain/entities/otp_credentials.dart';
import 'package:sewa_sathi/features/auth/domain/entities/user_entity.dart';
import 'package:sewa_sathi/features/auth/domain/usecases/auth_usecases.dart';
import 'package:sewa_sathi/features/profile/domain/usecases/check_profile_status_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC for managing authentication state.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RequestOtpUseCase requestOtp;
  final VerifyOtpUseCase verifyOtp;
  final ResendOtpUseCase resendOtp;
  final GetProfileUseCase getProfile;
  final LogoutUseCase logout;
  final CheckAuthStatusUseCase checkAuthStatus;
  final CheckProfileStatusUseCase checkProfileStatus;

  AuthBloc({
    required this.requestOtp,
    required this.verifyOtp,
    required this.resendOtp,
    required this.getProfile,
    required this.logout,
    required this.checkAuthStatus,
    required this.checkProfileStatus,
  }) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<RequestOtpEvent>(_onRequestOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<ResendOtpEvent>(_onResendOtp);
    on<GetProfileEvent>(_onGetProfile);
    on<LogoutEvent>(_onLogout);
    on<ClearAuthErrorEvent>(_onClearError);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await checkAuthStatus(const NoParams());

    await result.fold((failure) async => emit(Unauthenticated()), (user) async {
      if (user != null) {
        // Check profile status after authentication
        final profileResult = await checkProfileStatus(const NoParams());

        profileResult.fold(
          (failure) {
            // If profile check fails, still authenticate but mark as incomplete
            emit(Authenticated(user: user, isProfileComplete: false));
          },
          (profile) {
            emit(
              Authenticated(
                user: user,
                isProfileComplete: profile?.isProfileComplete ?? false,
              ),
            );
          },
        );
      } else {
        emit(Unauthenticated());
      }
    });
  }

  Future<void> _onRequestOtp(
    RequestOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final request = OtpRequest(email: event.email);
    final result = await requestOtp(request);

    result.fold(
      (failure) {
        debugPrint('❌ OTP Request failed: ${failure.message}');
        emit(AuthError(message: failure.message));
      },
      (success) {
        debugPrint('✅ OTP Request success, emitting OtpSent');
        emit(OtpSent(email: event.email));
      },
    );
  }

  Future<void> _onVerifyOtp(
    VerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final verification = OtpVerification(email: event.email, otp: event.otp);
    final result = await verifyOtp(verification);

    await result.fold(
      (failure) async => emit(AuthError(message: failure.message)),
      (authResponse) async {
        // Check profile status after successful OTP verification
        final profileResult = await checkProfileStatus(const NoParams());

        profileResult.fold(
          (failure) {
            // If profile check fails, still authenticate but mark as incomplete
            emit(
              Authenticated(
                user: authResponse.user,
                isNewUser: authResponse.isNewUser,
                isProfileComplete: false,
              ),
            );
          },
          (profile) {
            emit(
              Authenticated(
                user: authResponse.user,
                isNewUser: authResponse.isNewUser,
                isProfileComplete: profile?.isProfileComplete ?? false,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onResendOtp(
    ResendOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final request = OtpRequest(email: event.email);
    final result = await resendOtp(request);

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (success) => emit(OtpResent(email: event.email)),
    );
  }

  Future<void> _onGetProfile(
    GetProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is Authenticated) {
      emit(AuthLoading());

      final result = await getProfile(const NoParams());

      result.fold(
        (failure) => emit(AuthError(message: failure.message)),
        (user) => emit(Authenticated(user: user)),
      );
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await logout(const NoParams());

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(Unauthenticated()),
    );
  }

  void _onClearError(ClearAuthErrorEvent event, Emitter<AuthState> emit) {
    emit(Unauthenticated());
  }
}
