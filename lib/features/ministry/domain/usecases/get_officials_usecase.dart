import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/ministry/domain/entities/ministry_official.dart';
import 'package:sewa_web/features/ministry/domain/repositories/officials_repository.dart';

class GetOfficialsParams extends Equatable {
  final String? ministryId;
  final bool? isActive;

  const GetOfficialsParams({this.ministryId, this.isActive});

  @override
  List<Object?> get props => [ministryId, isActive];
}

/// Get list of officials with optional filters
class GetOfficialsUseCase
    implements UseCase<List<MinistryOfficial>, GetOfficialsParams> {
  final OfficialsRepository repository;

  GetOfficialsUseCase(this.repository);

  @override
  Future<Either<Failure, List<MinistryOfficial>>> call(
    GetOfficialsParams params,
  ) async {
    return await repository.getOfficials(
      ministryId: params.ministryId,
      isActive: params.isActive,
    );
  }
}
