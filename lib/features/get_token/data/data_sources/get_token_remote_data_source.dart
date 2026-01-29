import 'package:flutter/foundation.dart';
import 'package:sewa_sathi/core/constants/api_endpoints.dart';
import 'package:sewa_sathi/core/errors/exceptions.dart';
import 'package:sewa_sathi/core/network/api_client.dart';
import 'package:sewa_sathi/features/get_token/data/models/get_token_models.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/paginated_response.dart';

/// Remote data source for Get Token feature.
/// Follows Citizen API v1 with cursor-based pagination.
abstract class GetTokenRemoteDataSource {
  /// Get ministries by place ID with pagination.
  ///
  /// Query parameters:
  /// - cursor: Pagination cursor from previous response
  /// - pageSize: Items per page (1-50, default 20)
  Future<PaginatedMinistriesResponse<MinistryModel>> getMinistriesByPlace({
    required String placeId,
    String? cursor,
    int pageSize = 20,
  });

  /// Get services by ministry ID with pagination.
  Future<PaginatedServicesResponse<StaffServiceModel>> getServicesByMinistry({
    required String ministryId,
    String? cursor,
    int pageSize = 20,
  });

  /// Get service details.
  Future<QueueConfigModel> getServiceDetails(String serviceId);

  /// Book a token.
  Future<QueueTokenModel> bookToken({
    required String serviceId,
    required String bookingType,
    String? bookingDate,
  });

  /// Get user's tokens with pagination.
  ///
  /// Query parameters:
  /// - status: Filter by ACTIVE, COMPLETED, CANCELLED
  /// - cursor: Pagination cursor
  /// - pageSize: Items per page (1-50, default 20)
  Future<PaginatedResponse<QueueTokenModel>> getMyTokens({
    String? status,
    String? cursor,
    int pageSize = 20,
  });

  /// Cancel a token.
  Future<void> cancelToken(String tokenId);
}

/// Implementation of GetTokenRemoteDataSource.
class GetTokenRemoteDataSourceImpl implements GetTokenRemoteDataSource {
  final ApiClient apiClient;

  GetTokenRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<PaginatedMinistriesResponse<MinistryModel>> getMinistriesByPlace({
    required String placeId,
    String? cursor,
    int pageSize = 20,
  }) async {
    try {
      debugPrint(
        '🏛️ Fetching ministries for place: $placeId (cursor: $cursor)',
      );

      final queryParams = <String, dynamic>{'page_size': pageSize.clamp(1, 50)};
      if (cursor != null) {
        queryParams['cursor'] = cursor;
      }

      final response = await apiClient.get(
        ApiEndpoints.ministriesByPlace(placeId),
        queryParameters: queryParams,
      );

      if (response['success'] == true) {
        final result = PaginatedMinistriesResponseModel.fromJson<MinistryModel>(
          response,
          MinistryModel.fromJson,
        );
        debugPrint(
          '✅ Loaded ${result.items.length} ministries (hasMore: ${result.hasMore})',
        );
        return result;
      }

      throw ServerException(
        message: response['error'] ?? 'Failed to load ministries',
      );
    } catch (e) {
      debugPrint('❌ Failed to load ministries: $e');
      rethrow;
    }
  }

  @override
  Future<PaginatedServicesResponse<StaffServiceModel>> getServicesByMinistry({
    required String ministryId,
    String? cursor,
    int pageSize = 20,
  }) async {
    try {
      debugPrint(
        '📋 Fetching services for ministry: $ministryId (cursor: $cursor)',
      );

      final queryParams = <String, dynamic>{'page_size': pageSize.clamp(1, 50)};
      if (cursor != null) {
        queryParams['cursor'] = cursor;
      }

      final response = await apiClient.get(
        ApiEndpoints.servicesByMinistry(ministryId),
        queryParameters: queryParams,
      );

      if (response['success'] == true) {
        final result =
            PaginatedServicesResponseModel.fromJson<StaffServiceModel>(
              response,
              StaffServiceModel.fromJson,
            );
        debugPrint(
          '✅ Loaded ${result.items.length} services (hasMore: ${result.hasMore})',
        );
        return result;
      }

      throw ServerException(
        message: response['error'] ?? 'Failed to load services',
      );
    } catch (e) {
      debugPrint('❌ Failed to load services: $e');
      rethrow;
    }
  }

  @override
  Future<QueueConfigModel> getServiceDetails(String serviceId) async {
    try {
      debugPrint('📄 Fetching service details: $serviceId');

      final response = await apiClient.get(
        ApiEndpoints.serviceDetails(serviceId),
      );

      if (response['success'] == true) {
        final config = QueueConfigModel.fromJson(response['data']);
        debugPrint('✅ Loaded service details: ${config.serviceName}');
        return config;
      }

      throw ServerException(
        message: response['error'] ?? 'Failed to load service details',
      );
    } catch (e) {
      debugPrint('❌ Failed to load service details: $e');
      rethrow;
    }
  }

  @override
  Future<QueueTokenModel> bookToken({
    required String serviceId,
    required String bookingType,
    String? bookingDate,
  }) async {
    try {
      debugPrint('🎟️ Booking token for service: $serviceId');

      final data = <String, dynamic>{
        'service_id': serviceId,
        'booking_type': bookingType,
      };

      if (bookingDate != null) {
        data['booking_date'] = bookingDate;
      }

      final response = await apiClient.post(ApiEndpoints.bookToken, data: data);

      if (response['success'] == true) {
        final token = QueueTokenModel.fromJson(response['data']);
        debugPrint('✅ Token booked: #${token.tokenNumber}');
        return token;
      }

      throw ServerException(
        message: response['error'] ?? 'Failed to book token',
      );
    } catch (e) {
      debugPrint('❌ Failed to book token: $e');
      rethrow;
    }
  }

  @override
  Future<PaginatedResponse<QueueTokenModel>> getMyTokens({
    String? status,
    String? cursor,
    int pageSize = 20,
  }) async {
    try {
      debugPrint('📋 Fetching my tokens (status: $status, cursor: $cursor)');

      final queryParams = <String, dynamic>{'page_size': pageSize.clamp(1, 50)};
      if (status != null) {
        queryParams['status'] = status;
      }
      if (cursor != null) {
        queryParams['cursor'] = cursor;
      }

      final response = await apiClient.get(
        ApiEndpoints.myTokens,
        queryParameters: queryParams,
      );

      if (response['success'] == true) {
        final result = PaginatedResponseModel.fromJson<QueueTokenModel>(
          response,
          QueueTokenModel.fromJson,
        );
        debugPrint(
          '✅ Loaded ${result.items.length} tokens (hasMore: ${result.hasMore})',
        );
        return result;
      }

      throw ServerException(
        message: response['error'] ?? 'Failed to load tokens',
      );
    } catch (e) {
      debugPrint('❌ Failed to load tokens: $e');
      rethrow;
    }
  }

  @override
  Future<void> cancelToken(String tokenId) async {
    try {
      debugPrint('❌ Cancelling token: $tokenId');

      final response = await apiClient.post(ApiEndpoints.cancelToken(tokenId));

      if (response['success'] == true) {
        debugPrint('✅ Token cancelled successfully');
        return;
      }

      throw ServerException(
        message: response['error'] ?? 'Failed to cancel token',
      );
    } catch (e) {
      debugPrint('❌ Failed to cancel token: $e');
      rethrow;
    }
  }
}
