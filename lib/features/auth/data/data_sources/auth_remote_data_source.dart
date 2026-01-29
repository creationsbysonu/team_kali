import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sewa_web/core/auth/token_manager.dart';
import 'package:sewa_web/core/constants/api_endpoints.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/network/api_client.dart';
import 'package:sewa_web/features/auth/data/models/auth_tokens_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    String? placeSlug,
    String? ministrySlug,
    String? serviceSlug,
  });

  Future<AuthTokensModel> refreshTokens();
  Future<bool> validateToken();
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  final TokenManager tokenManager;

  AuthRemoteDataSourceImpl({
    required this.apiClient,
    required this.tokenManager,
  });

  @override
  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    String? placeSlug,
    String? ministrySlug,
    String? serviceSlug,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'email': email,
        'password': password,
      };

      // Add context slugs for ministry admin or staff login
      if (placeSlug != null && placeSlug.isNotEmpty) {
        requestData['place_slug'] = placeSlug;
      }
      if (ministrySlug != null && ministrySlug.isNotEmpty) {
        requestData['ministry_slug'] = ministrySlug;
      }
      if (serviceSlug != null && serviceSlug.isNotEmpty) {
        requestData['service_slug'] = serviceSlug;
      }

      debugPrint('AuthRemoteDataSource: Login request data: $requestData');

      // Determine the correct endpoint based on login type
      String endpoint;
      if (serviceSlug != null && serviceSlug.isNotEmpty) {
        // Staff login - use staff-specific endpoint
        endpoint = ApiEndpoints.staffLogin(placeSlug!, ministrySlug!);
        debugPrint(
          'AuthRemoteDataSource: Using staff login endpoint: $endpoint',
        );
      } else if (ministrySlug != null &&
          ministrySlug.isNotEmpty &&
          placeSlug != null &&
          placeSlug.isNotEmpty) {
        // Ministry admin login - use ministry-specific endpoint
        endpoint = ApiEndpoints.ministryLogin(placeSlug, ministrySlug);
        debugPrint(
          'AuthRemoteDataSource: Using ministry login endpoint: $endpoint',
        );
      } else {
        // Super admin login - use default auth endpoint
        endpoint = ApiEndpoints.login;
        debugPrint(
          'AuthRemoteDataSource: Using super admin login endpoint: $endpoint',
        );
      }

      final responseData = await apiClient.post(endpoint, data: requestData);

      debugPrint('AuthRemoteDataSource: Login response: $responseData');

      if (responseData['success'] != true) {
        throw ServerException(message: responseData['error'] ?? 'Login failed');
      }

      final data = responseData['data'];
      final tokens = AuthTokensModel.fromJson(data['tokens']);
      await tokenManager.storeTokens(tokens);
      return data;
    } on DioException catch (e) {
      final errorMessage = _handleDioError(e);
      throw ServerException(message: errorMessage);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet connection';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Server is taking too long to respond. Please try again later.';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'Connection error.Please check your internet connection.';
    } else if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      // Handle specific error responses
      if (data is Map && data.containsKey('error')) {
        final errorMessage = data['error'].toString();
        // check for specific error patterns
        if (errorMessage.contains('locked')) {
          return "Your account has been temporarily locked due to multiple failed login attempts. Please try again later.";
        } else if (errorMessage.contains('Invalid email or pasword')) {
          return 'The email or password you entered is incorrect. Please try again.';
        } else if (errorMessage.contains('disabled')) {
          return 'Your account has been disabled. Please contact support for assistance.';
        }
        return errorMessage;
      } else if (statusCode == 401) {
        return "Invalid email or password. Please check credentials and try again.";
      } else if (statusCode == 403) {
        if (data is Map &&
            data.containsKey('lockout') &&
            data['lockout'] == true) {
          return "Account temporarily locked due to multiple failed attempts. Try again later.";
        }

        return "Access denied. Please contact support if this problem persists";
      } else if (statusCode == 404) {
        return "Service not found. Please check your connection and try again.";
      } else if (statusCode == 400) {
        return "Invalid request. Please check your inputs and try again.";
      } else if (statusCode == 500) {
        return "Server error. Please try again later or contact support";
      } else {
        return "Server error ($statusCode). Please try again later";
      }
    }
    return "Network error. Please check your connection and try again. ";
  }

  @override
  Future<void> logout() async {
    try {
      try {
        await apiClient.post(ApiEndpoints.logout);
      } catch (e) {
        debugPrint('Backend logout failed, proceeding with local cleanup: $e');
      }
      // Always clear local tokens regardless of backend call success
      await tokenManager.clearTokens();
    } catch (e) {
      debugPrint("Error during logout: $e");
      await tokenManager.clearTokens();
    }
  }

  @override
  Future<AuthTokensModel> refreshTokens() async {
    try {
      final responseData = await apiClient.post(ApiEndpoints.tokenRefresh);

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['error'] ?? "Token refresh failed",
        );
      }

      final accessToken = responseData['data']['access_token'];
      return AuthTokensModel.fromJson({
        'access_token': accessToken,
        'refersh_token': '',
        'expires_in': 900,
        'refresh_expires_in': 0,
      });
    } on DioException catch (e) {
      final errorMessage = _handleDioError(e);
      throw ServerException(message: errorMessage);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> validateToken() async {
    try {
      final responseData = await apiClient.get(ApiEndpoints.tokenValidate);
      if (responseData['success'] != true) {
        return false;
      }
      return responseData['data']['valid'] ?? false;
    } on DioException catch (e) {
      debugPrint('Token validation DioException: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Token validation error: $e');
      return false;
    }
  }
}
