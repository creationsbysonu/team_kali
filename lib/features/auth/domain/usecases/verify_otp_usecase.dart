import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/auth/domain/entities/auth_response.dart';
import 'package:sewa_sathi/features/auth/domain/entities/otp_credentials.dart';
import 'package:sewa_sathi/features/auth/domain/repositories/auth_repository.dart';

/// Use case for verifying OTP and authenticating user.
class VerifyOtpUseCase implements UseCase<AuthResponse, OtpVerification> {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResponse>> call(OtpVerification params) async {
    // Validate OTP format
    if (!params.isValidOtp) {
      return const Left(
        ValidationFailure(message: 'Please enter a valid 6-digit OTP'),
      );
    }

    return repository.verifyOtp(params);
  }
}
