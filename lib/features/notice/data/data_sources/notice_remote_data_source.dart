import 'package:sewa_sathi/core/constants/api_endpoints.dart';
import 'package:sewa_sathi/core/errors/exceptions.dart';
import 'package:sewa_sathi/core/network/api_client.dart';
import 'package:sewa_sathi/features/notice/data/models/filter_options_model.dart';
import 'package:sewa_sathi/features/notice/data/models/notice_detail_model.dart';
import 'package:sewa_sathi/features/notice/data/models/notice_list_response_model.dart';

/// Abstract data source for notice remote operations.
abstract class NoticeRemoteDataSource {
  Future<NoticeListResponseModel> getNotices({
    String? ministryId,
    String? serviceId,
    String? fileType,
    String? search,
    int limit = 20,
    int offset = 0,
  });

  Future<NoticeDetailModel> getNoticeDetail(String noticeId);

  Future<FilterOptionsModel> getFilterOptions();
}

/// Implementation of NoticeRemoteDataSource using ApiClient.
class NoticeRemoteDataSourceImpl implements NoticeRemoteDataSource {
  final ApiClient apiClient;

  NoticeRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<NoticeListResponseModel> getNotices({
    String? ministryId,
    String? serviceId,
    String? fileType,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit, 'offset': offset};

      if (ministryId != null) queryParams['ministry'] = ministryId;
      if (serviceId != null) queryParams['service'] = serviceId;
      if (fileType != null) queryParams['file_type'] = fileType;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final responseData = await apiClient.get(
        ApiEndpoints.notices,
        queryParameters: queryParams,
      );

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['error'] ?? 'Failed to fetch notices',
        );
      }

      return NoticeListResponseModel.fromJson(responseData['data']);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to fetch notices: $e');
    }
  }

  @override
  Future<NoticeDetailModel> getNoticeDetail(String noticeId) async {
    try {
      final responseData = await apiClient.get(
        ApiEndpoints.noticeDetail(noticeId),
      );

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['error'] ?? 'Notice not found',
        );
      }

      return NoticeDetailModel.fromJson(responseData['data']);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to fetch notice detail: $e');
    }
  }

  @override
  Future<FilterOptionsModel> getFilterOptions() async {
    try {
      final responseData = await apiClient.get(ApiEndpoints.noticeFilters);

      if (responseData['success'] != true) {
        throw ServerException(
          message: responseData['error'] ?? 'Failed to fetch filters',
        );
      }

      return FilterOptionsModel.fromJson(responseData['data']);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to fetch filter options: $e');
    }
  }
}
