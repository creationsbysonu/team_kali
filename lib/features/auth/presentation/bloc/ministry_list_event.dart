part of 'ministry_list_bloc.dart';

/// Events for Ministry List BLoC
abstract class MinistryListEvent extends Equatable {
  const MinistryListEvent();

  @override
  List<Object?> get props => [];
}

/// Load ministries for a specific place
class LoadMinistriesByPlaceEvent extends MinistryListEvent {
  final String placeSlug;

  const LoadMinistriesByPlaceEvent({required this.placeSlug});

  @override
  List<Object?> get props => [placeSlug];
}

/// Retry loading ministries after error
class RetryLoadMinistriesEvent extends MinistryListEvent {
  final String placeSlug;

  const RetryLoadMinistriesEvent({required this.placeSlug});

  @override
  List<Object?> get props => [placeSlug];
}

/// Clear ministry list
class ClearMinistriesEvent extends MinistryListEvent {}
