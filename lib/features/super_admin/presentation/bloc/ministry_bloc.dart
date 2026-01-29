import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';
import 'package:sewa_web/features/super_admin/domain/entities/place_filter_option.dart';
import 'package:sewa_web/features/super_admin/domain/usecases/get_admin_ministries_usecase.dart';
import 'package:sewa_web/features/super_admin/domain/usecases/get_deleted_ministries_usecase.dart';
import 'package:sewa_web/features/super_admin/domain/usecases/get_places_for_filter_usecase.dart';
import 'package:sewa_web/features/super_admin/domain/usecases/create_ministry_usecase.dart';
import 'package:sewa_web/features/super_admin/domain/usecases/update_ministry_usecase.dart';
import 'package:sewa_web/features/super_admin/domain/usecases/activate_ministry_usecase.dart';
import 'package:sewa_web/features/super_admin/domain/usecases/suspend_ministry_usecase.dart';
import 'package:sewa_web/features/super_admin/domain/usecases/delete_ministry_usecase.dart';
import 'package:sewa_web/features/super_admin/domain/usecases/restore_ministry_usecase.dart';
import 'package:sewa_web/features/super_admin/domain/usecases/hard_delete_ministry_usecase.dart';
import 'package:sewa_web/features/super_admin/domain/usecases/reset_ministry_password_usecase.dart';
import 'package:sewa_web/core/usecases/usecase.dart';

part 'ministry_event.dart';
part 'ministry_state.dart';

/// BLoC for managing ministries (Super Admin only)
class MinistryBloc extends Bloc<MinistryEvent, MinistryState> {
  final GetAdminMinistriesUseCase getAdminMinistries;
  final GetDeletedMinistriesUseCase getDeletedMinistries;
  final GetPlacesForFilterUseCase getPlacesForFilter;
  final CreateMinistryUseCase createMinistry;
  final UpdateMinistryUseCase updateMinistry;
  final ActivateMinistryUseCase activateMinistry;
  final SuspendMinistryUseCase suspendMinistry;
  final DeleteMinistryUseCase deleteMinistry;
  final RestoreMinistryUseCase restoreMinistry;
  final HardDeleteMinistryUseCase hardDeleteMinistry;
  final ResetMinistryPasswordUseCase resetMinistryPassword;

  MinistryBloc({
    required this.getAdminMinistries,
    required this.getDeletedMinistries,
    required this.getPlacesForFilter,
    required this.createMinistry,
    required this.updateMinistry,
    required this.activateMinistry,
    required this.suspendMinistry,
    required this.deleteMinistry,
    required this.restoreMinistry,
    required this.hardDeleteMinistry,
    required this.resetMinistryPassword,
  }) : super(MinistryInitial()) {
    on<LoadPlacesForFilterEvent>(_onLoadPlacesForFilter);
    on<LoadMinistriesEvent>(_onLoadMinistries);
    on<LoadDeletedMinistriesEvent>(_onLoadDeletedMinistries);
    on<CreateMinistryEvent>(_onCreateMinistry);
    on<UpdateMinistryEvent>(_onUpdateMinistry);
    on<ActivateMinistryEvent>(_onActivateMinistry);
    on<SuspendMinistryEvent>(_onSuspendMinistry);
    on<DeleteMinistryEvent>(_onDeleteMinistry);
    on<RestoreMinistryEvent>(_onRestoreMinistry);
    on<HardDeleteMinistryEvent>(_onHardDeleteMinistry);
    on<ResetMinistryPasswordEvent>(_onResetPassword);
    on<RefreshMinistriesEvent>(_onRefreshMinistries);
    on<RefreshAllMinistriesEvent>(_onRefreshAllMinistries);
  }

  // Flag to prevent concurrent refresh operations
  bool _isRefreshing = false;

  // Cache for preserving data during operations - always kept up to date
  List<Ministry> _cachedMinistries = [];
  List<Ministry> _cachedDeletedMinistries = [];
  List<PlaceFilterOption> _cachedPlaces = [];
  String? _selectedPlaceId;

  /// Public getter for cached deleted ministries
  List<Ministry> get cachedDeletedMinistries => _cachedDeletedMinistries;

  /// Public getter for cached places
  List<PlaceFilterOption> get cachedPlaces => _cachedPlaces;

  /// Public getter for selected place ID
  String? get selectedPlaceId => _selectedPlaceId;

  /// Helper to extract active ministries from current state
  List<Ministry> get _currentMinistries {
    final s = state;
    if (s is MinistryLoaded) return s.ministries;
    if (s is MinistryRefreshing) return s.ministries;
    return _cachedMinistries;
  }

  /// Helper to extract deleted ministries from current state
  List<Ministry> get _currentDeletedMinistries {
    final s = state;
    if (s is DeletedMinistriesLoaded) return s.ministries;
    if (s is DeletedMinistriesRefreshing) return s.ministries;
    return _cachedDeletedMinistries;
  }

  Future<void> _onLoadPlacesForFilter(
    LoadPlacesForFilterEvent event,
    Emitter<MinistryState> emit,
  ) async {
    final result = await getPlacesForFilter(const NoParams());

    result.fold((failure) => emit(MinistryError(message: failure.message)), (
      places,
    ) {
      _cachedPlaces = places;
      emit(PlacesForFilterLoaded(places: places));
    });
  }

  Future<void> _onLoadMinistries(
    LoadMinistriesEvent event,
    Emitter<MinistryState> emit,
  ) async {
    // Store selected place ID
    _selectedPlaceId = event.placeId;

    // Get current list from state or cache
    final currentList = _currentMinistries;

    // Emit refreshing state with current data if available
    if (currentList.isNotEmpty) {
      emit(MinistryRefreshing(ministries: currentList));
    } else {
      emit(MinistryLoading());
    }

    final result = await getAdminMinistries(
      AdminMinistriesParams(
        placeId: event.placeId,
        status: event.status,
        search: event.search,
      ),
    );

    result.fold((failure) => emit(MinistryError(message: failure.message)), (
      ministries,
    ) {
      _cachedMinistries = ministries; // Update cache
      emit(
        MinistryLoaded(ministries: ministries, selectedPlaceId: event.placeId),
      );
    });
  }

  Future<void> _onLoadDeletedMinistries(
    LoadDeletedMinistriesEvent event,
    Emitter<MinistryState> emit,
  ) async {
    // Get current list from state or cache
    final currentList = _currentDeletedMinistries;

    // Emit refreshing state with current data if available
    if (currentList.isNotEmpty) {
      emit(DeletedMinistriesRefreshing(ministries: currentList));
    } else {
      emit(MinistryLoading());
    }

    final result = await getDeletedMinistries(const NoParams());

    result.fold((failure) => emit(MinistryError(message: failure.message)), (
      ministries,
    ) {
      _cachedDeletedMinistries = ministries; // Update cache
      emit(DeletedMinistriesLoaded(ministries: ministries));
    });
  }

  Future<void> _onRefreshAllMinistries(
    RefreshAllMinistriesEvent event,
    Emitter<MinistryState> emit,
  ) async {
    // Prevent concurrent refresh operations
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      // Show refreshing state with cached data
      emit(MinistryRefreshing(ministries: _cachedMinistries));

      // Load active ministries first
      final activeResult = await getAdminMinistries(
        const AdminMinistriesParams(),
      );

      activeResult.fold(
        (failure) {
          emit(MinistryError(message: failure.message));
          return;
        },
        (ministries) {
          _cachedMinistries = ministries;
        },
      );

      // If active load failed, return early
      if (state is MinistryError) {
        _isRefreshing = false;
        return;
      }

      // Load deleted ministries
      final deletedResult = await getDeletedMinistries(const NoParams());

      deletedResult.fold(
        (failure) {
          // Still emit loaded state for active ministries even if deleted fails
          emit(MinistryLoaded(ministries: _cachedMinistries));
        },
        (deletedMinistries) {
          _cachedDeletedMinistries = deletedMinistries;
          // Emit final loaded state
          emit(MinistryLoaded(ministries: _cachedMinistries));
        },
      );
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _onRefreshMinistries(
    RefreshMinistriesEvent event,
    Emitter<MinistryState> emit,
  ) async {
    // Keep current data while refreshing
    final currentState = state;
    List<Ministry> currentMinistries = [];
    if (currentState is MinistryLoaded) {
      currentMinistries = currentState.ministries;
    }

    emit(MinistryRefreshing(ministries: currentMinistries));

    final result = await getAdminMinistries(const AdminMinistriesParams());

    result.fold(
      (failure) => emit(MinistryError(message: failure.message)),
      (ministries) => emit(MinistryLoaded(ministries: ministries)),
    );
  }

  Future<void> _onCreateMinistry(
    CreateMinistryEvent event,
    Emitter<MinistryState> emit,
  ) async {
    emit(
      MinistryCreating(
        ministries: _cachedMinistries,
        deletedMinistries: _cachedDeletedMinistries,
      ),
    );

    final result = await createMinistry(
      CreateMinistryParams(
        placeId: event.placeId,
        name: event.name,
        email: event.email,
        password: event.password,
        description: event.description,
        phone: event.phone,
        address: event.address,
        website: event.website,
        logoBytes: event.logoBytes,
        logoFileName: event.logoFileName,
      ),
    );

    result.fold(
      (failure) => emit(MinistryOperationError(message: failure.message)),
      (ministry) {
        emit(MinistryCreated(ministry: ministry));
        // Auto-refresh list after creation
        add(const LoadMinistriesEvent());
      },
    );
  }

  Future<void> _onUpdateMinistry(
    UpdateMinistryEvent event,
    Emitter<MinistryState> emit,
  ) async {
    emit(
      MinistryUpdating(
        ministries: _cachedMinistries,
        deletedMinistries: _cachedDeletedMinistries,
      ),
    );

    final result = await updateMinistry(
      UpdateMinistryParams(
        id: event.ministryId,
        name: event.name,
        description: event.description,
        phone: event.phone,
        address: event.address,
        website: event.website,
        logoBytes: event.logoBytes,
        logoFileName: event.logoFileName,
      ),
    );

    result.fold(
      (failure) => emit(MinistryOperationError(message: failure.message)),
      (ministry) {
        emit(MinistryUpdated(ministry: ministry));
        add(const LoadMinistriesEvent());
      },
    );
  }

  Future<void> _onActivateMinistry(
    ActivateMinistryEvent event,
    Emitter<MinistryState> emit,
  ) async {
    emit(
      MinistryUpdating(
        ministries: _cachedMinistries,
        deletedMinistries: _cachedDeletedMinistries,
      ),
    );

    final result = await activateMinistry(
      ActivateMinistryParams(id: event.ministryId),
    );

    result.fold(
      (failure) => emit(MinistryOperationError(message: failure.message)),
      (ministry) {
        emit(MinistryActivated(ministry: ministry));
        add(const LoadMinistriesEvent());
      },
    );
  }

  Future<void> _onSuspendMinistry(
    SuspendMinistryEvent event,
    Emitter<MinistryState> emit,
  ) async {
    emit(
      MinistryUpdating(
        ministries: _cachedMinistries,
        deletedMinistries: _cachedDeletedMinistries,
      ),
    );

    final result = await suspendMinistry(
      SuspendMinistryParams(id: event.ministryId, reason: event.reason),
    );

    result.fold(
      (failure) => emit(MinistryOperationError(message: failure.message)),
      (ministry) {
        emit(MinistrySuspended(ministry: ministry));
        add(const LoadMinistriesEvent());
      },
    );
  }

  Future<void> _onDeleteMinistry(
    DeleteMinistryEvent event,
    Emitter<MinistryState> emit,
  ) async {
    emit(
      MinistryUpdating(
        ministries: _cachedMinistries,
        deletedMinistries: _cachedDeletedMinistries,
      ),
    );

    final result = await deleteMinistry(
      DeleteMinistryParams(id: event.ministryId),
    );

    result.fold(
      (failure) => emit(MinistryOperationError(message: failure.message)),
      (_) {
        emit(MinistryDeleted(ministryId: event.ministryId));
        add(const LoadMinistriesEvent());
      },
    );
  }

  Future<void> _onRestoreMinistry(
    RestoreMinistryEvent event,
    Emitter<MinistryState> emit,
  ) async {
    emit(
      MinistryUpdating(
        ministries: _cachedMinistries,
        deletedMinistries: _cachedDeletedMinistries,
      ),
    );

    final result = await restoreMinistry(
      RestoreMinistryParams(id: event.ministryId),
    );

    result.fold(
      (failure) => emit(MinistryOperationError(message: failure.message)),
      (ministry) {
        emit(MinistryRestored(ministry: ministry));
        add(LoadDeletedMinistriesEvent());
      },
    );
  }

  Future<void> _onHardDeleteMinistry(
    HardDeleteMinistryEvent event,
    Emitter<MinistryState> emit,
  ) async {
    emit(
      MinistryUpdating(
        ministries: _cachedMinistries,
        deletedMinistries: _cachedDeletedMinistries,
      ),
    );

    final result = await hardDeleteMinistry(
      HardDeleteMinistryParams(id: event.ministryId),
    );

    result.fold(
      (failure) => emit(MinistryOperationError(message: failure.message)),
      (_) {
        emit(MinistryHardDeleted(ministryId: event.ministryId));
        add(LoadDeletedMinistriesEvent());
      },
    );
  }

  Future<void> _onResetPassword(
    ResetMinistryPasswordEvent event,
    Emitter<MinistryState> emit,
  ) async {
    emit(
      MinistryUpdating(
        ministries: _cachedMinistries,
        deletedMinistries: _cachedDeletedMinistries,
      ),
    );

    final result = await resetMinistryPassword(
      ResetMinistryPasswordParams(
        id: event.ministryId,
        newPassword: event.newPassword,
      ),
    );

    result.fold(
      (failure) => emit(MinistryOperationError(message: failure.message)),
      (_) {
        emit(MinistryPasswordReset(ministryId: event.ministryId));
        add(const LoadMinistriesEvent());
      },
    );
  }
}
