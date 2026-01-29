import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sewa_web/core/errors/failures.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';
import 'package:sewa_web/features/super_admin/domain/repositories/ministry_repository.dart';

/// Use case to get all ministries for Super Admin
/// Requires authentication with super_admin role
class GetAdminMinistriesUseCase
    implements UseCase<List<Ministry>, AdminMinistriesParams> {
  final MinistryRepository repository;

  GetAdminMinistriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Ministry>>> call(
    AdminMinistriesParams params,
  ) async {
    return await repository.getAdminMinistries(
      place: params.placeId,
      status: params.status,
      search: params.search,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}

class AdminMinistriesParams extends Equatable {
  final String? placeId;
  final String? status;
  final String? search;
  final int? page;
  final int? pageSize;

  const AdminMinistriesParams({
    this.placeId,
    this.status,
    this.search,
    this.page,
    this.pageSize,
  });

  @override
  List<Object?> get props => [placeId, status, search, page, pageSize];
}
