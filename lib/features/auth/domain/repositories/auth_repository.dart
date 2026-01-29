import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/features/auth/domain/entities/auth_credentials.dart';
import 'package:sewa_web/features/auth/domain/entities/auth_tokens.dart';
import 'package:sewa_web/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  /// Login with email and password
  /// Uses: POST /api/auth/login/
  Future<Either<Failure, UserEntity>> loginWithEmailAndPassword(
    AuthCredentials credentials,
  );

  /// Refresh authentication tokens
  /// Uses: POST /api/auth/token/refresh/
  Future<Either<Failure, AuthTokens>> refreshTokens();

  /// Validate if the current token is still valid
  /// Uses: POST /api/auth/token/validate/
  Future<Either<Failure, bool>> validateToken();

  /// Get the currently authenticated user from cache
  /// Note: No API call - uses locally cached user from login response
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Logout the current user
  /// Uses: POST /auth/logout/ (backend handles all user types via JWT)
  Future<Either<Failure, void>> logout();
}
