import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/ministry/domain/entities/queue_configuration.dart';
import 'package:sewa_web/features/ministry/domain/repositories/queue_config_repository.dart';

class GetConfigByServiceParams extends Equatable {
  final String staffServiceId;

  const GetConfigByServiceParams({required this.staffServiceId});

  @override
  List<Object?> get props => [staffServiceId];
}

/// Get queue configuration by staff service ID
class GetConfigByServiceUseCase
    implements UseCase<QueueConfiguration?, GetConfigByServiceParams> {
  final QueueConfigRepository repository;

  GetConfigByServiceUseCase(this.repository);

  @override
  Future<Either<Failure, QueueConfiguration?>> call(
    GetConfigByServiceParams params,
  ) async {
    return await repository.getConfigByServiceId(params.staffServiceId);
  }
}
