import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:sewa_web/core/constants/api_endpoints.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/network/api_client.dart';
import 'package:sewa_web/features/notice/data/models/notice_model.dart';
import 'package:sewa_web/features/notice/domain/repositories/notice_repository.dart';

/// Notice Remote Data Source Interface
abstract class NoticeRemoteDataSource {
  /// Get notices with filters
  Future<NoticeListResponseModel> getNotices(GetNoticesParams params);

  /// Get notice by ID
  Future<NoticeModel> getNoticeById(String noticeId);

  /// Upload a new notice
  /// Backend auto-determines ministry/service from user context:
  /// - Ministry Admin: Attaches ministry info
  /// - Staff Admin: Attaches service info (staff is linked to service)
  Future<NoticeModel> uploadNotice({
    required String title,
    required Uint8List fileBytes,
    required String fileName,
  });

  /// Update notice metadata
  Future<NoticeModel> updateNotice({
    required String noticeId,
    String? title,
    String? serviceId,
    bool? isActive,
  });

  /// Delete notice
  Future<void> deleteNotice(String noticeId);

  /// Get notice statistics
  Future<NoticeStatsModel> getStats();

  /// Retry failed ingestion
  Future<void> retryIngestion(String noticeId);

  /// Get available services
  Future<List<NoticeServiceModel>> getServices();
}

/// Notice Remote Data Source Implementation
class NoticeRemoteDataSourceImpl implements NoticeRemoteDataSource {
  final ApiClient apiClient;

  NoticeRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<NoticeListResponseModel> getNotices(GetNoticesParams params) async {
    try {
      final queryParams = <String, dynamic>{
        'page': params.page,
        'page_size': params.pageSize,
      };

      if (params.serviceId != null) {
        queryParams['service'] = params.serviceId;
      }
      if (params.status != null) {
        queryParams['status'] = params.status;
      }
      if (params.isActive != null) {
        queryParams['is_active'] = params.isActive.toString();
      }
      if (params.search != null && params.search!.isNotEmpty) {
        queryParams['search'] = params.search;
      }
      if (params.ordering != null) {
        queryParams['ordering'] = params.ordering;
      }

      final response = await apiClient.get(
        ApiEndpoints.adminNotices,
        queryParameters: queryParams,
      );

      return NoticeListResponseModel.fromJson(response as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['error'] ?? 'Failed to fetch notices',
      );
    }
  }

  @override
  Future<NoticeModel> getNoticeById(String noticeId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.adminNoticeDetail(noticeId),
      );

      final data = response as Map<String, dynamic>;
      final noticeData = data['data'] as Map<String, dynamic>? ?? data;

      return NoticeModel.fromJson(noticeData);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['error'] ?? 'Failed to fetch notice',
      );
    }
  }

  @override
  Future<NoticeModel> uploadNotice({
    required String title,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });

      final response = await apiClient.postFormData(
        ApiEndpoints.adminNotices,
        data: formData,
      );

      final data = response as Map<String, dynamic>;
      final noticeData = data['data'] as Map<String, dynamic>? ?? data;

      return NoticeModel.fromJson(noticeData);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['error'] ?? 'Failed to upload notice',
      );
    }
  }

  @override
  Future<NoticeModel> updateNotice({
    required String noticeId,
    String? title,
    String? serviceId,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (serviceId != null) data['service'] = serviceId;
      if (isActive != null) data['is_active'] = isActive;

      final response = await apiClient.patch(
        ApiEndpoints.adminNoticeDetail(noticeId),
        data: data,
      );

      final responseData = response as Map<String, dynamic>;
      final noticeData =
          responseData['data'] as Map<String, dynamic>? ?? responseData;

      return NoticeModel.fromJson(noticeData);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['error'] ?? 'Failed to update notice',
      );
    }
  }

  @override
  Future<void> deleteNotice(String noticeId) async {
    try {
      await apiClient.delete(ApiEndpoints.adminNoticeDetail(noticeId));
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['error'] ?? 'Failed to delete notice',
      );
    }
  }

  @override
  Future<NoticeStatsModel> getStats() async {
    try {
      final response = await apiClient.get(ApiEndpoints.adminNoticeStats);

      final data = response as Map<String, dynamic>;
      final statsData = data['data'] as Map<String, dynamic>? ?? data;

      return NoticeStatsModel.fromJson(statsData);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['error'] ?? 'Failed to fetch statistics',
      );
    }
  }

  @override
  Future<void> retryIngestion(String noticeId) async {
    try {
      await apiClient.post(ApiEndpoints.adminNoticeRetryIngestion(noticeId));
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['error'] ?? 'Failed to retry ingestion',
      );
    }
  }

  @override
  Future<List<NoticeServiceModel>> getServices() async {
    try {
      final response = await apiClient.get(ApiEndpoints.adminNoticeServices);

      final data = response as Map<String, dynamic>;
      final servicesList = data['data'] as List<dynamic>? ?? [];

      return servicesList
          .map((e) => NoticeServiceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['error'] ?? 'Failed to fetch services',
      );
    }
  }
}
