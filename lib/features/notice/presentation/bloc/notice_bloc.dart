import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/notice/domain/entities/notice_entity.dart';
import 'package:sewa_web/features/notice/domain/repositories/notice_repository.dart';
import 'package:sewa_web/features/notice/domain/usecases/notice_usecases.dart';

part 'notice_event.dart';
part 'notice_state.dart';

/// Notice BLoC for managing notice operations
class NoticeBloc extends Bloc<NoticeEvent, NoticeState> {
  final GetNoticesUseCase getNotices;
  final GetNoticeByIdUseCase getNoticeById;
  final UploadNoticeUseCase uploadNotice;
  final UpdateNoticeUseCase updateNotice;
  final DeleteNoticeUseCase deleteNotice;
  final GetNoticeStatsUseCase getNoticeStats;
  final RetryIngestionUseCase retryIngestion;
  final GetNoticeServicesUseCase getNoticeServices;

  NoticeBloc({
    required this.getNotices,
    required this.getNoticeById,
    required this.uploadNotice,
    required this.updateNotice,
    required this.deleteNotice,
    required this.getNoticeStats,
    required this.retryIngestion,
    required this.getNoticeServices,
  }) : super(NoticeInitial()) {
    on<LoadNoticesEvent>(_onLoadNotices);
    on<LoadMoreNoticesEvent>(_onLoadMoreNotices);
    on<UploadNoticeEvent>(_onUploadNotice);
    on<UpdateNoticeEvent>(_onUpdateNotice);
    on<DeleteNoticeEvent>(_onDeleteNotice);
    on<LoadNoticeStatsEvent>(_onLoadNoticeStats);
    on<RetryIngestionEvent>(_onRetryIngestion);
    on<LoadServicesEvent>(_onLoadServices);
    on<RefreshNoticesEvent>(_onRefreshNotices);
  }

  /// Current filter parameters
  GetNoticesParams _currentParams = const GetNoticesParams();

  /// Current notices list
  List<NoticeEntity> _currentNotices = [];

  /// Total count
  int _totalCount = 0;

  Future<void> _onLoadNotices(
    LoadNoticesEvent event,
    Emitter<NoticeState> emit,
  ) async {
    emit(NoticeLoading());

    _currentParams = GetNoticesParams(
      serviceId: event.serviceId,
      status: event.status,
      isActive: event.isActive,
      search: event.search,
      ordering: event.ordering,
      page: 1,
    );

    final result = await getNotices(_currentParams);

    result.fold((failure) => emit(NoticeError(message: failure.message)), (
      response,
    ) {
      _currentNotices = response.results;
      _totalCount = response.count;
      emit(
        NoticeLoaded(
          notices: _currentNotices,
          hasMore: response.hasMore,
          totalCount: _totalCount,
        ),
      );
    });
  }

  Future<void> _onLoadMoreNotices(
    LoadMoreNoticesEvent event,
    Emitter<NoticeState> emit,
  ) async {
    if (state is! NoticeLoaded) return;

    final currentState = state as NoticeLoaded;
    if (!currentState.hasMore) return;

    emit(NoticeLoadingMore(notices: _currentNotices, totalCount: _totalCount));

    _currentParams = GetNoticesParams(
      serviceId: _currentParams.serviceId,
      status: _currentParams.status,
      isActive: _currentParams.isActive,
      search: _currentParams.search,
      ordering: _currentParams.ordering,
      page: _currentParams.page + 1,
    );

    final result = await getNotices(_currentParams);

    result.fold(
      (failure) => emit(
        NoticeLoaded(
          notices: _currentNotices,
          hasMore: currentState.hasMore,
          totalCount: _totalCount,
        ),
      ),
      (response) {
        _currentNotices = [..._currentNotices, ...response.results];
        emit(
          NoticeLoaded(
            notices: _currentNotices,
            hasMore: response.hasMore,
            totalCount: _totalCount,
          ),
        );
      },
    );
  }

  Future<void> _onRefreshNotices(
    RefreshNoticesEvent event,
    Emitter<NoticeState> emit,
  ) async {
    final result = await getNotices(
      GetNoticesParams(
        serviceId: _currentParams.serviceId,
        status: _currentParams.status,
        isActive: _currentParams.isActive,
        search: _currentParams.search,
        ordering: _currentParams.ordering,
        page: 1,
      ),
    );

    result.fold(
      (failure) => emit(
        NoticeError(message: failure.message, currentNotices: _currentNotices),
      ),
      (response) {
        _currentNotices = response.results;
        _totalCount = response.count;
        emit(
          NoticeLoaded(
            notices: _currentNotices,
            hasMore: response.hasMore,
            totalCount: _totalCount,
          ),
        );
      },
    );
  }

  Future<void> _onUploadNotice(
    UploadNoticeEvent event,
    Emitter<NoticeState> emit,
  ) async {
    emit(
      NoticeOperationInProgress(
        message: 'Uploading notice...',
        currentNotices: _currentNotices,
      ),
    );

    final params = UploadNoticeParams(
      title: event.title,
      fileBytes: event.fileBytes,
      fileName: event.fileName,
    );

    final result = await uploadNotice(params);

    result.fold(
      (failure) => emit(
        NoticeOperationFailure(
          message: failure.message,
          currentNotices: _currentNotices,
        ),
      ),
      (notice) {
        _currentNotices = [notice, ..._currentNotices];
        _totalCount++;
        emit(
          NoticeOperationSuccess(
            message: 'Notice uploaded successfully. Document ingestion queued.',
            currentNotices: _currentNotices,
          ),
        );
      },
    );
  }

  Future<void> _onUpdateNotice(
    UpdateNoticeEvent event,
    Emitter<NoticeState> emit,
  ) async {
    emit(
      NoticeOperationInProgress(
        message: 'Updating notice...',
        currentNotices: _currentNotices,
      ),
    );

    final params = UpdateNoticeParams(
      noticeId: event.noticeId,
      title: event.title,
      serviceId: event.serviceId,
      isActive: event.isActive,
    );

    final result = await updateNotice(params);

    result.fold(
      (failure) => emit(
        NoticeOperationFailure(
          message: failure.message,
          currentNotices: _currentNotices,
        ),
      ),
      (updatedNotice) {
        _currentNotices = _currentNotices.map((n) {
          return n.id == updatedNotice.id ? updatedNotice : n;
        }).toList();
        emit(
          NoticeOperationSuccess(
            message: 'Notice updated successfully',
            currentNotices: _currentNotices,
          ),
        );
      },
    );
  }

  Future<void> _onDeleteNotice(
    DeleteNoticeEvent event,
    Emitter<NoticeState> emit,
  ) async {
    emit(
      NoticeOperationInProgress(
        message: 'Deleting notice...',
        currentNotices: _currentNotices,
      ),
    );

    final result = await deleteNotice(event.noticeId);

    result.fold(
      (failure) => emit(
        NoticeOperationFailure(
          message: failure.message,
          currentNotices: _currentNotices,
        ),
      ),
      (_) {
        _currentNotices = _currentNotices
            .where((n) => n.id != event.noticeId)
            .toList();
        _totalCount--;
        emit(
          NoticeOperationSuccess(
            message: 'Notice deleted successfully',
            currentNotices: _currentNotices,
          ),
        );
      },
    );
  }

  Future<void> _onLoadNoticeStats(
    LoadNoticeStatsEvent event,
    Emitter<NoticeState> emit,
  ) async {
    final result = await getNoticeStats(const NoParams());

    result.fold(
      (failure) {
        // Stats loading failure shouldn't affect the main state
      },
      (stats) {
        if (state is NoticeLoaded) {
          emit((state as NoticeLoaded).copyWith(stats: stats));
        }
      },
    );
  }

  Future<void> _onRetryIngestion(
    RetryIngestionEvent event,
    Emitter<NoticeState> emit,
  ) async {
    emit(
      NoticeOperationInProgress(
        message: 'Retrying ingestion...',
        currentNotices: _currentNotices,
      ),
    );

    final result = await retryIngestion(event.noticeId);

    result.fold(
      (failure) => emit(
        NoticeOperationFailure(
          message: failure.message,
          currentNotices: _currentNotices,
        ),
      ),
      (_) {
        // Update the notice status to pending
        _currentNotices = _currentNotices.map((n) {
          if (n.id == event.noticeId) {
            return n.copyWith(ingestionStatus: IngestionStatus.pending);
          }
          return n;
        }).toList();
        emit(
          NoticeOperationSuccess(
            message: 'Ingestion retry queued',
            currentNotices: _currentNotices,
          ),
        );
      },
    );
  }

  Future<void> _onLoadServices(
    LoadServicesEvent event,
    Emitter<NoticeState> emit,
  ) async {
    final result = await getNoticeServices(const NoParams());

    result.fold(
      (failure) {
        // Services loading failure - emit with empty services
        emit(const ServicesLoaded(services: []));
      },
      (services) {
        emit(ServicesLoaded(services: services));
      },
    );
  }
}
