import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';
import 'package:sewa_web/features/super_admin/domain/repositories/ministry_repository.dart';

/// Use case to activate a ministry (Super Admin only)
class ActivateMinistryUseCase
    implements UseCase<Ministry, ActivateMinistryParams> {
  final MinistryRepository repository;

  ActivateMinistryUseCase(this.repository);

  @override
  Future<Either<Failure, Ministry>> call(ActivateMinistryParams params) async {
    return await repository.activateMinistry(params.id);
  }
}

class ActivateMinistryParams extends Equatable {
  final String id;

  const ActivateMinistryParams({required this.id});

  @override
  List<Object?> get props => [id];
}
