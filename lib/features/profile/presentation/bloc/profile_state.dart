part of 'profile_bloc.dart';

/// Base class for all profile states.
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state when BLoC is created.
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// State when a profile operation is in progress.
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// State when profile status has been checked.
class ProfileStatusChecked extends ProfileState {
  final ProfileEntity? profile;
  final bool isComplete;

  const ProfileStatusChecked({this.profile, required this.isComplete});

  @override
  List<Object?> get props => [profile, isComplete];
}

/// State when places have been loaded successfully.
class PlacesLoaded extends ProfileState {
  final List<PlaceEntity> places;

  const PlacesLoaded({required this.places});

  @override
  List<Object?> get props => [places];
}

/// State when profile has been setup successfully.
class ProfileSetupSuccess extends ProfileState {
  final ProfileEntity profile;

  const ProfileSetupSuccess({required this.profile});

  @override
  List<Object?> get props => [profile];
}

/// State when profile has been updated successfully.
class ProfileUpdateSuccess extends ProfileState {
  final ProfileEntity profile;

  const ProfileUpdateSuccess({required this.profile});

  @override
  List<Object?> get props => [profile];
}

/// State when a profile operation fails.
class ProfileError extends ProfileState {
  final String message;

  const ProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}
