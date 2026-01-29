part of 'notice_bloc.dart';

/// Base class for all notice states.
abstract class NoticeState extends Equatable {
  const NoticeState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded.
class NoticeInitial extends NoticeState {}

/// State when loading notices.
class NoticeLoading extends NoticeState {}

/// State when notices are loaded successfully.
class NoticeLoaded extends NoticeState {
  final List<NoticeEntity> notices;
  final bool hasMore;
  final NoticeParams currentParams;
  final bool isLoadingMore;

  const NoticeLoaded({
    required this.notices,
    required this.hasMore,
    required this.currentParams,
    this.isLoadingMore = false,
  });

  NoticeLoaded copyWith({
    List<NoticeEntity>? notices,
    bool? hasMore,
    NoticeParams? currentParams,
    bool? isLoadingMore,
  }) {
    return NoticeLoaded(
      notices: notices ?? this.notices,
      hasMore: hasMore ?? this.hasMore,
      currentParams: currentParams ?? this.currentParams,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [notices, hasMore, currentParams, isLoadingMore];
}

/// State when error occurs while loading notices.
class NoticeError extends NoticeState {
  final String message;

  const NoticeError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// State when loading filter options.
class FilterOptionsLoading extends NoticeState {}

/// State when filter options are loaded successfully.
class FilterOptionsLoaded extends NoticeState {
  final FilterOptionsEntity options;

  const FilterOptionsLoaded({required this.options});

  @override
  List<Object?> get props => [options];
}

/// State when error occurs while loading filter options.
class FilterOptionsError extends NoticeState {
  final String message;

  const FilterOptionsError({required this.message});

  @override
  List<Object?> get props => [message];
}
