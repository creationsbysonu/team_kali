import 'package:dio/dio.dart';
import 'package:sewa_web/core/constants/api_endpoints.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/network/api_client.dart';
import 'package:sewa_web/features/staff/data/models/staff_model.dart';

/// Abstract data source for staff operations
abstract class StaffRemoteDataSource {
  /// Get all staff in ministry
  Future<List<StaffModel>> getMinistryStaff();

  /// Get staff by ID
  Future<StaffModel> getStaffById(String id);

  /// Create staff
  Future<StaffModel> createStaff({
    required String name,
    required String email,
    required String password,
    required String serviceId,
    String? contact,
    String? imagePath,
  });

  /// Update staff
  Future<StaffModel> updateStaff({
    required String id,
    String? name,
    String? contact,
    String? password,
    bool? isActive,
  });

  /// Delete staff
  Future<void> deleteStaff(String id);

  /// Reset staff password
  Future<void> resetStaffPassword({
    required String staffId,
    required String newPassword,
  });
}

/// Implementation of StaffRemoteDataSource
class StaffRemoteDataSourceImpl implements StaffRemoteDataSource {
  final ApiClient apiClient;

  StaffRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<StaffModel>> getMinistryStaff() async {
    try {
      final response = await apiClient.get(ApiEndpoints.staffList);

      if (response['success'] != true) {
        throw ServerException(
          message: response['error'] ?? 'Failed to load staff',
        );
      }

      final data = response['data'] as List;
      return data.map((json) => StaffModel.fromJson(json)).toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<StaffModel> getStaffById(String id) async {
    try {
      final response = await apiClient.get(ApiEndpoints.staffDetail(id));

      if (response['success'] != true) {
        throw ServerException(message: response['error'] ?? 'Staff not found');
      }

      return StaffModel.fromJson(response['data']);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<StaffModel> createStaff({
    required String name,
    required String email,
    required String password,
    required String serviceId,
    String? contact,
    String? imagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        'email': email,
        'password': password,
        'service_id': serviceId,
        if (contact != null) 'contact': contact,
        if (imagePath != null) 'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await apiClient.postFormData(
        ApiEndpoints.staffCreate,
        data: formData,
      );

      if (response['success'] != true) {
        throw ServerException(
          message: response['error'] ?? 'Failed to create staff',
        );
      }

      return StaffModel.fromJson(response['data']);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<StaffModel> updateStaff({
    required String id,
    String? name,
    String? contact,
    String? password,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (contact != null) data['contact'] = contact;
      if (password != null) data['password'] = password;
      if (isActive != null) data['is_active'] = isActive;

      final response = await apiClient.put(
        ApiEndpoints.staffDetail(id),
        data: data,
      );

      if (response['success'] != true) {
        throw ServerException(
          message: response['error'] ?? 'Failed to update staff',
        );
      }

      return StaffModel.fromJson(response['data']);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteStaff(String id) async {
    try {
      final response = await apiClient.delete(ApiEndpoints.staffDetail(id));

      if (response['success'] != true) {
        throw ServerException(
          message: response['error'] ?? 'Failed to delete staff',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> resetStaffPassword({
    required String staffId,
    required String newPassword,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.staffResetPassword(staffId),
        data: {'new_password': newPassword},
      );

      if (response['success'] != true) {
        throw ServerException(
          message: response['error'] ?? 'Failed to reset password',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
