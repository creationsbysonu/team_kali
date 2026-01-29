import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/features/officials/domain/entities/official.dart';
import 'package:sewa_web/features/officials/domain/usecases/officials_usecases.dart';

part 'officials_event.dart';
part 'officials_state.dart';

/// Officials BLoC - manages officials list and CRUD operations
class OfficialsBloc extends Bloc<OfficialsEvent, OfficialsState> {
  final GetOfficialsUseCase getOfficials;
  final GetOfficialByIdUseCase getOfficialById;
  final CreateOfficialUseCase createOfficial;
  final UpdateOfficialUseCase updateOfficial;
  final DeleteOfficialUseCase deleteOfficial;

  OfficialsBloc({
    required this.getOfficials,
    required this.getOfficialById,
    required this.createOfficial,
    required this.updateOfficial,
    required this.deleteOfficial,
  }) : super(OfficialsInitial()) {
    on<LoadOfficialsEvent>(_onLoadOfficials);
    on<LoadOfficialByIdEvent>(_onLoadOfficialById);
    on<CreateOfficialEvent>(_onCreateOfficial);
    on<UpdateOfficialEvent>(_onUpdateOfficial);
    on<DeleteOfficialEvent>(_onDeleteOfficial);
  }

  Future<void> _onLoadOfficials(
    LoadOfficialsEvent event,
    Emitter<OfficialsState> emit,
  ) async {
    emit(OfficialsLoading());

    final result = await getOfficials(event.ministryId);

    result.fold(
      (failure) => emit(OfficialsError(message: failure.message)),
      (officials) => emit(OfficialsLoaded(officials: officials)),
    );
  }

  Future<void> _onLoadOfficialById(
    LoadOfficialByIdEvent event,
    Emitter<OfficialsState> emit,
  ) async {
    emit(OfficialDetailLoading());

    final result = await getOfficialById(event.officialId);

    result.fold(
      (failure) => emit(OfficialsError(message: failure.message)),
      (official) => emit(OfficialDetailLoaded(official: official)),
    );
  }

  Future<void> _onCreateOfficial(
    CreateOfficialEvent event,
    Emitter<OfficialsState> emit,
  ) async {
    emit(OfficialCreating());

    final params = CreateOfficialParams(
      ministryId: event.ministryId,
      name: event.name,
      role: event.role,
    );

    final result = await createOfficial(params);

    result.fold((failure) => emit(OfficialsError(message: failure.message)), (
      official,
    ) {
      emit(OfficialCreated(official: official));
      // Reload the list
      add(LoadOfficialsEvent(ministryId: event.ministryId));
    });
  }

  Future<void> _onUpdateOfficial(
    UpdateOfficialEvent event,
    Emitter<OfficialsState> emit,
  ) async {
    emit(OfficialUpdating());

    final params = UpdateOfficialParams(
      officialId: event.officialId,
      name: event.name,
      role: event.role,
      isActive: event.isActive,
    );

    final result = await updateOfficial(params);

    result.fold((failure) => emit(OfficialsError(message: failure.message)), (
      official,
    ) {
      emit(OfficialUpdated(official: official));
      // Reload the list
      add(LoadOfficialsEvent(ministryId: event.ministryId));
    });
  }

  Future<void> _onDeleteOfficial(
    DeleteOfficialEvent event,
    Emitter<OfficialsState> emit,
  ) async {
    emit(OfficialDeleting());

    final result = await deleteOfficial(event.officialId);

    result.fold((failure) => emit(OfficialsError(message: failure.message)), (
      _,
    ) {
      emit(const OfficialDeleted());
      // Reload the list
      add(LoadOfficialsEvent(ministryId: event.ministryId));
    });
  }
}
