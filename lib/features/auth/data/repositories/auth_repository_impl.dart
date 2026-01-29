import 'package:dartz/dartz.dart';
import 'package:sewa_sathi/core/errors/exceptions.dart';
import 'package:sewa_sathi/core/errors/failures.dart';
import 'package:sewa_sathi/core/network/network_info.dart';
import 'package:sewa_sathi/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:sewa_sathi/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:sewa_sathi/features/auth/domain/entities/auth_response.dart';
import 'package:sewa_sathi/features/auth/domain/entities/auth_tokens.dart';
import 'package:sewa_sathi/features/auth/domain/entities/otp_credentials.dart';
import 'package:sewa_sathi/features/auth/domain/entities/user_entity.dart';
import 'package:sewa_sathi/features/auth/domain/repositories/auth_repository.dart';

/// Implementation of AuthRepository.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, bool>> requestOtp(OtpRequest request) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await remoteDataSource.requestOtp(request.email);
      return Right(result);
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthResponse>> verifyOtp(
    OtpVerification verification,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final response = await remoteDataSource.verifyOtp(
        verification.email,
        verification.otp,
      );

      // Cache user and tokens
      await localDataSource.cacheUser(response.userModel);
      await localDataSource.cacheTokens(response.tokensModel);

      return Right(response);
    } on OtpException catch (e) {
      return Left(OtpFailure(message: e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(message: e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> resendOtp(OtpRequest request) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await remoteDataSource.resendOtp(request.email);
      return Right(result);
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getProfile() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final user = await remoteDataSource.getProfile();

      // Update cached user
      await localDataSource.cacheUser(user);

      return Right(user);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthTokens>> refreshTokens() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final currentTokens = await localDataSource.getTokens();
      if (currentTokens == null) {
        return const Left(
          AuthenticationFailure(message: 'No refresh token available'),
        );
      }

      final newTokens = await remoteDataSource.refreshTokens(
        currentTokens.refreshToken,
      );

      // Update cached tokens
      await localDataSource.cacheTokens(newTokens);

      return Right(newTokens);
    } on AuthenticationException catch (e) {
      // Clear tokens on refresh failure
      await localDataSource.clearAll();
      return Left(AuthenticationFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Try to logout on server
      final tokens = await localDataSource.getTokens();
      if (tokens != null) {
        await remoteDataSource.logout(tokens.refreshToken);
      }
    } catch (_) {
      // Ignore server errors
    }

    // Always clear local data
    try {
      await localDataSource.clearAll();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final hasTokens = await localDataSource.hasTokens();
      return Right(hasTokens);
    } catch (e) {
      return const Right(false);
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCachedUser() async {
    try {
      final user = await localDataSource.getUser();
      return Right(user);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }
}
