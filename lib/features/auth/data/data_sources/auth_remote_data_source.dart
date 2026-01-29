import 'package:sewa_sathi/core/constants/api_endpoints.dart';
import 'package:sewa_sathi/core/errors/exceptions.dart';
import 'package:sewa_sathi/core/network/api_client.dart';
import 'package:sewa_sathi/features/auth/data/models/auth_response_model.dart';
import 'package:sewa_sathi/features/auth/data/models/auth_tokens_model.dart';
import 'package:sewa_sathi/features/auth/data/models/user_model.dart';

/// Abstract interface for auth remote data source.
abstract class AuthRemoteDataSource {
  /// Request OTP to be sent to email.
  Future<bool> requestOtp(String email);

  /// Verify OTP and get auth response.
  Future<AuthResponseModel> verifyOtp(String email, String otp);

  /// Resend OTP to email.
  Future<bool> resendOtp(String email);

  /// Get user profile.
  Future<UserModel> getProfile();

  /// Refresh tokens.
  Future<AuthTokensModel> refreshTokens(String refreshToken);

  /// Logout user.
  Future<void> logout(String refreshToken);
}

/// Implementation of auth remote data source.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<bool> requestOtp(String email) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.otpRequest,
        data: {'email': email},
      );

      if (response['success'] == true) {
        return true;
      }

      throw ServerException(message: response['error'] ?? 'Failed to send OTP');
    } on RateLimitException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<AuthResponseModel> verifyOtp(String email, String otp) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.otpVerify,
        data: {'email': email, 'otp': otp},
      );

      if (response['success'] == true) {
        return AuthResponseModel.fromJson(response['data']);
      }

      // Handle OTP-specific errors
      final error = response['error'] ?? 'OTP verification failed';
      if (error.toString().contains('Invalid OTP')) {
        throw OtpException(message: error);
      }
      if (error.toString().contains('expired')) {
        throw OtpException(message: error);
      }

      throw ServerException(message: error);
    } on OtpException {
      rethrow;
    } on RateLimitException {
      rethrow;
    } on AuthenticationException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> resendOtp(String email) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.otpResend,
        data: {'email': email},
      );

      if (response['success'] == true) {
        return true;
      }

      throw ServerException(
        message: response['error'] ?? 'Failed to resend OTP',
      );
    } on RateLimitException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await apiClient.get(ApiEndpoints.profile);

      if (response['success'] == true) {
        return UserModel.fromJson(response['data']);
      }

      throw ServerException(
        message: response['error'] ?? 'Failed to get profile',
      );
    } on AuthenticationException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<AuthTokensModel> refreshTokens(String refreshToken) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.tokenRefresh,
        data: {'refresh_token': refreshToken},
      );

      if (response['success'] == true) {
        return AuthTokensModel.fromJson(response['data']);
      }

      throw AuthenticationException(
        message: response['error'] ?? 'Failed to refresh token',
      );
    } on AuthenticationException {
      rethrow;
    } catch (e) {
      throw AuthenticationException(message: e.toString());
    }
  }

  @override
  Future<void> logout(String refreshToken) async {
    try {
      await apiClient.post(
        ApiEndpoints.logout,
        data: {'refresh_token': refreshToken},
      );
    } catch (e) {
      // Ignore logout errors, we'll clear local storage anyway
    }
  }
}
