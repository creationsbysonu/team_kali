part of 'notice_bloc.dart';

/// Base class for notice events
abstract class NoticeEvent extends Equatable {
  const NoticeEvent();

  @override
  List<Object?> get props => [];
}

/// Load notices with optional filters
class LoadNoticesEvent extends NoticeEvent {
  final String? serviceId;
  final String? status;
  final bool? isActive;
  final String? search;
  final String? ordering;

  const LoadNoticesEvent({
    this.serviceId,
    this.status,
    this.isActive,
    this.search,
    this.ordering,
  });

  @override
  List<Object?> get props => [serviceId, status, isActive, search, ordering];
}

/// Load more notices (pagination)
class LoadMoreNoticesEvent extends NoticeEvent {
  const LoadMoreNoticesEvent();
}

/// Refresh notices
class RefreshNoticesEvent extends NoticeEvent {
  const RefreshNoticesEvent();
}

/// Upload a new notice
/// For Ministry Admin: Backend attaches ministry info automatically
/// For Staff Admin: Backend attaches service info automatically (staff is linked to service)
class UploadNoticeEvent extends NoticeEvent {
  final String title;
  final Uint8List fileBytes;
  final String fileName;

  const UploadNoticeEvent({
    required this.title,
    required this.fileBytes,
    required this.fileName,
  });

  @override
  List<Object?> get props => [title, fileBytes, fileName];
}

/// Update notice metadata
class UpdateNoticeEvent extends NoticeEvent {
  final String noticeId;
  final String? title;
  final String? serviceId;
  final bool? isActive;

  const UpdateNoticeEvent({
    required this.noticeId,
    this.title,
    this.serviceId,
    this.isActive,
  });

  @override
  List<Object?> get props => [noticeId, title, serviceId, isActive];
}

/// Delete a notice
class DeleteNoticeEvent extends NoticeEvent {
  final String noticeId;

  const DeleteNoticeEvent({required this.noticeId});

  @override
  List<Object?> get props => [noticeId];
}

/// Load notice statistics
class LoadNoticeStatsEvent extends NoticeEvent {
  const LoadNoticeStatsEvent();
}

/// Retry failed ingestion
class RetryIngestionEvent extends NoticeEvent {
  final String noticeId;

  const RetryIngestionEvent({required this.noticeId});

  @override
  List<Object?> get props => [noticeId];
}

/// Load available services
class LoadServicesEvent extends NoticeEvent {
  const LoadServicesEvent();
}
