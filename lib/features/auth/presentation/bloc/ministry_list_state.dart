part of 'ministry_list_bloc.dart';

/// States for Ministry List BLoC
abstract class MinistryListState extends Equatable {
  const MinistryListState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class MinistryListInitial extends MinistryListState {}

/// Loading ministries
class MinistryListLoading extends MinistryListState {}

/// Ministries loaded successfully
class MinistriesLoaded extends MinistryListState {
  final List<Ministry> ministries;
  final String placeSlug;

  const MinistriesLoaded({required this.ministries, required this.placeSlug});

  @override
  List<Object?> get props => [ministries, placeSlug];
}

/// Error loading ministries
class MinistryListError extends MinistryListState {
  final String message;
  final String? placeSlug;

  const MinistryListError({required this.message, this.placeSlug});

  @override
  List<Object?> get props => [message, placeSlug];
}
