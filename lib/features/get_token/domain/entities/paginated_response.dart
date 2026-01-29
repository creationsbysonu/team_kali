import 'package:equatable/equatable.dart';

/// Pagination info from API response.
class PaginationInfo extends Equatable {
  final String? nextCursor;
  final bool hasMore;
  final int? totalEstimate;

  const PaginationInfo({
    this.nextCursor,
    required this.hasMore,
    this.totalEstimate,
  });

  @override
  List<Object?> get props => [nextCursor, hasMore, totalEstimate];
}

/// Generic paginated response following Citizen API v1 format.
///
/// Response structure:
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
class PaginatedResponse<T> extends Equatable {
  final List<T> items;
  final PaginationInfo pagination;

  const PaginatedResponse({required this.items, required this.pagination});

  /// Convenience getters
  String? get nextCursor => pagination.nextCursor;
  bool get hasMore => pagination.hasMore;
  int? get totalEstimate => pagination.totalEstimate;
  int get itemCount => items.length;
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  @override
  List<Object?> get props => [items, pagination];

  /// Create a new PaginatedResponse with merged items.
  /// Used for infinite scroll - appends new items to existing list.
  PaginatedResponse<T> merge(PaginatedResponse<T> other) {
    return PaginatedResponse<T>(
      items: [...items, ...other.items],
      pagination: other.pagination,
    );
  }

  /// Create an empty PaginatedResponse.
  static PaginatedResponse<T> empty<T>() {
    return PaginatedResponse<T>(
      items: [],
      pagination: const PaginationInfo(hasMore: false),
    );
  }
}

/// Place info returned with ministries response.
class PlaceInfo extends Equatable {
  final String id;
  final String name;
  final String slug;

  const PlaceInfo({required this.id, required this.name, required this.slug});

  @override
  List<Object?> get props => [id, name, slug];
}

/// Ministry info returned with services response.
class MinistryInfo extends Equatable {
  final String id;
  final String name;
  final String slug;

  const MinistryInfo({
    required this.id,
    required this.name,
    required this.slug,
  });

  @override
  List<Object?> get props => [id, name, slug];
}

/// Extended paginated response for ministries with place context.
class PaginatedMinistriesResponse<T> extends PaginatedResponse<T> {
  final PlaceInfo? place;

  const PaginatedMinistriesResponse({
    required super.items,
    required super.pagination,
    this.place,
  });

  @override
  List<Object?> get props => [items, pagination, place];
}

/// Extended paginated response for services with ministry context.
class PaginatedServicesResponse<T> extends PaginatedResponse<T> {
  final MinistryInfo? ministry;

  const PaginatedServicesResponse({
    required super.items,
    required super.pagination,
    this.ministry,
  });

  @override
  List<Object?> get props => [items, pagination, ministry];
}
