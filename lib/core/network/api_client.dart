import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sewa_sathi/core/auth/token_manager.dart';
import 'package:sewa_sathi/core/constants/api_endpoints.dart';
import 'package:sewa_sathi/core/errors/exceptions.dart';
import 'package:sewa_sathi/core/network/interceptors/auth_interceptor.dart';

/// Centralized API client using Dio for HTTP requests.
class ApiClient {
  final Dio _dio;
  final TokenManager tokenManager;
  final VoidCallback? onAuthenticationFailed;

  ApiClient({
    required Dio dio,
    required this.tokenManager,
    this.onAuthenticationFailed,
  }) : _dio = dio {
    _dio.options = BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    _dio.interceptors.addAll([
      AuthInterceptor(
        getAccessToken: tokenManager.getAccessToken,
        refreshTokens: tokenManager.refreshTokens,
        onAuthError: (DioException error) {
          tokenManager.clearTokens();
          onAuthenticationFailed?.call();
        },
      ),
      // Enable logging for debugging
      if (kDebugMode)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
    ]);
  }

  /// Generic request handler with error handling
  Future<dynamic> _request(Future<Response> Function() requestMaker) async {
    try {
      final response = await requestMaker();
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// GET request
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _request(
      () => _dio.get(path, queryParameters: queryParameters, options: options),
    );
  }

  /// POST request
  Future<dynamic> post(String path, {dynamic data, Options? options}) {
    return _request(() => _dio.post(path, data: data, options: options));
  }

  /// PUT request
  Future<dynamic> put(String path, {dynamic data, Options? options}) {
    return _request(() => _dio.put(path, data: data, options: options));
  }

  /// PATCH request
  Future<dynamic> patch(String path, {dynamic data, Options? options}) {
    return _request(() => _dio.patch(path, data: data, options: options));
  }

  /// DELETE request
  Future<dynamic> delete(String path, {dynamic data, Options? options}) {
    return _request(() => _dio.delete(path, data: data, options: options));
  }

  /// POST multipart request for file uploads
  Future<dynamic> postMultipart(String path, {required FormData data}) {
    return _request(
      () => _dio.post(
        path,
        data: data,
        options: Options(contentType: 'multipart/form-data'),
      ),
    );
  }

  /// Handle Dio errors and convert to custom exceptions
  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      String message = 'An error occurred';
      if (data is Map && data.containsKey('error')) {
        message = data['error'] is String
            ? data['error']
            : data['error'].toString();
      } else if (data is Map && data.containsKey('message')) {
        message = data['message'];
      } else if (data is Map && data.containsKey('detail')) {
        message = data['detail'];
      }

      // Rate limiting
      if (statusCode == 429) {
        return RateLimitException(message: message);
      }

      // Authentication errors
      if (statusCode == 401 || statusCode == 403) {
        return AuthenticationException(message: message);
      }

      return ServerException(message: message, statusCode: statusCode);
    }

    // Connection errors
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkException(message: 'Connection timeout. Please try again.');
    }

    if (e.type == DioExceptionType.connectionError) {
      return NetworkException(
        message:
            'Cannot connect to server. Please check your internet connection.',
      );
    }

    return ServerException(
      message: e.message ?? 'An unexpected error occurred',
    );
  }
}
