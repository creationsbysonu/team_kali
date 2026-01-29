import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/ministry_entity.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/paginated_response.dart';
import 'package:sewa_sathi/features/get_token/domain/repositories/get_token_repository.dart';

/// Get ministries by place ID use case with pagination.
class GetMinistriesUseCase
    implements
        UseCase<
          PaginatedMinistriesResponse<MinistryEntity>,
          GetMinistriesParams
        > {
  final GetTokenRepository repository;

  GetMinistriesUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedMinistriesResponse<MinistryEntity>>> call(
    GetMinistriesParams params,
  ) {
    return repository.getMinistriesByPlace(
      placeId: params.placeId,
      cursor: params.cursor,
      pageSize: params.pageSize,
    );
  }
}

/// Parameters for GetMinistriesUseCase.
class GetMinistriesParams extends Equatable {
  final String placeId;
  final String? cursor;
  final int pageSize;

  const GetMinistriesParams({
    required this.placeId,
    this.cursor,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [placeId, cursor, pageSize];
}
