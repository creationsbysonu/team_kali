import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';
import 'package:sewa_web/features/super_admin/domain/repositories/ministry_repository.dart';

/// Restore a soft-deleted ministry
class RestoreMinistryUseCase
    implements UseCase<Ministry, RestoreMinistryParams> {
  final MinistryRepository repository;

  RestoreMinistryUseCase(this.repository);

  @override
  Future<Either<Failure, Ministry>> call(RestoreMinistryParams params) {
    return repository.restoreMinistry(params.id);
  }
}

class RestoreMinistryParams extends Equatable {
  final String id;

  const RestoreMinistryParams({required this.id});

  @override
  List<Object?> get props => [id];
}
