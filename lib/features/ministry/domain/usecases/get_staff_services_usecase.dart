import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/ministry/domain/entities/staff_service_entity.dart';
import 'package:sewa_web/features/ministry/domain/repositories/staff_service_repository.dart';

/// Use case to fetch all staff services
class GetStaffServicesUseCase implements UseCase<List<StaffService>, NoParams> {
  final StaffServiceRepository repository;

  GetStaffServicesUseCase(this.repository);

  @override
  Future<Either<Failure, List<StaffService>>> call(NoParams params) {
    return repository.getStaffServices();
  }
}
