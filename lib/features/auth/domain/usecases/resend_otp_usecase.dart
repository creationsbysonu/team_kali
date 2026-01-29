import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/auth/domain/entities/otp_credentials.dart';
import 'package:sewa_sathi/features/auth/domain/repositories/auth_repository.dart';

/// Use case for resending OTP to email.
class ResendOtpUseCase implements UseCase<bool, OtpRequest> {
  final AuthRepository repository;

  ResendOtpUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(OtpRequest params) async {
    // Validate email format
    if (!params.isValidEmail) {
      return const Left(
        ValidationFailure(message: 'Please enter a valid email address'),
      );
    }

    return repository.resendOtp(params);
  }
}
