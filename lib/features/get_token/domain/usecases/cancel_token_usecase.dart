import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/get_token/domain/repositories/get_token_repository.dart';

/// Cancel token use case.
class CancelTokenUseCase implements UseCase<void, CancelTokenParams> {
  final GetTokenRepository repository;

  CancelTokenUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CancelTokenParams params) {
    return repository.cancelToken(params.tokenId);
  }
}

/// Parameters for CancelTokenUseCase.
class CancelTokenParams extends Equatable {
  final String tokenId;

  const CancelTokenParams({required this.tokenId});

  @override
  List<Object?> get props => [tokenId];
}
