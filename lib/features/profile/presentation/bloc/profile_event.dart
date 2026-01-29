part of 'profile_bloc.dart';

/// Base class for all profile events.
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check the current profile status.
class CheckProfileStatusEvent extends ProfileEvent {
  const CheckProfileStatusEvent();
}

/// Event to load the list of available places.
class LoadPlacesEvent extends ProfileEvent {
  const LoadPlacesEvent();
}

/// Event to setup a new profile.
class SetupProfileEvent extends ProfileEvent {
  final String fullName;
  final String placeId;

  const SetupProfileEvent({required this.fullName, required this.placeId});

  @override
  List<Object?> get props => [fullName, placeId];
}

/// Event to update an existing profile.
class UpdateProfileEvent extends ProfileEvent {
  final String? fullName;
  final String? placeId;

  const UpdateProfileEvent({this.fullName, this.placeId});

  @override
  List<Object?> get props => [fullName, placeId];
}

/// Event to clear any error messages.
class ClearProfileErrorEvent extends ProfileEvent {
  const ClearProfileErrorEvent();
}
