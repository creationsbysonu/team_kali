import 'package:sewa_sathi/features/notice/data/models/notice_model.dart';
import 'package:sewa_sathi/features/notice/domain/entities/notice_list_response_entity.dart';

/// Model for Notice List Response with JSON serialization.
class NoticeListResponseModel extends NoticeListResponseEntity {
  const NoticeListResponseModel({
    required super.results,
    required super.count,
    required super.limit,
    required super.offset,
    required super.hasMore,
  });

  factory NoticeListResponseModel.fromJson(Map<String, dynamic> json) {
    return NoticeListResponseModel(
      results: (json['results'] as List)
          .map((n) => NoticeModel.fromJson(n))
          .toList(),
      count: json['count'],
      limit: json['limit'],
      offset: json['offset'],
      hasMore: json['has_more'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'results': results
          .map((n) => NoticeModel.fromEntity(n).toJson())
          .toList(),
      'count': count,
      'limit': limit,
      'offset': offset,
      'has_more': hasMore,
    };
  }
}
