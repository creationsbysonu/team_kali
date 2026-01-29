import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/holidays/domain/entities/holiday.dart';
import 'package:sewa_web/features/holidays/domain/repositories/holidays_repository.dart';

class UpdateHolidayParams {
  final String holidayId;
  final String name;
  final DateTime date;
  final String? description;

  const UpdateHolidayParams({
    required this.holidayId,
    required this.name,
    required this.date,
    this.description,
  });
}

class UpdateHolidayUseCase implements UseCase<Holiday, UpdateHolidayParams> {
  final HolidaysRepository repository;

  UpdateHolidayUseCase(this.repository);

  @override
  Future<Either<Failure, Holiday>> call(UpdateHolidayParams params) async {
    // Validation
    if (params.holidayId.isEmpty) {
      return const Left(ValidationFailure(message: 'Holiday ID is required'));
    }

    if (params.name.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Holiday name is required'));
    }

    return await repository.updateHoliday(
      holidayId: params.holidayId,
      name: params.name,
      date: params.date,
      description: params.description,
    );
  }
}
