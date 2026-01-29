import 'package:dartz/dartz.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/network/network_info.dart';
import 'package:sewa_web/features/staff/data/data_sources/staff_remote_data_source.dart';
import 'package:sewa_web/features/staff/domain/entities/staff_member.dart';
import 'package:sewa_web/features/staff/domain/repositories/staff_repository.dart';

/// Implementation of StaffRepository
class StaffRepositoryImpl implements StaffRepository {
  final StaffRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  StaffRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<StaffMember>>> getMinistryStaff() async {
    if (await networkInfo.isConnected) {
      try {
        final staff = await remoteDataSource.getMinistryStaff();
        return Right(staff);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, StaffMember>> getStaffById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final staff = await remoteDataSource.getStaffById(id);
        return Right(staff);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, StaffMember>> createStaff({
    required String name,
    required String email,
    required String password,
    required String serviceId,
    String? contact,
    String? imagePath,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final staff = await remoteDataSource.createStaff(
          name: name,
          email: email,
          password: password,
          serviceId: serviceId,
          contact: contact,
          imagePath: imagePath,
        );
        return Right(staff);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, StaffMember>> updateStaff({
    required String id,
    String? name,
    String? contact,
    String? password,
    bool? isActive,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final staff = await remoteDataSource.updateStaff(
          id: id,
          name: name,
          contact: contact,
          password: password,
          isActive: isActive,
        );
        return Right(staff);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteStaff(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteStaff(id);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> resetStaffPassword({
    required String staffId,
    required String newPassword,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.resetStaffPassword(
          staffId: staffId,
          newPassword: newPassword,
        );
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
