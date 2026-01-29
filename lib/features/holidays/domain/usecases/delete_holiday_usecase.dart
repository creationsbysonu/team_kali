import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/holidays/domain/repositories/holidays_repository.dart';

class DeleteHolidayParams {
  final String holidayId;

  const DeleteHolidayParams({required this.holidayId});
}

class DeleteHolidayUseCase implements UseCase<void, DeleteHolidayParams> {
  final HolidaysRepository repository;

  DeleteHolidayUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteHolidayParams params) async {
    if (params.holidayId.isEmpty) {
      return const Left(ValidationFailure(message: 'Holiday ID is required'));
    }

    return await repository.deleteHoliday(params.holidayId);
  }
}
