import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/queue_management/domain/repositories/queue_config_repository.dart';

class GetAllServicesWithConfigsUseCase
    implements UseCase<Map<String, dynamic>, GetAllServicesWithConfigsParams> {
  final QueueConfigRepository repository;

  GetAllServicesWithConfigsUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    GetAllServicesWithConfigsParams params,
  ) async {
    return await repository.getAllServicesWithConfigs(params.ministryId);
  }
}

class GetAllServicesWithConfigsParams {
  final String ministryId;

  const GetAllServicesWithConfigsParams({required this.ministryId});
}
