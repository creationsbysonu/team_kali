import 'package:dio/dio.dart';
import 'package:sewa_sathi/features/auth/domain/entities/auth_tokens.dart';

/// Interceptor for handling JWT authentication.
/// Adds access token to requests and handles token refresh on 401.
class AuthInterceptor extends Interceptor {
  final Future<String?> Function() getAccessToken;
  final Future<AuthTokens?> Function() refreshTokens;
  final void Function(DioException error) onAuthError;

  AuthInterceptor({
    required this.getAccessToken,
    required this.refreshTokens,
    required this.onAuthError,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for auth endpoints that don't need it
    final noAuthPaths = [
      '/auth/otp/request/',
      '/auth/otp/verify/',
      '/auth/otp/resend/',
      '/auth/token/refresh/',
    ];

    final needsAuth = !noAuthPaths.any((path) => options.path.contains(path));

    if (needsAuth) {
      final token = await getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized - try to refresh token
    if (err.response?.statusCode == 401) {
      try {
        final newTokens = await refreshTokens();
        if (newTokens != null) {
          // Retry the original request with new token
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer ${newTokens.accessToken}';

          final dio = Dio();
          final response = await dio.fetch(options);
          return handler.resolve(response);
        }
      } catch (e) {
        // Refresh failed, notify auth error
        onAuthError(err);
      }
    }

    handler.next(err);
  }
}
