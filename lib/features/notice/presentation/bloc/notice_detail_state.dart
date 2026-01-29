part of 'notice_detail_bloc.dart';

/// Base class for notice detail states.
abstract class NoticeDetailState extends Equatable {
  const NoticeDetailState();

  @override
  List<Object?> get props => [];
}

/// Initial state.
class NoticeDetailInitial extends NoticeDetailState {}

/// Loading state.
class NoticeDetailLoadInProgress extends NoticeDetailState {}

/// Success state with notice detail.
class NoticeDetailLoadSuccess extends NoticeDetailState {
  final NoticeDetailEntity notice;

  const NoticeDetailLoadSuccess({required this.notice});

  @override
  List<Object?> get props => [notice];
}

/// Error state.
class NoticeDetailLoadFailure extends NoticeDetailState {
  final String message;

  const NoticeDetailLoadFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
