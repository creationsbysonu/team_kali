import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/ministry/domain/repositories/staff_service_repository.dart';

/// Use case to delete a staff service
class DeleteStaffServiceUseCase
    implements UseCase<void, DeleteStaffServiceParams> {
  final StaffServiceRepository repository;

  DeleteStaffServiceUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteStaffServiceParams params) {
    if (params.id.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Service ID cannot be empty')),
      );
    }
    return repository.deleteStaffService(params.id.trim());
  }
}

class DeleteStaffServiceParams extends Equatable {
  final String id;

  const DeleteStaffServiceParams({required this.id});

  @override
  List<Object?> get props => [id];
}
