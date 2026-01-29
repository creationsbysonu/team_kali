import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/auth/domain/entities/otp_credentials.dart';
import 'package:sewa_sathi/features/auth/domain/repositories/auth_repository.dart';

/// Use case for requesting OTP to be sent to email.
class RequestOtpUseCase implements UseCase<bool, OtpRequest> {
  final AuthRepository repository;

  RequestOtpUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(OtpRequest params) async {
    // Validate email format
    if (!params.isValidEmail) {
      return const Left(
        ValidationFailure(message: 'Please enter a valid email address'),
      );
    }

    return repository.requestOtp(params);
  }
}
