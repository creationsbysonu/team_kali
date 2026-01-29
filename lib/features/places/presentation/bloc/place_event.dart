part of 'place_bloc.dart';

/// Base class for all place events
abstract class PlaceEvent extends Equatable {
  const PlaceEvent();

  @override
  List<Object?> get props => [];
}

/// Load public places (for selection)
class LoadPublicPlacesEvent extends PlaceEvent {
  final bool forceRefresh;

  const LoadPublicPlacesEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

/// Load all places (admin)
class LoadAllPlacesEvent extends PlaceEvent {
  final bool forceRefresh;

  const LoadAllPlacesEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

/// Force refresh places (clears cache)
class RefreshPlacesEvent extends PlaceEvent {
  const RefreshPlacesEvent();
}

/// Select a place
class SelectPlaceEvent extends PlaceEvent {
  final Place place;

  const SelectPlaceEvent({required this.place});

  @override
  List<Object?> get props => [place];
}

/// Clear selected place
class ClearSelectedPlaceEvent extends PlaceEvent {}

/// Create a new place (super admin)
class CreatePlaceEvent extends PlaceEvent {
  final String name;
  final String slug;

  const CreatePlaceEvent({required this.name, required this.slug});

  @override
  List<Object?> get props => [name, slug];
}

/// Update place (super admin)
class UpdatePlaceEvent extends PlaceEvent {
  final String id;
  final String? name;
  final String? slug;
  final bool? isActive;

  const UpdatePlaceEvent({
    required this.id,
    this.name,
    this.slug,
    this.isActive,
  });

  @override
  List<Object?> get props => [id, name, slug, isActive];
}

/// Delete place (super admin)
class DeletePlaceEvent extends PlaceEvent {
  final String id;

  const DeletePlaceEvent({required this.id});

  @override
  List<Object?> get props => [id];
}
