import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/get_token_entities.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/paginated_response.dart';

/// Abstract repository for Get Token feature.
/// Follows Citizen API v1 with cursor-based pagination.
abstract class GetTokenRepository {
  /// Get ministries by place ID with pagination.
  ///
  /// Parameters:
  /// - placeId: The place ID to fetch ministries for
  /// - cursor: Optional pagination cursor from previous response
  /// - pageSize: Items per page (1-50, default 20)
  Future<Either<Failure, PaginatedMinistriesResponse<MinistryEntity>>>
  getMinistriesByPlace({
    required String placeId,
    String? cursor,
    int pageSize = 20,
  });

  /// Get services by ministry ID with pagination.
  Future<Either<Failure, PaginatedServicesResponse<StaffServiceEntity>>>
  getServicesByMinistry({
    required String ministryId,
    String? cursor,
    int pageSize = 20,
  });

  /// Get service details with queue configuration.
  Future<Either<Failure, QueueConfigEntity>> getServiceDetails(
    String serviceId,
  );

  /// Book a token.
  Future<Either<Failure, QueueTokenEntity>> bookToken({
    required String serviceId,
    required String bookingType,
    String? bookingDate,
  });

  /// Get user's tokens with pagination.
  ///
  /// Parameters:
  /// - status: Filter by ACTIVE, COMPLETED, CANCELLED
  /// - cursor: Optional pagination cursor
  /// - pageSize: Items per page (1-50, default 20)
  Future<Either<Failure, PaginatedResponse<QueueTokenEntity>>> getMyTokens({
    String? status,
    String? cursor,
    int pageSize = 20,
  });

  /// Cancel a token.
  Future<Either<Failure, void>> cancelToken(String tokenId);
}
