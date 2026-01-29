import 'package:sewa_web/core/constants/api_endpoints.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/network/api_client.dart';
import 'package:sewa_web/features/staff_queue/data/models/staff_token_model.dart';

/// Abstract Staff Queue Remote Data Source (New System)
abstract class StaffQueueRemoteDataSource {
  /// Get active tokens (WAITING, IN_SERVICE)
  Future<ActiveTokensDataModel> getActiveTokens(String staffServiceId);

  /// Get all tokens (complete history)
  Future<AllTokensDataModel> getAllTokens(String staffServiceId);

  /// Get pending tokens (government fault)
  Future<PendingTokensDataModel> getPendingTokens(String staffServiceId);

  /// Start service for a token
  Future<StartServiceResultModel> startService(String tokenId);

  /// Mark token as no-show
  Future<NoShowResultModel> markNoShow(String tokenId);

  /// Mark token as pending
  Future<MarkPendingResultModel> markPending(String tokenId, String reason);

  /// Send pending email notification
  Future<void> sendPendingEmail(String tokenId);

  /// Mark pending token as served
  Future<MarkPendingServedResultModel> markPendingServed(String tokenId);
}

/// Implementation of Staff Queue Remote Data Source (New System)
class StaffQueueRemoteDataSourceImpl implements StaffQueueRemoteDataSource {
  final ApiClient apiClient;

  StaffQueueRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ActiveTokensDataModel> getActiveTokens(String staffServiceId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.staffActiveTokens(staffServiceId),
      );

      if (response is Map<String, dynamic>) {
        final data = response['data'] ?? response;
        return ActiveTokensDataModel.fromJson(data);
      }

      throw ServerException(message: 'Invalid response format');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<AllTokensDataModel> getAllTokens(String staffServiceId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.staffAllTokens(staffServiceId),
      );

      if (response is Map<String, dynamic>) {
        final data = response['data'] ?? response;
        return AllTokensDataModel.fromJson(data);
      }

      throw ServerException(message: 'Invalid response format');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<PendingTokensDataModel> getPendingTokens(String staffServiceId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.staffPendingTokens(staffServiceId),
      );

      if (response is Map<String, dynamic>) {
        final data = response['data'] ?? response;
        return PendingTokensDataModel.fromJson(data);
      }

      throw ServerException(message: 'Invalid response format');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<StartServiceResultModel> startService(String tokenId) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.staffStartService(tokenId),
      );

      if (response is Map<String, dynamic>) {
        final data = response['data'] ?? response;
        return StartServiceResultModel.fromJson(data);
      }

      throw ServerException(message: 'Invalid response format');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<NoShowResultModel> markNoShow(String tokenId) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.staffMarkNoShow,
        data: {'token_id': tokenId},
      );

      if (response is Map<String, dynamic>) {
        final data = response['data'] ?? response;
        return NoShowResultModel.fromJson(data);
      }

      throw ServerException(message: 'Invalid response format');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<MarkPendingResultModel> markPending(
    String tokenId,
    String reason,
  ) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.staffMarkPending(tokenId),
        data: {'reason': reason},
      );

      if (response is Map<String, dynamic>) {
        final data = response['data'] ?? response;
        return MarkPendingResultModel.fromJson(data);
      }

      throw ServerException(message: 'Invalid response format');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> sendPendingEmail(String tokenId) async {
    try {
      await apiClient.post(ApiEndpoints.staffSendPendingEmail(tokenId));
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<MarkPendingServedResultModel> markPendingServed(String tokenId) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.staffMarkPendingServed(tokenId),
      );

      if (response is Map<String, dynamic>) {
        final data = response['data'] ?? response;
        return MarkPendingServedResultModel.fromJson(data);
      }

      throw ServerException(message: 'Invalid response format');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
