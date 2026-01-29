import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/queue_token_entity.dart';
import 'package:sewa_sathi/features/get_token/domain/repositories/get_token_repository.dart';

/// Book token use case.
class BookTokenUseCase implements UseCase<QueueTokenEntity, BookTokenParams> {
  final GetTokenRepository repository;

  BookTokenUseCase(this.repository);

  @override
  Future<Either<Failure, QueueTokenEntity>> call(BookTokenParams params) {
    return repository.bookToken(
      serviceId: params.serviceId,
      bookingType: params.bookingType,
      bookingDate: params.bookingDate,
    );
  }
}

/// Parameters for BookTokenUseCase.
class BookTokenParams extends Equatable {
  final String serviceId;
  final String bookingType;
  final String? bookingDate;

  const BookTokenParams({
    required this.serviceId,
    this.bookingType = 'REGULAR',
    this.bookingDate,
  });

  @override
  List<Object?> get props => [serviceId, bookingType, bookingDate];
}
