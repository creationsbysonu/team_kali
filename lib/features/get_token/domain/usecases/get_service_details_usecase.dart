import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/queue_config_entity.dart';
import 'package:sewa_sathi/features/get_token/domain/repositories/get_token_repository.dart';

/// Get service details use case.
class GetServiceDetailsUseCase
    implements UseCase<QueueConfigEntity, GetServiceDetailsParams> {
  final GetTokenRepository repository;

  GetServiceDetailsUseCase(this.repository);

  @override
  Future<Either<Failure, QueueConfigEntity>> call(
    GetServiceDetailsParams params,
  ) {
    return repository.getServiceDetails(params.serviceId);
  }
}

/// Parameters for GetServiceDetailsUseCase.
class GetServiceDetailsParams extends Equatable {
  final String serviceId;

  const GetServiceDetailsParams({required this.serviceId});

  @override
  List<Object?> get props => [serviceId];
}
