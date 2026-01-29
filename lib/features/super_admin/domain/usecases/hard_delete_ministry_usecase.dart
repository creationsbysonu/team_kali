import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/super_admin/domain/repositories/ministry_repository.dart';

/// Permanently delete a ministry (cannot be undone)
class HardDeleteMinistryUseCase
    implements UseCase<void, HardDeleteMinistryParams> {
  final MinistryRepository repository;

  HardDeleteMinistryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(HardDeleteMinistryParams params) {
    return repository.hardDeleteMinistry(params.id);
  }
}

class HardDeleteMinistryParams extends Equatable {
  final String id;

  const HardDeleteMinistryParams({required this.id});

  @override
  List<Object?> get props => [id];
}
