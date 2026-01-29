import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/auth/token_manager.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/auth/domain/entities/auth_credentials.dart';
import 'package:sewa_web/features/auth/domain/entities/user_entity.dart';
import 'package:sewa_web/features/auth/domain/usecase/auth_usecases.dart';
part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // Use cases
  final GetCurrentUserUsecase getCurrentUser;
  final LoginUseCase login;
  final LogoutUseCase logout;
  final ValidateTokenUseCase validateToken;
  final TokenManager tokenManager;

  AuthBloc({
    required this.getCurrentUser,
    required this.login,
    required this.logout,
    required this.validateToken,
    required this.tokenManager,
  }) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // Step 1: Check if we have tokens stored locally
      final hasTokens = await tokenManager.hasTokens();
      if (!hasTokens) {
        debugPrint('AuthBloc: No tokens found locally');
        emit(UnAuthenticated());
        return;
      }

      // Step 2: Check local token expiry status
      final authStatus = await tokenManager.getAuthStatus();
      debugPrint('AuthBloc: Local auth status: $authStatus');

      switch (authStatus) {
        case AuthStatus.authenticated:
          // Token is still valid locally, try to get cached user
          final userResult = await getCurrentUser(const NoParams());
          userResult.fold(
            (failure) {
              debugPrint(
                'AuthBloc: Failed to get cached user: ${failure.message}',
              );
              emit(UnAuthenticated());
            },
            (user) {
              if (user != null) {
                debugPrint('AuthBloc: User restored from cache: ${user.email}');
                emit(Authenticated(user: user));
              } else {
                debugPrint('AuthBloc: No cached user found');
                emit(UnAuthenticated());
              }
            },
          );
          break;

        case AuthStatus.expired:
          // Access token expired, try to refresh
          debugPrint('AuthBloc: Access token expired, attempting refresh...');
          final refreshed = await tokenManager.refreshTokens();

          if (refreshed) {
            debugPrint('AuthBloc: Token refreshed successfully');
            // Token refreshed, get cached user
            final userResult = await getCurrentUser(const NoParams());
            userResult.fold(
              (failure) {
                debugPrint(
                  'AuthBloc: Failed to get user after refresh: ${failure.message}',
                );
                emit(UnAuthenticated());
              },
              (user) {
                if (user != null) {
                  debugPrint(
                    'AuthBloc: User restored after token refresh: ${user.email}',
                  );
                  emit(Authenticated(user: user));
                } else {
                  emit(UnAuthenticated());
                }
              },
            );
          } else {
            // Refresh failed, clear tokens and logout
            debugPrint('AuthBloc: Token refresh failed');
            await tokenManager.clearTokens();
            emit(UnAuthenticated());
          }
          break;

        case AuthStatus.unauthenticated:
          // Both tokens expired
          debugPrint('AuthBloc: Both tokens expired');
          await tokenManager.clearTokens();
          emit(UnAuthenticated());
          break;
      }
    } catch (e) {
      debugPrint('AuthBloc: Error during auth check: $e');
      emit(UnAuthenticated());
    }
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final credentials = AuthCredentials(
      email: event.email,
      password: event.password,
      placeSlug: event.placeSlug,
      ministrySlug: event.ministrySlug,
      serviceSlug: event.serviceSlug,
    );
    final result = await login(credentials);

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(Authenticated(user: user)),
    );
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await logout(const NoParams());

    // Always emit UnAuthenticated regardless of backend result
    // Repository already handles local cleanup
    result.fold(
      (failure) {
        debugPrint(
          'Logout backend failed: ${failure.message}, local cleanup done',
        );
      },
      (_) {
        debugPrint('Logout successful');
      },
    );
    emit(UnAuthenticated());
  }
}
