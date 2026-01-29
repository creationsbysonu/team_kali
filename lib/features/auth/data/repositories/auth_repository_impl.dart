import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/auth/token_manager.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/network/network_info.dart';
import 'package:sewa_web/features/auth/data/data_sources/auth_local_data_source.dart';
import 'package:sewa_web/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:sewa_web/features/auth/data/models/auth_tokens_model.dart';
import 'package:sewa_web/features/auth/data/models/user_model.dart';
import 'package:sewa_web/features/auth/domain/entities/auth_credentials.dart';
import 'package:sewa_web/features/auth/domain/entities/auth_tokens.dart';
import 'package:sewa_web/features/auth/domain/entities/user_entity.dart';
import 'package:sewa_web/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final TokenManager tokenManager;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.tokenManager,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      // Get user from cache (stored during login)
      final cachedUser = await localDataSource.getUser();
      if (cachedUser != null) {
        // Simply return cached user - token validity is already checked
        // by AuthBloc before calling this method
        return Right(cachedUser);
      } else {
        // No cached user - not authenticated
        return const Right(null);
      }
    } on CacheException {
      return const Right(null);
    } catch (e) {
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithEmailAndPassword(
    AuthCredentials credentials,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.login(
          credentials.email,
          credentials.password,
          placeSlug: credentials.placeSlug,
          ministrySlug: credentials.ministrySlug,
          serviceSlug: credentials.serviceSlug,
        );

        // Parse complete login response including user and context
        final user = UserModel.fromLoginResponse(result);
        final tokens = AuthTokensModel.fromJson(result['tokens']);

        // Validate user type matches login context
        if (credentials.isAdminLogin) {
          // User tried to login via ministry admin portal
          if (user.isSuperAdmin) {
            return const Left(
              AuthenticationFailure(
                message:
                    'Super admin accounts must login through the admin portal',
              ),
            );
          }
          if (!user.isAdmin || user.ministry == null) {
            return const Left(
              AuthenticationFailure(
                message: 'This account is not a ministry admin',
              ),
            );
          }
        } else if (credentials.isStaffLogin) {
          // User tried to login via staff portal
          if (!user.isStaff || user.service == null) {
            return const Left(
              AuthenticationFailure(
                message:
                    'This account is not associated with the selected service',
              ),
            );
          }
        } else if (credentials.isSuperAdminLogin) {
          // User tried to login via super admin portal
          if (!user.isSuperAdmin) {
            return const Left(
              AuthenticationFailure(
                message:
                    'Access denied. Please login through your ministry portal',
              ),
            );
          }
        }

        // cache user and tokens
        await localDataSource.cacheUser(user);
        await localDataSource.cacheTokens(tokens);
        return Right(user);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on AuthenticationException catch (e) {
        return Left(AuthenticationFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      if (await networkInfo.isConnected) {
        try {
          await remoteDataSource.logout();
        } catch (e) {
          // continue with local logout even if remote fails
        }
      }
      // always clear local auth data
      await localDataSource.clearAuthData();
      return const Right(null);
    } on CacheException {
      return const Left(CacheFailure());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthTokens>> refreshTokens() async {
    if (await networkInfo.isConnected) {
      try {
        final newTokens = await remoteDataSource.refreshTokens();
        // Cache new tokens
        await localDataSource.cacheTokens(newTokens);

        return Right(newTokens);
      } on ServerException catch (e) {
        await localDataSource.clearAuthData();
        return Left(AuthenticationFailure(message: e.message));
      } on CacheException {
        return const Left(CacheFailure());
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> validateToken() async {
    if (await networkInfo.isConnected) {
      try {
        if (!await tokenManager.hasTokens()) {
          return const Right(false);
        }

        // Check if tokens are expired locally first
        final authStatus = await tokenManager.getAuthStatus();

        switch (authStatus) {
          case AuthStatus.authenticated:
            break;
          case AuthStatus.expired:
            final refreshed = await tokenManager.refreshTokens();
            if (!refreshed) {
              return const Right(false);
            }

            break;
          case AuthStatus.unauthenticated:
            return const Right(false);
        }
        final isValid = await remoteDataSource.validateToken();
        return Right(isValid);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      try {
        if (!await tokenManager.hasTokens()) {
          return const Right(false);
        }

        final authStatus = await tokenManager.getAuthStatus();
        return Right(authStatus == AuthStatus.authenticated);
      } on CacheException {
        return const Left(CacheFailure());
      } catch (e) {
        return const Left(CacheFailure());
      }
    }
  }
}
