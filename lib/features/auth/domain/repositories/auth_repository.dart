import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/features/auth/domain/entities/auth_response.dart';
import 'package:sewa_sathi/features/auth/domain/entities/auth_tokens.dart';
import 'package:sewa_sathi/features/auth/domain/entities/otp_credentials.dart';
import 'package:sewa_sathi/features/auth/domain/entities/user_entity.dart';

/// Abstract repository interface for authentication operations.
abstract class AuthRepository {
  /// Request OTP to be sent to the user's email.
  Future<Either<Failure, bool>> requestOtp(OtpRequest request);

  /// Verify OTP and login/register the user.
  Future<Either<Failure, AuthResponse>> verifyOtp(OtpVerification verification);

  /// Resend OTP to the user's email.
  Future<Either<Failure, bool>> resendOtp(OtpRequest request);

  /// Get the currently authenticated user's profile.
  Future<Either<Failure, UserEntity>> getProfile();

  /// Refresh authentication tokens.
  Future<Either<Failure, AuthTokens>> refreshTokens();

  /// Logout the current user.
  Future<Either<Failure, void>> logout();

  /// Check if user is authenticated.
  Future<Either<Failure, bool>> isAuthenticated();

  /// Get cached user from local storage.
  Future<Either<Failure, UserEntity?>> getCachedUser();
}
