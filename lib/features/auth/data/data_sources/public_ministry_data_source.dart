import 'package:dio/dio.dart';
import 'package:sewa_web/core/constants/api_endpoints.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/features/auth/data/models/ministry_model.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';

/// Data source for fetching public ministry list (NO AUTH REQUIRED)
abstract class PublicMinistryDataSource {
  /// Get list of active ministries in a place for login
  Future<List<Ministry>> getMinistriesByPlace(String placeSlug);

  /// Get single ministry by place and ministry slug
  Future<Ministry> getMinistryDetail(String placeSlug, String ministrySlug);

  /// Get list of active ministries for login dropdown (deprecated)
  @Deprecated('Use getMinistriesByPlace instead')
  Future<List<Ministry>> getPublicMinistries();

  /// Get single ministry by slug (deprecated)
  @Deprecated('Use getMinistryDetail instead')
  Future<Ministry> getMinistryBySlug(String slug);
}

class PublicMinistryDataSourceImpl implements PublicMinistryDataSource {
  final Dio dio;

  PublicMinistryDataSourceImpl({Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiEndpoints.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  @override
  Future<List<Ministry>> getMinistriesByPlace(String placeSlug) async {
    try {
      final response = await dio.get(
        ApiEndpoints.publicMinistriesByPlace(placeSlug),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final ministriesJson = data['data'] as List<dynamic>? ?? [];
          return ministriesJson
              .map(
                (json) => MinistryModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
      }

      throw ServerException(
        message: response.data['error'] ?? 'Failed to fetch ministries',
      );
    } on DioException catch (e) {
      throw ServerException(message: _handleDioError(e));
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Ministry> getMinistryDetail(
    String placeSlug,
    String ministrySlug,
  ) async {
    try {
      final response = await dio.get(
        ApiEndpoints.publicMinistryDetail(placeSlug, ministrySlug),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return MinistryModel.fromJson(data['data'] as Map<String, dynamic>);
        }
      }

      throw ServerException(
        message: response.data['error'] ?? 'Ministry not found',
      );
    } on DioException catch (e) {
      throw ServerException(message: _handleDioError(e));
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  @Deprecated('Use getMinistriesByPlace instead')
  Future<List<Ministry>> getPublicMinistries() async {
    try {
      final response = await dio.get(ApiEndpoints.publicMinistries);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final ministriesJson = data['data'] as List<dynamic>? ?? [];
          return ministriesJson
              .map(
                (json) => MinistryModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
      }

      throw ServerException(
        message: response.data['error'] ?? 'Failed to fetch ministries',
      );
    } on DioException catch (e) {
      throw ServerException(message: _handleDioError(e));
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  @Deprecated('Use getMinistryDetail instead')
  Future<Ministry> getMinistryBySlug(String slug) async {
    try {
      final response = await dio.get(ApiEndpoints.publicMinistryBySlug(slug));

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return MinistryModel.fromJson(data['data'] as Map<String, dynamic>);
        }
      }

      throw ServerException(
        message: response.data['error'] ?? 'Ministry not found',
      );
    } on DioException catch (e) {
      throw ServerException(message: _handleDioError(e));
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final errorMessage = e.response?.data?['error'];
        if (statusCode == 404) {
          return errorMessage ?? 'Not found';
        }
        return errorMessage ?? 'Server error ($statusCode)';
      default:
        return 'Network error: ${e.message}';
    }
  }
}
