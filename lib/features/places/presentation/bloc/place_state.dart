part of 'place_bloc.dart';

/// Base class for all place states
abstract class PlaceState extends Equatable {
  const PlaceState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PlaceInitial extends PlaceState {}

/// Loading places
class PlaceLoading extends PlaceState {}

/// Places loaded successfully
class PlacesLoaded extends PlaceState {
  final List<Place> places;

  const PlacesLoaded({required this.places});

  @override
  List<Object?> get props => [places];
}

/// A place has been selected
class PlaceSelected extends PlaceState {
  final Place place;

  const PlaceSelected({required this.place});

  @override
  List<Object?> get props => [place];
}

/// Error loading places
class PlaceError extends PlaceState {
  final String message;

  const PlaceError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Loading for CRUD operation
class PlaceOperationLoading extends PlaceState {}

/// CRUD operation successful
class PlaceOperationSuccess extends PlaceState {
  final String message;
  final Place? place;

  const PlaceOperationSuccess({required this.message, this.place});

  @override
  List<Object?> get props => [message, place];
}

/// CRUD operation error
class PlaceOperationError extends PlaceState {
  final String message;

  const PlaceOperationError({required this.message});

  @override
  List<Object?> get props => [message];
}
