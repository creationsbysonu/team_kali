part of 'notice_bloc.dart';

/// Base class for all notice events.
abstract class NoticeEvent extends Equatable {
  const NoticeEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load notices with optional parameters.
class LoadNoticesEvent extends NoticeEvent {
  final NoticeParams? params;

  const LoadNoticesEvent({this.params});

  @override
  List<Object?> get props => [params];
}

/// Event to load more notices (pagination).
class LoadMoreNoticesEvent extends NoticeEvent {}

/// Event to refresh notice list.
class RefreshNoticesEvent extends NoticeEvent {}

/// Event to filter notices.
class FilterNoticesEvent extends NoticeEvent {
  final NoticeParams params;

  const FilterNoticesEvent({required this.params});

  @override
  List<Object?> get props => [params];
}

/// Event to search notices.
class SearchNoticesEvent extends NoticeEvent {
  final String query;

  const SearchNoticesEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Event to load filter options.
class LoadFilterOptionsEvent extends NoticeEvent {}
