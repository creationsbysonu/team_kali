
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sewa_web/core/constants/api_endpoints.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/network/api_client.dart';
import 'package:sewa_web/features/ministry/data/models/staff_service_model.dart';
import 'package:sewa_web/features/ministry/domain/entities/staff_service_entity.dart';

/// Remote data source for StaffService operations (Ministry Admin)
/// Handles API calls to manage staff-services
abstract class StaffServiceRemoteDataSource {
  /// Fetch all staff-services for ministry admin
  /// API: GET /ministry/management/staff-services/
  Future<List<StaffService>> getStaffServices();

  /// Get staff-service details by ID
  /// API: GET /ministry/management/staff-services/{id}/
  Future<StaffService> getStaffServiceById(String id);

  /// Create a new staff-service
  /// API: POST /ministry/management/staff-services/
  Future<StaffService> createStaffService({
    required String serviceName,
    required String staffName,
    required String email,
    required String password,
    Uint8List? serviceLogoBytes,
    String? serviceLogoFileName,
    Uint8List? staffImageBytes,
    String? staffImageFileName,
  });

  /// Update staff-service
  /// API: PATCH /ministry/management/staff-services/{id}/
  Future<StaffService> updateStaffService({
    required String id,
    String? serviceName,
    String? staffName,
    Uint8List? serviceLogoBytes,
    String? serviceLogoFileName,
    Uint8List? staffImageBytes,
    String? staffImageFileName,
  });

  /// Delete staff-service
  /// API: DELETE /ministry/management/staff-services/{id}/
  Future<void> deleteStaffService(String id);

  /// Reset staff password
  /// API: POST /ministry/management/staff-services/{id}/reset-password/
  Future<void> resetStaffPassword(String id, String newPassword);

  /// Toggle staff-service status (active/paused)
  /// API: POST /ministry/management/staff-services/{id}/toggle-status/
  Future<StaffService> toggleStaffServiceStatus(String id);
}

class StaffServiceRemoteDataSourceImpl implements StaffServiceRemoteDataSource {
  final ApiClient apiClient;

  StaffServiceRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<StaffService>> getStaffServices() async {
    try {
      debugPrint(
        'StaffServiceRemoteDataSource: Fetching staff services from ${ApiEndpoints.ministryStaffServices}',
      );

      final responseData = await apiClient.get(
        ApiEndpoints.ministryStaffServices,
      );

      debugPrint(
        'StaffServiceRemoteDataSource: Response received: $responseData',
      );

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['error'] ?? 'Failed to fetch staff services',
        );
      }

      final data = responseData['data'] as List<dynamic>? ?? [];
      debugPrint('StaffServiceRemoteDataSource: Parsing ${data.length} items');

      return data
          .map(
            (json) => StaffServiceModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      debugPrint(
        'StaffServiceRemoteDataSource: DioException - ${e.type}: ${e.message}',
      );
      debugPrint('StaffServiceRemoteDataSource: Response: ${e.response?.data}');
      throw ServerException(message: _handleDioError(e));
    } catch (e, stackTrace) {
      debugPrint('StaffServiceRemoteDataSource: Unexpected error: $e');
      debugPrint('StaffServiceRemoteDataSource: Stack trace: $stackTrace');
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Error parsing response: ${e.toString()}');
    }
  }

  @override
  Future<StaffService> getStaffServiceById(String id) async {
    try {
      final responseData = await apiClient.get(
        ApiEndpoints.ministryStaffServiceDetail(id),
      );

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['error'] ?? 'Staff service not found',
        );
      }

      return StaffServiceModel.fromJson(
        responseData['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(message: _handleDioError(e));
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<StaffService> createStaffService({
    required String serviceName,
    required String staffName,
    required String email,
    required String password,
    Uint8List? serviceLogoBytes,
    String? serviceLogoFileName,
    Uint8List? staffImageBytes,
    String? staffImageFileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'service_name': serviceName,
        'staff_name': staffName,
        'email': email,
        'password': password,
        if (serviceLogoBytes != null && serviceLogoFileName != null)
          'service_logo': MultipartFile.fromBytes(
            serviceLogoBytes,
            filename: serviceLogoFileName,
          ),
        if (staffImageBytes != null && staffImageFileName != null)
          'staff_image': MultipartFile.fromBytes(
            staffImageBytes,
            filename: staffImageFileName,
          ),
      });

      final responseData = await apiClient.post(
        ApiEndpoints.ministryStaffServicesCreate,
        data: formData,
      );

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['error'] ?? 'Failed to create staff service',
        );
      }

      return StaffServiceModel.fromJson(
        responseData['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(message: _handleDioError(e));
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<StaffService> updateStaffService({
    required String id,
    String? serviceName,
    String? staffName,
    Uint8List? serviceLogoBytes,
    String? serviceLogoFileName,
    Uint8List? staffImageBytes,
    String? staffImageFileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        if (serviceName != null) 'service_name': serviceName,
        if (staffName != null) 'staff_name': staffName,
        if (serviceLogoBytes != null && serviceLogoFileName != null)
          'service_logo': MultipartFile.fromBytes(
            serviceLogoBytes,
            filename: serviceLogoFileName,
          ),
        if (staffImageBytes != null && staffImageFileName != null)
          'staff_image': MultipartFile.fromBytes(
            staffImageBytes,
            filename: staffImageFileName,
          ),
      });

      final responseData = await apiClient.patch(
        ApiEndpoints.ministryStaffServiceDetail(id),
        data: formData,
      );

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['error'] ?? 'Failed to update staff service',
        );
      }

      return StaffServiceModel.fromJson(
        responseData['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(message: _handleDioError(e));
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteStaffService(String id) async {
    try {
      final responseData = await apiClient.delete(
        ApiEndpoints.ministryStaffServiceDetail(id),
      );

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['error'] ?? 'Failed to delete staff service',
        );
      }
    } on DioException catch (e) {
      throw ServerException(message: _handleDioError(e));
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> resetStaffPassword(String id, String newPassword) async {
    try {
      final responseData = await apiClient.post(
        ApiEndpoints.ministryStaffServiceResetPassword(id),
        data: {'new_password': newPassword},
      );

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['error'] ?? 'Failed to reset password',
        );
      }
    } on DioException catch (e) {
      throw ServerException(message: _handleDioError(e));
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<StaffService> toggleStaffServiceStatus(String id) async {
    try {
      final responseData = await apiClient.post(
        ApiEndpoints.ministryStaffServiceToggleStatus(id),
      );

      debugPrint(
        'StaffServiceRemoteDataSource: Toggle status response: $responseData',
      );

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['error'] ?? 'Failed to toggle status',
        );
      }

      // Check if data field exists and is not null
      final data = responseData['data'];
      if (data == null) {
        throw ServerException(
          message: 'Backend returned success but no service data',
        );
      }

      return StaffServiceModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(message: _handleDioError(e));
    } catch (e) {
      debugPrint('ServerException in toggleStaffServiceStatus: $e');
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  String _handleDioError(DioException e) {
    debugPrint('DioException: ${e.type} - ${e.message}');
    debugPrint('Response: ${e.response?.data}');

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        if (data is Map && data['error'] != null) {
          return data['error'].toString();
        }

        if (statusCode == 400) return 'Invalid request data';
        if (statusCode == 401) return 'Unauthorized. Please login again.';
        if (statusCode == 403) return 'Access denied';
        if (statusCode == 404) return 'Not found';
        if (statusCode == 409) return 'Resource conflict';
        if (statusCode == 422) return 'Validation error';
        if (statusCode != null && statusCode >= 500) {
          return 'Server error. Please try again later.';
        }
        return 'Request failed with status: $statusCode';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'Network connection error. Please check your internet.';
      default:
        return e.message ?? 'An unexpected error occurred';
    }
  }
}
