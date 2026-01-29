import 'package:sewa_web/core/constants/api_endpoints.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/network/api_client.dart';
import 'package:sewa_web/features/officials/data/models/official_model.dart';

/// Remote data source for Officials API operations
abstract class OfficialsRemoteDataSource {
  /// Get all officials for a ministry
  Future<List<OfficialModel>> getOfficials(String ministryId);

  /// Get a single official by ID
  Future<OfficialModel> getOfficialById(String officialId);

  /// Create a new official
  Future<OfficialModel> createOfficial(Map<String, dynamic> officialData);

  /// Update an existing official
  Future<OfficialModel> updateOfficial(
    String officialId,
    Map<String, dynamic> officialData,
  );

  /// Delete an official
  Future<void> deleteOfficial(String officialId);
}

class OfficialsRemoteDataSourceImpl implements OfficialsRemoteDataSource {
  final ApiClient apiClient;

  OfficialsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<OfficialModel>> getOfficials(String ministryId) async {
    try {
      final responseData = await apiClient.get(
        ApiEndpoints.officialsList(ministryId: ministryId),
      );

      // Debug logging
      print(
        'OfficialsRemoteDataSource: Response type: ${responseData.runtimeType}',
      );
      print('OfficialsRemoteDataSource: Response data: $responseData');

      // Handle different response formats:
      // 1. {success: true, data: [...]} - standard format
      // 2. {results: [...]} - DRF default format
      // 3. [...] - raw list
      List<dynamic> officialsJson;

      if (responseData is List) {
        // Raw list response
        print('OfficialsRemoteDataSource: Using raw list format');
        officialsJson = responseData;
      } else if (responseData['success'] == true &&
          responseData['data'] != null) {
        // Standard format with success flag
        print('OfficialsRemoteDataSource: Using success/data format');
        officialsJson = responseData['data'];
      } else if (responseData['results'] != null) {
        // DRF default paginated format
        print('OfficialsRemoteDataSource: Using results format');
        officialsJson = responseData['results'];
      } else if (responseData['data'] != null) {
        // Data without success flag
        print('OfficialsRemoteDataSource: Using data-only format');
        officialsJson = responseData['data'];
      } else {
        print(
          'OfficialsRemoteDataSource: No matching format found, throwing exception',
        );
        throw ServerException(
          message:
              responseData['error']?.toString() ?? 'Failed to fetch officials',
        );
      }

      print(
        'OfficialsRemoteDataSource: Parsing ${officialsJson.length} officials',
      );
      final officials = officialsJson
          .map((json) => OfficialModel.fromJson(json))
          .toList();
      print('OfficialsRemoteDataSource: Parsed ${officials.length} officials');
      return officials;
    } catch (e) {
      print('OfficialsRemoteDataSource: Error: $e');
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<OfficialModel> getOfficialById(String officialId) async {
    try {
      final responseData = await apiClient.get(
        ApiEndpoints.officialDetail(officialId),
      );

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['error'] ?? 'Failed to fetch official',
        );
      }

      return OfficialModel.fromJson(responseData['data']);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<OfficialModel> createOfficial(
    Map<String, dynamic> officialData,
  ) async {
    try {
      final responseData = await apiClient.post(
        ApiEndpoints.officialCreate,
        data: officialData,
      );

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['error'] ?? 'Failed to create official',
        );
      }

      return OfficialModel.fromJson(responseData['data']);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<OfficialModel> updateOfficial(
    String officialId,
    Map<String, dynamic> officialData,
  ) async {
    try {
      final responseData = await apiClient.put(
        ApiEndpoints.officialDetail(officialId),
        data: officialData,
      );

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['error'] ?? 'Failed to update official',
        );
      }

      return OfficialModel.fromJson(responseData['data']);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteOfficial(String officialId) async {
    try {
      final responseData = await apiClient.delete(
        ApiEndpoints.officialDetail(officialId),
      );

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['error'] ?? 'Failed to delete official',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
