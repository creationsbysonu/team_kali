import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/notice/domain/entities/filter_options_entity.dart';
import 'package:sewa_sathi/features/notice/domain/entities/notice_entity.dart';
import 'package:sewa_sathi/features/notice/domain/usecases/notice_usecases.dart';

part 'notice_event.dart';
part 'notice_state.dart';

/// BLoC for managing notice list, filters, and pagination.
class NoticeBloc extends Bloc<NoticeEvent, NoticeState> {
  final GetNoticesUseCase getNotices;
  final GetFilterOptionsUseCase getFilterOptions;

  NoticeParams _currentParams = const NoticeParams();
  final List<NoticeEntity> _allNotices = [];
  bool _hasMore = true;
  bool _isLoadingMore = false;

  NoticeBloc({required this.getNotices, required this.getFilterOptions})
    : super(NoticeInitial()) {
    on<LoadNoticesEvent>(_onLoadNotices);
    on<LoadMoreNoticesEvent>(_onLoadMoreNotices);
    on<RefreshNoticesEvent>(_onRefreshNotices);
    on<FilterNoticesEvent>(_onFilterNotices);
    on<SearchNoticesEvent>(_onSearchNotices);
    on<LoadFilterOptionsEvent>(_onLoadFilterOptions);
  }

  Future<void> _onLoadNotices(
    LoadNoticesEvent event,
    Emitter<NoticeState> emit,
  ) async {
    emit(NoticeLoading());

    _currentParams = event.params ?? const NoticeParams();
    _allNotices.clear();

    final result = await getNotices(_currentParams);

    result.fold((failure) => emit(NoticeError(message: failure.message)), (
      response,
    ) {
      _allNotices.addAll(response.results);
      _hasMore = response.hasMore;
      emit(
        NoticeLoaded(
          notices: List.from(_allNotices),
          hasMore: _hasMore,
          currentParams: _currentParams,
        ),
      );
    });
  }

  Future<void> _onLoadMoreNotices(
    LoadMoreNoticesEvent event,
    Emitter<NoticeState> emit,
  ) async {
    if (_isLoadingMore || !_hasMore || state is! NoticeLoaded) return;

    _isLoadingMore = true;
    emit((state as NoticeLoaded).copyWith(isLoadingMore: true));

    final newParams = _currentParams.copyWith(offset: _allNotices.length);

    final result = await getNotices(newParams);

    result.fold(
      (failure) {
        _isLoadingMore = false;
        emit((state as NoticeLoaded).copyWith(isLoadingMore: false));
      },
      (response) {
        _allNotices.addAll(response.results);
        _hasMore = response.hasMore;
        _isLoadingMore = false;
        emit(
          NoticeLoaded(
            notices: List.from(_allNotices),
            hasMore: _hasMore,
            currentParams: _currentParams,
            isLoadingMore: false,
          ),
        );
      },
    );
  }

  Future<void> _onRefreshNotices(
    RefreshNoticesEvent event,
    Emitter<NoticeState> emit,
  ) async {
    _allNotices.clear();
    final newParams = _currentParams.copyWith(offset: 0);

    final result = await getNotices(newParams);

    result.fold((failure) => emit(NoticeError(message: failure.message)), (
      response,
    ) {
      _allNotices.addAll(response.results);
      _hasMore = response.hasMore;
      emit(
        NoticeLoaded(
          notices: List.from(_allNotices),
          hasMore: _hasMore,
          currentParams: _currentParams,
        ),
      );
    });
  }

  Future<void> _onFilterNotices(
    FilterNoticesEvent event,
    Emitter<NoticeState> emit,
  ) async {
    emit(NoticeLoading());

    _currentParams = event.params;
    _allNotices.clear();

    final result = await getNotices(_currentParams);

    result.fold((failure) => emit(NoticeError(message: failure.message)), (
      response,
    ) {
      _allNotices.addAll(response.results);
      _hasMore = response.hasMore;
      emit(
        NoticeLoaded(
          notices: List.from(_allNotices),
          hasMore: _hasMore,
          currentParams: _currentParams,
        ),
      );
    });
  }

  Future<void> _onSearchNotices(
    SearchNoticesEvent event,
    Emitter<NoticeState> emit,
  ) async {
    emit(NoticeLoading());

    _currentParams = _currentParams.copyWith(search: event.query, offset: 0);
    _allNotices.clear();

    final result = await getNotices(_currentParams);

    result.fold((failure) => emit(NoticeError(message: failure.message)), (
      response,
    ) {
      _allNotices.addAll(response.results);
      _hasMore = response.hasMore;
      emit(
        NoticeLoaded(
          notices: List.from(_allNotices),
          hasMore: _hasMore,
          currentParams: _currentParams,
        ),
      );
    });
  }

  Future<void> _onLoadFilterOptions(
    LoadFilterOptionsEvent event,
    Emitter<NoticeState> emit,
  ) async {
    emit(FilterOptionsLoading());

    final result = await getFilterOptions(const NoParams());

    result.fold(
      (failure) => emit(FilterOptionsError(message: failure.message)),
      (options) => emit(FilterOptionsLoaded(options: options)),
    );
  }
}
