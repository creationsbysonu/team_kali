import 'package:sewa_web/core/constants/api_endpoints.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/network/api_client.dart';
import 'package:sewa_web/features/holidays/data/models/holiday_model.dart';

/// Remote data source for Holidays API operations
abstract class HolidaysRemoteDataSource {
  Future<List<HolidayModel>> getHolidays({int? year, int? month});
  Future<HolidayModel> getHolidayById(String holidayId);
  Future<HolidayModel> createHoliday(Map<String, dynamic> holidayData);
  Future<HolidayModel> updateHoliday(
    String holidayId,
    Map<String, dynamic> holidayData,
  );
  Future<void> deleteHoliday(String holidayId);
}

class HolidaysRemoteDataSourceImpl implements HolidaysRemoteDataSource {
  final ApiClient apiClient;

  HolidaysRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<HolidayModel>> getHolidays({int? year, int? month}) async {
    try {
      final responseData = await apiClient.get(
        ApiEndpoints.holidaysList(year: year, month: month),
      );

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['error'] ?? 'Failed to fetch holidays',
        );
      }

      final List<dynamic> holidaysJson = responseData['data'];
      return holidaysJson.map((json) => HolidayModel.fromJson(json)).toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<HolidayModel> getHolidayById(String holidayId) async {
    // NOTE: Backend doesn't have a GET detail endpoint
    // Holidays are fetched via list endpoint only
    throw UnimplementedError(
      'Backend does not support GET /holidays/<id>/ endpoint. Use getHolidays() instead.',
    );
  }

  @override
  Future<HolidayModel> createHoliday(Map<String, dynamic> holidayData) async {
    try {
      final responseData = await apiClient.post(
        ApiEndpoints.holidayCreate,
        data: holidayData,
      );

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['error'] ?? 'Failed to create holiday',
        );
      }

      return HolidayModel.fromJson(responseData['data']);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<HolidayModel> updateHoliday(
    String holidayId,
    Map<String, dynamic> holidayData,
  ) async {
    try {
      final responseData = await apiClient.patch(
        ApiEndpoints.holidayUpdate(holidayId),
        data: holidayData,
      );

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['error'] ?? 'Failed to update holiday',
        );
      }

      return HolidayModel.fromJson(responseData['data']);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteHoliday(String holidayId) async {
    try {
      final responseData = await apiClient.delete(
        ApiEndpoints.holidayDelete(holidayId),
      );

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['error'] ?? 'Failed to delete holiday',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
