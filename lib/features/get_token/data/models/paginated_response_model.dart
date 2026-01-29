import 'package:sewa_sathi/features/get_token/domain/entities/paginated_response.dart';

/// Pagination info model with JSON serialization.
class PaginationInfoModel extends PaginationInfo {
  const PaginationInfoModel({
    super.nextCursor,
    required super.hasMore,
    super.totalEstimate,
  });

  /// Create from JSON response.
  ///
  /// Expected JSON structure:
  /// ```json
  /// {
  ///   "next_cursor": "YWJj...",
  ///   "has_more": true,
  ///   "total_estimate": 100
  /// }
  /// ```
  factory PaginationInfoModel.fromJson(Map<String, dynamic> json) {
    return PaginationInfoModel(
      nextCursor: json['next_cursor'],
      hasMore: json['has_more'] ?? false,
      totalEstimate: json['total_estimate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'next_cursor': nextCursor,
      'has_more': hasMore,
      'total_estimate': totalEstimate,
    };
  }
}

/// Place info model with JSON serialization.
class PlaceInfoModel extends PlaceInfo {
  const PlaceInfoModel({
    required super.id,
    required super.name,
    required super.slug,
  });

  factory PlaceInfoModel.fromJson(Map<String, dynamic> json) {
    return PlaceInfoModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug};
  }
}

/// Ministry info model with JSON serialization.
class MinistryInfoModel extends MinistryInfo {
  const MinistryInfoModel({
    required super.id,
    required super.name,
    required super.slug,
  });

  factory MinistryInfoModel.fromJson(Map<String, dynamic> json) {
    return MinistryInfoModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug};
  }
}

/// Generic paginated response model with JSON serialization.
///
/// Parses the standard Citizen API v1 response format:
/// ```json
/// {
///   "success": true,
///   "data": {
///     "items": [...],
///     "pagination": {
///       "next_cursor": "string | null",
///       "has_more": true,
///       "total_estimate": 100
///     }
///   }
/// }
/// ```
class PaginatedResponseModel<T> extends PaginatedResponse<T> {
  const PaginatedResponseModel({
    required super.items,
    required super.pagination,
  });

  /// Create from JSON response with a custom item parser.
  static PaginatedResponseModel<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final data = json['data'] ?? json;
    final itemsJson = data['items'] as List? ?? [];
    final paginationJson = data['pagination'] as Map<String, dynamic>? ?? {};

    return PaginatedResponseModel<T>(
      items: itemsJson
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfoModel.fromJson(paginationJson),
    );
  }
}

/// Paginated ministries response model.
class PaginatedMinistriesResponseModel<T>
    extends PaginatedMinistriesResponse<T> {
  const PaginatedMinistriesResponseModel({
    required super.items,
    required super.pagination,
    super.place,
  });

  /// Create from JSON response with a custom item parser.
  static PaginatedMinistriesResponseModel<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final data = json['data'] ?? json;
    final itemsJson = data['items'] as List? ?? [];
    final paginationJson = data['pagination'] as Map<String, dynamic>? ?? {};
    final placeJson = data['place'] as Map<String, dynamic>?;

    return PaginatedMinistriesResponseModel<T>(
      items: itemsJson
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfoModel.fromJson(paginationJson),
      place: placeJson != null ? PlaceInfoModel.fromJson(placeJson) : null,
    );
  }
}

/// Paginated services response model.
class PaginatedServicesResponseModel<T> extends PaginatedServicesResponse<T> {
  const PaginatedServicesResponseModel({
    required super.items,
    required super.pagination,
    super.ministry,
  });

  /// Create from JSON response with a custom item parser.
  static PaginatedServicesResponseModel<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final data = json['data'] ?? json;
    final itemsJson = data['items'] as List? ?? [];
    final paginationJson = data['pagination'] as Map<String, dynamic>? ?? {};
    final ministryJson = data['ministry'] as Map<String, dynamic>?;

    return PaginatedServicesResponseModel<T>(
      items: itemsJson
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfoModel.fromJson(paginationJson),
      ministry: ministryJson != null
          ? MinistryInfoModel.fromJson(ministryJson)
          : null,
    );
  }
}
