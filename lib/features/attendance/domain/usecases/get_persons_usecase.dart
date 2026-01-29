import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/attendance/domain/repositories/attendance_repository.dart';

class GetPersonsUseCase
    implements UseCase<List<Map<String, String>>, GetPersonsParams> {
  final AttendanceRepository repository;

  GetPersonsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Map<String, String>>>> call(
    GetPersonsParams params,
  ) async {
    return await repository.getPersons(
      personType: params.personType,
      ministryId: params.ministryId,
    );
  }
}

class GetPersonsParams {
  final String personType;
  final String? ministryId;

  const GetPersonsParams({required this.personType, this.ministryId});
}
