import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';
import 'package:sewa_web/features/super_admin/domain/repositories/ministry_repository.dart';

/// Use case to get a ministry by ID (Super Admin only)
class GetMinistryByIdUseCase
    implements UseCase<Ministry, GetMinistryByIdParams> {
  final MinistryRepository repository;

  GetMinistryByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Ministry>> call(GetMinistryByIdParams params) async {
    return await repository.getMinistryById(params.id);
  }
}

class GetMinistryByIdParams extends Equatable {
  final String id;

  const GetMinistryByIdParams({required this.id});

  @override
  List<Object?> get props => [id];
}
