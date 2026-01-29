import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/paginated_response.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/queue_token_entity.dart';
import 'package:sewa_sathi/features/get_token/domain/repositories/get_token_repository.dart';

/// Get user's tokens use case with pagination.
class GetMyTokensUseCase
    implements UseCase<PaginatedResponse<QueueTokenEntity>, GetMyTokensParams> {
  final GetTokenRepository repository;

  GetMyTokensUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResponse<QueueTokenEntity>>> call(
    GetMyTokensParams params,
  ) {
    return repository.getMyTokens(
      status: params.status,
      cursor: params.cursor,
      pageSize: params.pageSize,
    );
  }
}

/// Parameters for GetMyTokensUseCase.
///
/// Status values:
/// - ACTIVE: Active tokens (WAITING, IN_SERVICE, PENDING)
/// - COMPLETED: Completed tokens
/// - CANCELLED: Cancelled tokens
class GetMyTokensParams extends Equatable {
  final String? status;
  final String? cursor;
  final int pageSize;

  const GetMyTokensParams({this.status, this.cursor, this.pageSize = 20});

  @override
  List<Object?> get props => [status, cursor, pageSize];
}
