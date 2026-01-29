part of 'notice_bloc.dart';

/// Base class for notice states
abstract class NoticeState extends Equatable {
  const NoticeState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class NoticeInitial extends NoticeState {}

/// Loading state
class NoticeLoading extends NoticeState {}

/// Loading more notices (pagination)
class NoticeLoadingMore extends NoticeState {
  final List<NoticeEntity> notices;
  final int totalCount;

  const NoticeLoadingMore({required this.notices, required this.totalCount});

  @override
  List<Object?> get props => [notices, totalCount];
}

/// Notices loaded successfully
class NoticeLoaded extends NoticeState {
  final List<NoticeEntity> notices;
  final bool hasMore;
  final int totalCount;
  final NoticeStatsEntity? stats;

  const NoticeLoaded({
    required this.notices,
    required this.hasMore,
    required this.totalCount,
    this.stats,
  });

  NoticeLoaded copyWith({
    List<NoticeEntity>? notices,
    bool? hasMore,
    int? totalCount,
    NoticeStatsEntity? stats,
  }) {
    return NoticeLoaded(
      notices: notices ?? this.notices,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [notices, hasMore, totalCount, stats];
}

/// Error state
class NoticeError extends NoticeState {
  final String message;
  final List<NoticeEntity>? currentNotices;

  const NoticeError({required this.message, this.currentNotices});

  @override
  List<Object?> get props => [message, currentNotices];
}

/// Operation in progress (upload, update, delete)
class NoticeOperationInProgress extends NoticeState {
  final String message;
  final List<NoticeEntity> currentNotices;

  const NoticeOperationInProgress({
    required this.message,
    required this.currentNotices,
  });

  @override
  List<Object?> get props => [message, currentNotices];
}

/// Operation succeeded
class NoticeOperationSuccess extends NoticeState {
  final String message;
  final List<NoticeEntity> currentNotices;

  const NoticeOperationSuccess({
    required this.message,
    required this.currentNotices,
  });

  @override
  List<Object?> get props => [message, currentNotices];
}

/// Operation failed
class NoticeOperationFailure extends NoticeState {
  final String message;
  final List<NoticeEntity> currentNotices;

  const NoticeOperationFailure({
    required this.message,
    required this.currentNotices,
  });

  @override
  List<Object?> get props => [message, currentNotices];
}

/// Services loaded
class ServicesLoaded extends NoticeState {
  final List<NoticeServiceEntity> services;

  const ServicesLoaded({required this.services});

  @override
  List<Object?> get props => [services];
}
