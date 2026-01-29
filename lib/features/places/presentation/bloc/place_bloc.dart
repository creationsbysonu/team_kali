import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/places/domain/entities/place.dart';
import 'package:sewa_web/features/places/domain/usecases/get_places_usecase.dart';

part 'place_event.dart';
part 'place_state.dart';

/// BLoC for managing place selection and listing
class PlaceBloc extends Bloc<PlaceEvent, PlaceState> {
  final GetPublicPlacesUseCase getPublicPlaces;
  final GetAllPlacesUseCase? getAllPlaces;
  final CreatePlaceUseCase? createPlace;
  final UpdatePlaceUseCase? updatePlace;
  final DeletePlaceUseCase? deletePlace;

  // Cache for places data
  List<Place>? _cachedPlaces;
  DateTime? _lastFetchTime;
  static const _cacheValidDuration = Duration(seconds: 30);

  PlaceBloc({
    required this.getPublicPlaces,
    this.getAllPlaces,
    this.createPlace,
    this.updatePlace,
    this.deletePlace,
  }) : super(PlaceInitial()) {
    // Use droppable transformer to prevent concurrent loads
    on<LoadPublicPlacesEvent>(_onLoadPublicPlaces, transformer: droppable());
    on<LoadAllPlacesEvent>(_onLoadAllPlaces, transformer: droppable());
    on<SelectPlaceEvent>(_onSelectPlace);
    on<CreatePlaceEvent>(_onCreatePlace);
    on<UpdatePlaceEvent>(_onUpdatePlace);
    on<DeletePlaceEvent>(_onDeletePlace);
    on<ClearSelectedPlaceEvent>(_onClearSelectedPlace);
    on<RefreshPlacesEvent>(_onRefreshPlaces);
  }

  bool get _isCacheValid =>
      _cachedPlaces != null &&
      _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration;

  Future<void> _onLoadPublicPlaces(
    LoadPublicPlacesEvent event,
    Emitter<PlaceState> emit,
  ) async {
    // Return cached data if valid
    if (_isCacheValid && !event.forceRefresh) {
      emit(PlacesLoaded(places: _cachedPlaces!));
      return;
    }

    emit(PlaceLoading());

    final result = await getPublicPlaces(const NoParams());

    result.fold((failure) => emit(PlaceError(message: failure.message)), (
      places,
    ) {
      _cachedPlaces = places;
      _lastFetchTime = DateTime.now();
      emit(PlacesLoaded(places: places));
    });
  }

  Future<void> _onLoadAllPlaces(
    LoadAllPlacesEvent event,
    Emitter<PlaceState> emit,
  ) async {
    if (getAllPlaces == null) {
      emit(const PlaceError(message: 'Not authorized to load all places'));
      return;
    }

    // Return cached data if valid and not forcing refresh
    if (_isCacheValid && !event.forceRefresh) {
      emit(PlacesLoaded(places: _cachedPlaces!));
      return;
    }

    emit(PlaceLoading());

    final result = await getAllPlaces!(const NoParams());

    result.fold((failure) => emit(PlaceError(message: failure.message)), (
      places,
    ) {
      _cachedPlaces = places;
      _lastFetchTime = DateTime.now();
      emit(PlacesLoaded(places: places));
    });
  }

  Future<void> _onRefreshPlaces(
    RefreshPlacesEvent event,
    Emitter<PlaceState> emit,
  ) async {
    // Force clear cache and reload
    _cachedPlaces = null;
    _lastFetchTime = null;
    add(const LoadAllPlacesEvent(forceRefresh: true));
  }

  void _onSelectPlace(SelectPlaceEvent event, Emitter<PlaceState> emit) {
    emit(PlaceSelected(place: event.place));
  }

  void _onClearSelectedPlace(
    ClearSelectedPlaceEvent event,
    Emitter<PlaceState> emit,
  ) {
    emit(PlaceInitial());
  }

  Future<void> _onCreatePlace(
    CreatePlaceEvent event,
    Emitter<PlaceState> emit,
  ) async {
    if (createPlace == null) {
      emit(const PlaceError(message: 'Not authorized to create places'));
      return;
    }

    emit(PlaceOperationLoading());

    final result = await createPlace!(
      CreatePlaceParams(name: event.name, slug: event.slug),
    );

    result.fold(
      (failure) => emit(PlaceOperationError(message: failure.message)),
      (place) => emit(
        PlaceOperationSuccess(
          message: 'Place "${place.name}" created successfully',
          place: place,
        ),
      ),
    );
  }

  Future<void> _onUpdatePlace(
    UpdatePlaceEvent event,
    Emitter<PlaceState> emit,
  ) async {
    if (updatePlace == null) {
      emit(const PlaceError(message: 'Not authorized to update places'));
      return;
    }

    emit(PlaceOperationLoading());

    final result = await updatePlace!(
      UpdatePlaceParams(
        id: event.id,
        name: event.name,
        slug: event.slug,
        isActive: event.isActive,
      ),
    );

    result.fold(
      (failure) => emit(PlaceOperationError(message: failure.message)),
      (place) => emit(
        PlaceOperationSuccess(
          message: 'Place "${place.name}" updated successfully',
          place: place,
        ),
      ),
    );
  }

  Future<void> _onDeletePlace(
    DeletePlaceEvent event,
    Emitter<PlaceState> emit,
  ) async {
    if (deletePlace == null) {
      emit(const PlaceError(message: 'Not authorized to delete places'));
      return;
    }

    emit(PlaceOperationLoading());

    final result = await deletePlace!(event.id);

    result.fold(
      (failure) => emit(PlaceOperationError(message: failure.message)),
      (_) => emit(
        const PlaceOperationSuccess(message: 'Place deleted successfully'),
      ),
    );
  }
}
