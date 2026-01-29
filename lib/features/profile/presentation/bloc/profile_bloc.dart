import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/profile/domain/entities/place_entity.dart';
import 'package:sewa_sathi/features/profile/domain/entities/profile_entity.dart';
import 'package:sewa_sathi/features/profile/domain/usecases/profile_usecases.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// BLoC for managing profile-related state and operations.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final CheckProfileStatusUseCase checkProfileStatus;
  final GetPlacesUseCase getPlaces;
  final SetupProfileUseCase setupProfile;
  final UpdateProfileUseCase updateProfile;

  ProfileBloc({
    required this.checkProfileStatus,
    required this.getPlaces,
    required this.setupProfile,
    required this.updateProfile,
  }) : super(const ProfileInitial()) {
    on<CheckProfileStatusEvent>(_onCheckProfileStatus);
    on<LoadPlacesEvent>(_onLoadPlaces);
    on<SetupProfileEvent>(_onSetupProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<ClearProfileErrorEvent>(_onClearError);
  }

  Future<void> _onCheckProfileStatus(
    CheckProfileStatusEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await checkProfileStatus(const NoParams());

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (profile) => emit(
        ProfileStatusChecked(
          profile: profile,
          isComplete: profile?.isProfileComplete ?? false,
        ),
      ),
    );
  }

  Future<void> _onLoadPlaces(
    LoadPlacesEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await getPlaces(const NoParams());

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (places) => emit(PlacesLoaded(places: places)),
    );
  }

  Future<void> _onSetupProfile(
    SetupProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final params = SetupProfileParams(
      fullName: event.fullName,
      placeId: event.placeId,
    );

    final result = await setupProfile(params);

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (profile) => emit(ProfileSetupSuccess(profile: profile)),
    );
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final params = UpdateProfileParams(
      fullName: event.fullName,
      placeId: event.placeId,
    );

    final result = await updateProfile(params);

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (profile) => emit(ProfileUpdateSuccess(profile: profile)),
    );
  }

  void _onClearError(ClearProfileErrorEvent event, Emitter<ProfileState> emit) {
    emit(const ProfileInitial());
  }
}
