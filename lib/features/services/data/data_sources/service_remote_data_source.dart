import 'package:sewa_web/core/constants/api_endpoints.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/network/api_client.dart';
import 'package:sewa_web/features/services/data/models/service_model.dart';
import 'package:sewa_web/features/services/domain/entities/service.dart';

/// Abstract data source for service operations
abstract class ServiceRemoteDataSource {
  /// Get public services for a ministry
  Future<List<ServiceModel>> getPublicServices({
    required String placeSlug,
    required String ministrySlug,
  });

  /// Get all services in ministry (ministry admin)
  Future<List<ServiceModel>> getMinistryServices();

  /// Get service by ID
  Future<ServiceModel> getServiceById(String id);

  /// Create service
  Future<ServiceModel> createService({
    required String name,
    required String slug,
    String? description,
    ServiceType? serviceType,
    double? feeAmount,
  });

  /// Update service
  Future<ServiceModel> updateService({
    required String id,
    String? name,
    String? slug,
    String? description,
    ServiceType? serviceType,
    double? feeAmount,
    bool? isActive,
    bool? isPublished,
  });

  /// Delete service
  Future<void> deleteService(String id);
}

/// Implementation of ServiceRemoteDataSource
class ServiceRemoteDataSourceImpl implements ServiceRemoteDataSource {
  final ApiClient apiClient;

  ServiceRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ServiceModel>> getPublicServices({
    required String placeSlug,
    required String ministrySlug,
  }) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.publicServicesByMinistry(placeSlug, ministrySlug),
      );

      if (response['success'] != true) {
        throw ServerException(
          message: response['error'] ?? 'Failed to load services',
        );
      }

      final data = response['data'] as List;
      return data.map((json) => ServiceModel.fromJson(json)).toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ServiceModel>> getMinistryServices() async {
    try {
      final response = await apiClient.get(ApiEndpoints.serviceList);

      if (response['success'] != true) {
        throw ServerException(
          message: response['error'] ?? 'Failed to load services',
        );
      }

      final data = response['data'] as List;
      return data.map((json) => ServiceModel.fromJson(json)).toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ServiceModel> getServiceById(String id) async {
    try {
      final response = await apiClient.get(ApiEndpoints.serviceDetail(id));

      if (response['success'] != true) {
        throw ServerException(
          message: response['error'] ?? 'Service not found',
        );
      }

      return ServiceModel.fromJson(response['data']);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ServiceModel> createService({
    required String name,
    required String slug,
    String? description,
    ServiceType? serviceType,
    double? feeAmount,
  }) async {
    try {
      final data = <String, dynamic>{'name': name, 'slug': slug};
      if (description != null) data['description'] = description;
      if (serviceType != null) data['service_type'] = serviceType.value;
      if (feeAmount != null) data['fee_amount'] = feeAmount;

      final response = await apiClient.post(
        ApiEndpoints.serviceCreate,
        data: data,
      );

      if (response['success'] != true) {
        throw ServerException(
          message: response['error'] ?? 'Failed to create service',
        );
      }

      return ServiceModel.fromJson(response['data']);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ServiceModel> updateService({
    required String id,
    String? name,
    String? slug,
    String? description,
    ServiceType? serviceType,
    double? feeAmount,
    bool? isActive,
    bool? isPublished,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (slug != null) data['slug'] = slug;
      if (description != null) data['description'] = description;
      if (serviceType != null) data['service_type'] = serviceType.value;
      if (feeAmount != null) data['fee_amount'] = feeAmount;
      if (isActive != null) data['is_active'] = isActive;
      if (isPublished != null) data['is_published'] = isPublished;

      final response = await apiClient.put(
        ApiEndpoints.serviceDetail(id),
        data: data,
      );

      if (response['success'] != true) {
        throw ServerException(
          message: response['error'] ?? 'Failed to update service',
        );
      }

      return ServiceModel.fromJson(response['data']);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteService(String id) async {
    try {
      final response = await apiClient.delete(ApiEndpoints.serviceDetail(id));

      if (response['success'] != true) {
        throw ServerException(
          message: response['error'] ?? 'Failed to delete service',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
