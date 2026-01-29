import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/super_admin/domain/repositories/ministry_repository.dart';

/// Use case to delete a ministry (Super Admin only)
class DeleteMinistryUseCase implements UseCase<void, DeleteMinistryParams> {
  final MinistryRepository repository;

  DeleteMinistryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteMinistryParams params) async {
    return await repository.deleteMinistry(params.id);
  }
}

class DeleteMinistryParams extends Equatable {
  final String id;

  const DeleteMinistryParams({required this.id});

  @override
  List<Object?> get props => [id];
}
