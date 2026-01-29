import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/paginated_response.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/staff_service_entity.dart';
import 'package:sewa_sathi/features/get_token/domain/repositories/get_token_repository.dart';

/// Get services by ministry ID use case with pagination.
class GetServicesUseCase
    implements
        UseCase<
          PaginatedServicesResponse<StaffServiceEntity>,
          GetServicesParams
        > {
  final GetTokenRepository repository;

  GetServicesUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedServicesResponse<StaffServiceEntity>>> call(
    GetServicesParams params,
  ) {
    return repository.getServicesByMinistry(
      ministryId: params.ministryId,
      cursor: params.cursor,
      pageSize: params.pageSize,
    );
  }
}

/// Parameters for GetServicesUseCase.
class GetServicesParams extends Equatable {
  final String ministryId;
  final String? cursor;
  final int pageSize;

  const GetServicesParams({
    required this.ministryId,
    this.cursor,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [ministryId, cursor, pageSize];
}
