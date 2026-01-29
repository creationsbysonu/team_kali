import 'package:sewa_web/core/network/api_client.dart';
import 'package:sewa_web/core/constants/api_endpoints.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/features/queue_management/data/models/queue_configuration_model.dart';

abstract class QueueConfigRemoteDataSource {
  /// Get all services - only checks if config exists (not full details)
  Future<Map<String, dynamic>> getAllServicesWithConfigStatus(
    String ministryId,
  );
  Future<QueueConfigurationModel?> getConfigByService(String staffServiceId);
  Future<QueueConfigurationModel> createConfig(Map<String, dynamic> configData);
  Future<QueueConfigurationModel> updateConfig(
    String configId,
    Map<String, dynamic> configData,
  );
  Future<void> deleteConfig(String configId);
}

class QueueConfigRemoteDataSourceImpl implements QueueConfigRemoteDataSource {
  final ApiClient apiClient;

  QueueConfigRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<Map<String, dynamic>> getAllServicesWithConfigStatus(
    String ministryId,
  ) async {
    try {
      // Only fetch staff services - configs will be loaded on-demand when editing
      final servicesResponse = await apiClient.get(
        ApiEndpoints.ministryStaffServices,
      );

      if (servicesResponse['success'] != true) {
        throw ServerException(
          message: servicesResponse['error'] ?? 'Failed to fetch services',
        );
      }

      final services = servicesResponse['data'] as List;

      // Check config existence SEQUENTIALLY to avoid overwhelming the backend
      // The backend has Supabase connection issues with parallel requests
      final configExists = <String, bool>{};
      for (final service in services) {
        final serviceId = service['id'].toString();
        configExists[serviceId] = await _checkConfigExistsWithRetry(serviceId);
      }

      return {'services': services, 'configExists': configExists};
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  /// Check config exists with retry logic for unreliable backend
  Future<bool> _checkConfigExistsWithRetry(
    String staffServiceId, {
    int maxRetries = 2,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final responseData = await apiClient
            .get(ApiEndpoints.queueConfigByService(staffServiceId))
            .timeout(const Duration(seconds: 20));

        if (responseData['success'] == true) {
          final data = responseData['data'];
          return data != null &&
              data['results'] != null &&
              (data['results'] as List).isNotEmpty;
        }
        return false;
      } catch (e) {
        if (attempt == maxRetries) {
          // Last attempt failed, return false (assume not configured)
          return false;
        }
        // Wait briefly before retry
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    return false;
  }

  @override
  Future<QueueConfigurationModel?> getConfigByService(
    String staffServiceId,
  ) async {
    try {
      final responseData = await apiClient.get(
        ApiEndpoints.queueConfigByService(staffServiceId),
      );

      if (responseData['success'] == true) {
        final data = responseData['data'];
        if (data == null ||
            data['results'] == null ||
            (data['results'] as List).isEmpty) {
          return null;
        }
        return QueueConfigurationModel.fromJson(data['results'][0]);
      }

      throw ServerException(
        message: responseData['error'] ?? 'Failed to fetch queue configuration',
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<QueueConfigurationModel> createConfig(
    Map<String, dynamic> configData,
  ) async {
    try {
      final responseData = await apiClient.post(
        ApiEndpoints.queueConfigCreate,
        data: configData,
      );

      if (responseData['success'] == true) {
        return QueueConfigurationModel.fromJson(responseData['data']);
      }

      throw ServerException(
        message:
            responseData['error'] ?? 'Failed to create queue configuration',
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<QueueConfigurationModel> updateConfig(
    String configId,
    Map<String, dynamic> configData,
  ) async {
    try {
      final responseData = await apiClient.put(
        ApiEndpoints.queueConfigDetail(configId),
        data: configData,
      );

      if (responseData['success'] == true) {
        return QueueConfigurationModel.fromJson(responseData['data']);
      }

      throw ServerException(
        message:
            responseData['error'] ?? 'Failed to update queue configuration',
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteConfig(String configId) async {
    try {
      final responseData = await apiClient.delete(
        ApiEndpoints.queueConfigDetail(configId),
      );

      if (responseData['success'] != true) {
        throw ServerException(
          message:
              responseData['error'] ?? 'Failed to delete queue configuration',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
