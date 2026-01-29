import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/holidays/domain/entities/holiday.dart';
import 'package:sewa_web/features/holidays/domain/repositories/holidays_repository.dart';

class CreateHolidayParams {
  final String name;
  final DateTime date;
  final String? description;

  const CreateHolidayParams({
    required this.name,
    required this.date,
    this.description,
  });
}

class CreateHolidayUseCase implements UseCase<Holiday, CreateHolidayParams> {
  final HolidaysRepository repository;

  CreateHolidayUseCase(this.repository);

  @override
  Future<Either<Failure, Holiday>> call(CreateHolidayParams params) async {
    // Validation
    if (params.name.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Holiday name is required'));
    }

    return await repository.createHoliday(
      name: params.name,
      date: params.date,
      description: params.description,
    );
  }
}
