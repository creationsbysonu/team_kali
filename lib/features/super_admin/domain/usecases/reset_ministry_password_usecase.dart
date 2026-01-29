import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/super_admin/domain/repositories/ministry_repository.dart';

/// Reset ministry admin password (Super Admin only)
class ResetMinistryPasswordUseCase
    implements UseCase<void, ResetMinistryPasswordParams> {
  final MinistryRepository repository;

  ResetMinistryPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ResetMinistryPasswordParams params) {
    return repository.resetMinistryPassword(params.id, params.newPassword);
  }
}

class ResetMinistryPasswordParams extends Equatable {
  final String id;
  final String newPassword;

  const ResetMinistryPasswordParams({
    required this.id,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [id, newPassword];
}
