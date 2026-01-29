import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sewa_web/core/auth/token_manager.dart';
import 'package:sewa_web/core/constants/api_endpoints.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/network/interceptors/auth_interceptor.dart';

class ApiClient {
  final Dio _dio;
  final TokenManager tokenManager;
  final Function()? onAuthenticationFailed;
  final Future<String?> Function()? getMinistryId;

  ApiClient({
    required Dio dio,
    required this.tokenManager,
    this.onAuthenticationFailed,
    this.getMinistryId,
  }) : _dio = dio {
    // set base options
    _dio.options = BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    // Add interceptors
    _dio.interceptors.addAll([
      AuthInterceptor(
        getAccessToken: tokenManager.getAccessToken,
        refreshTokens: tokenManager.refreshTokens,
        getMinistryId: getMinistryId,
        onAuthError: (DioException error) {
          tokenManager.clearTokens();
          onAuthenticationFailed?.call();
        },
      ),
    ]);
  }

  // Create options with withCredentials for web cookied handling
  Options _createOptions({Options? options}) {
    return Options(
        headers: options?.headers,
        method: options?.method,
        sendTimeout: options?.sendTimeout,
        receiveTimeout: options?.receiveTimeout,
        extra: options?.extra,
        followRedirects: options?.followRedirects,
        validateStatus: options?.validateStatus,
        receiveDataWhenStatusError: options?.receiveDataWhenStatusError,
        listFormat: options?.listFormat,
        responseType: options?.responseType,
        contentType: options?.contentType,
      )
      ..extra = {
        ...?options?.extra,
        'withCredentials': true, // enable cookies for web
      };
  }

  // Generic request handler
  Future<dynamic> _request(Future<Response> Function() requestMaker) async {
    try {
      final response = await requestMaker();
      debugPrint('ApiClient: Response status: ${response.statusCode}');
      debugPrint('ApiClient: Response data type: ${response.data.runtimeType}');
      return response.data;
    } on DioException catch (e) {
      debugPrint('ApiClient: DioException caught');
      debugPrint('ApiClient: Type: ${e.type}');
      debugPrint('ApiClient: Message: ${e.message}');
      debugPrint('ApiClient: Response: ${e.response?.data}');

      // Extract error message from various formats
      String errorMessage = e.message ?? 'Unknown error';
      final responseData = e.response?.data;

      if (responseData is Map) {
        final error = responseData['error'];
        if (error is String) {
          errorMessage = error;
        } else if (error is Map) {
          // Handle nested error like {non_field_errors: [...]}
          if (error['non_field_errors'] is List) {
            errorMessage = (error['non_field_errors'] as List).join(', ');
          } else {
            // Get first error message from any field
            for (final value in error.values) {
              if (value is List && value.isNotEmpty) {
                errorMessage = value.first.toString();
                break;
              } else if (value is String) {
                errorMessage = value;
                break;
              }
            }
          }
        }
        // Also check 'detail' field
        if (responseData['detail'] is String) {
          errorMessage = responseData['detail'];
        }
      }

      throw ServerException(message: errorMessage);
    } catch (e, stackTrace) {
      debugPrint('ApiClient: Unexpected error caught: $e');
      debugPrint('ApiClient: Error type: ${e.runtimeType}');
      debugPrint('ApiClient: Stack trace: $stackTrace');
      throw ServerException(
        message: "An unexpected error occurred: ${e.toString()}",
      );
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    final requestOptions = _createOptions(options: options);
    return _request(
      () => _dio.get(
        path,
        queryParameters: queryParameters,
        options: requestOptions,
      ),
    );
  }

  Future<dynamic> post(String path, {dynamic data, Options? options}) {
    final requestOptions = _createOptions(options: options);
    return _request(() => _dio.post(path, data: data, options: requestOptions));
  }

  Future<dynamic> postFormData(
    String path, {
    required FormData data,
    Options? options,
  }) {
    final requestOptions = _createOptions(options: options);
    requestOptions.contentType = 'multipart/form-data';
    return _request(() => _dio.post(path, data: data, options: requestOptions));
  }

  Future<dynamic> put(String path, {dynamic data, Options? options}) {
    final requestOptions = _createOptions(options: options);
    return _request(() => _dio.put(path, data: data, options: requestOptions));
  }

  Future<dynamic> patch(String path, {dynamic data, Options? options}) {
    final requestOptions = _createOptions(options: options);
    return _request(
      () => _dio.patch(path, data: data, options: requestOptions),
    );
  }

  Future<dynamic> delete(String path, {dynamic data, Options? options}) {
    final requestOptions = _createOptions(options: options);
    return _request(
      () => _dio.delete(path, data: data, options: requestOptions),
    );
  }
}
