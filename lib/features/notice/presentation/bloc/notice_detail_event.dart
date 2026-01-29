part of 'notice_detail_bloc.dart';

/// Base class for notice detail events.
abstract class NoticeDetailEvent extends Equatable {
  const NoticeDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load notice detail.
class LoadNoticeDetail extends NoticeDetailEvent {
  final String noticeId;

  const LoadNoticeDetail({required this.noticeId});

  @override
  List<Object?> get props => [noticeId];
}
