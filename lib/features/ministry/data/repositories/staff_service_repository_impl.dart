
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/network/network_info.dart';
import 'package:sewa_web/features/ministry/data/data_sources/staff_service_remote_data_source.dart';
import 'package:sewa_web/features/ministry/domain/entities/staff_service_entity.dart';
import 'package:sewa_web/features/ministry/domain/repositories/staff_service_repository.dart';

class StaffServiceRepositoryImpl implements StaffServiceRepository {
  final StaffServiceRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  StaffServiceRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<StaffService>>> getStaffServices() async {
    if (await networkInfo.isConnected) {
      try {
        final services = await remoteDataSource.getStaffServices();
        return Right(services);
      } on ServerException catch (e) {
        debugPrint('ServerException in getStaffServices: ${e.message}');
        return Left(ServerFailure(message: e.message));
      } on AuthenticationException catch (e) {
        debugPrint('AuthenticationException in getStaffServices: ${e.message}');
        return Left(AuthenticationFailure(message: e.message));
      } catch (e) {
        debugPrint('Unexpected error in getStaffServices: $e');
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, StaffService>> getStaffServiceById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final service = await remoteDataSource.getStaffServiceById(id);
        return Right(service);
      } on ServerException catch (e) {
        debugPrint('ServerException in getStaffServiceById: ${e.message}');
        return Left(ServerFailure(message: e.message));
      } on AuthenticationException catch (e) {
        debugPrint(
          'AuthenticationException in getStaffServiceById: ${e.message}',
        );
        return Left(AuthenticationFailure(message: e.message));
      } catch (e) {
        debugPrint('Unexpected error in getStaffServiceById: $e');
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, StaffService>> createStaffService({
    required String serviceName,
    required String staffName,
    required String email,
    required String password,
    Uint8List? serviceLogoBytes,
    String? serviceLogoFileName,
    Uint8List? staffImageBytes,
    String? staffImageFileName,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final service = await remoteDataSource.createStaffService(
          serviceName: serviceName,
          staffName: staffName,
          email: email,
          password: password,
          serviceLogoBytes: serviceLogoBytes,
          serviceLogoFileName: serviceLogoFileName,
          staffImageBytes: staffImageBytes,
          staffImageFileName: staffImageFileName,
        );
        return Right(service);
      } on ServerException catch (e) {
        debugPrint('ServerException in createStaffService: ${e.message}');
        return Left(ServerFailure(message: e.message));
      } on AuthenticationException catch (e) {
        debugPrint(
          'AuthenticationException in createStaffService: ${e.message}',
        );
        return Left(AuthenticationFailure(message: e.message));
      } catch (e) {
        debugPrint('Unexpected error in createStaffService: $e');
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, StaffService>> updateStaffService({
    required String id,
    String? serviceName,
    String? staffName,
    Uint8List? serviceLogoBytes,
    String? serviceLogoFileName,
    Uint8List? staffImageBytes,
    String? staffImageFileName,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final service = await remoteDataSource.updateStaffService(
          id: id,
          serviceName: serviceName,
          staffName: staffName,
          serviceLogoBytes: serviceLogoBytes,
          serviceLogoFileName: serviceLogoFileName,
          staffImageBytes: staffImageBytes,
          staffImageFileName: staffImageFileName,
        );
        return Right(service);
      } on ServerException catch (e) {
        debugPrint('ServerException in updateStaffService: ${e.message}');
        return Left(ServerFailure(message: e.message));
      } on AuthenticationException catch (e) {
        debugPrint(
          'AuthenticationException in updateStaffService: ${e.message}',
        );
        return Left(AuthenticationFailure(message: e.message));
      } catch (e) {
        debugPrint('Unexpected error in updateStaffService: $e');
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteStaffService(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteStaffService(id);
        return const Right(null);
      } on ServerException catch (e) {
        debugPrint('ServerException in deleteStaffService: ${e.message}');
        return Left(ServerFailure(message: e.message));
      } on AuthenticationException catch (e) {
        debugPrint(
          'AuthenticationException in deleteStaffService: ${e.message}',
        );
        return Left(AuthenticationFailure(message: e.message));
      } catch (e) {
        debugPrint('Unexpected error in deleteStaffService: $e');
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> resetStaffPassword(
    String id,
    String newPassword,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.resetStaffPassword(id, newPassword);
        return const Right(null);
      } on ServerException catch (e) {
        debugPrint('ServerException in resetStaffPassword: ${e.message}');
        return Left(ServerFailure(message: e.message));
      } on AuthenticationException catch (e) {
        debugPrint(
          'AuthenticationException in resetStaffPassword: ${e.message}',
        );
        return Left(AuthenticationFailure(message: e.message));
      } catch (e) {
        debugPrint('Unexpected error in resetStaffPassword: $e');
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, StaffService>> toggleStaffServiceStatus(
    String id,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final service = await remoteDataSource.toggleStaffServiceStatus(id);
        return Right(service);
      } on ServerException catch (e) {
        debugPrint('ServerException in toggleStaffServiceStatus: ${e.message}');
        return Left(ServerFailure(message: e.message));
      } on AuthenticationException catch (e) {
        debugPrint(
          'AuthenticationException in toggleStaffServiceStatus: ${e.message}',
        );
        return Left(AuthenticationFailure(message: e.message));
      } catch (e) {
        debugPrint('Unexpected error in toggleStaffServiceStatus: $e');
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}
