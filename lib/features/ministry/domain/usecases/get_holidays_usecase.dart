import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/ministry/domain/entities/holiday.dart';
import 'package:sewa_web/features/ministry/domain/repositories/holidays_repository.dart';

class GetHolidaysParams extends Equatable {
  final int? year;
  final int? month;

  const GetHolidaysParams({this.year, this.month});

  @override
  List<Object?> get props => [year, month];
}

/// Get list of holidays with optional filters
class GetHolidaysUseCase implements UseCase<List<Holiday>, GetHolidaysParams> {
  final HolidaysRepository repository;

  GetHolidaysUseCase(this.repository);

  @override
  Future<Either<Failure, List<Holiday>>> call(GetHolidaysParams params) async {
    return await repository.getHolidays(year: params.year, month: params.month);
  }
}
