import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';
import 'package:sewa_web/features/super_admin/domain/repositories/ministry_repository.dart';

/// Use case to suspend a ministry (Super Admin only)
class SuspendMinistryUseCase
    implements UseCase<Ministry, SuspendMinistryParams> {
  final MinistryRepository repository;

  SuspendMinistryUseCase(this.repository);

  @override
  Future<Either<Failure, Ministry>> call(SuspendMinistryParams params) async {
    return await repository.suspendMinistry(params.id, reason: params.reason);
  }
}

class SuspendMinistryParams extends Equatable {
  final String id;
  final String? reason;

  const SuspendMinistryParams({required this.id, this.reason});

  @override
  List<Object?> get props => [id, reason];
}
